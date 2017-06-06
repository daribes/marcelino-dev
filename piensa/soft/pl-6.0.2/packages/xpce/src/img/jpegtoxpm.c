/*  $Id$

    Part of XPCE --- The SWI-Prolog GUI toolkit

    Author:        Jan Wielemaker and Anjo Anjewierden
    E-mail:        jan@swi.psy.uva.nl
    WWW:           http://www.swi.psy.uva.nl/projects/xpce/
    Copyright (C): 1985-2002, University of Amsterdam

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
*/

#ifdef __WINDOWS__
#include <msw/include.h>
#ifdef HAVE_LIBXPM
#define  FOR_MSW 1
#include <msw/xpm.h>
#endif
#ifdef __RPCNDR_H__
#define HAVE_BOOLEAN		/* prevent jmorecfg.h from redefining it */
#endif
#else /*__WINDOWS__*/
#include <h/kernel.h>
#ifdef HAVE_LIBXPM
#include <X11/xpm.h>
#endif
#endif /*__WINDOWS__*/

#undef GLOBAL				/* conflict */

#ifdef HAVE_LIBJPEG

#if defined(__CYGWIN__) || defined(__MINGW32__)	/* avoid redefinition of INT32 */
#define XMD_H
#endif
#include <jpeglib.h>
#include <jerror.h>
#ifdef HAVE_STRING_H
#include <string.h>
#endif
#include <setjmp.h>

#include "jpeg.h"

/* left to free(), so use malloc() rather then pceMalloc() */
#define XpmMalloc(n) (void *)malloc(n)
typedef unsigned int XpmPixel;

#ifndef SEEK_SET
#define SEEK_SET 0
#endif

extern void	jpeg_iostream_src(j_decompress_ptr cinfo, IOSTREAM* infile);

static int
convert_colourmap(int ncolors, int ncomponents,
		  JSAMPARRAY colourmap,
		  XpmImage *img)
{ int i;

  img->ncolors = ncolors;
  if ( !(img->colorTable = XpmMalloc(sizeof(XpmColor) * ncolors)) )
    return XpmNoMemory;

  memset(img->colorTable, 0, sizeof(XpmColor) * ncolors);

  for(i=0; i<ncolors; i++)
  { XpmColor *c = &img->colorTable[i];

    if ( (c->c_color = XpmMalloc(8)) )
    { int r, g, b;

      switch(ncomponents)
      { case 3:
	  r = colourmap[0][i];
	  g = colourmap[1][i];
	  b = colourmap[2][i];
	  break;
	case 1:
	  r = colourmap[0][i];
	  g = b = r;
	  break;
	default:
	  r = g = b = 0;		/* keep compiler happy */
	  sysPce("JPEG: Unknown number of colour components: %d\n",
		 ncomponents);
      }

      sprintf(c->c_color, "#%02x%02x%02x", r, g, b);
    } else
      return XpmNoMemory;
  }

  return XpmSuccess;
}


struct my_jpeg_error_mgr
{ struct jpeg_error_mgr	jerr;
  jmp_buf 		jmp_context;
};


static void
my_exit(j_common_ptr cl)
{ struct jpeg_decompress_struct *cinfo = (struct jpeg_decompress_struct *)cl;
  struct my_jpeg_error_mgr *jerr = (struct my_jpeg_error_mgr *)cinfo->err;

  longjmp(jerr->jmp_context, 1);
}


int
readJPEGtoXpmImage(IOSTREAM *fd, XpmImage *img, Image image)
{ struct jpeg_decompress_struct cinfo;
  struct my_jpeg_error_mgr jerr;
  long row_stride;
  JSAMPLE **buffer;
  int rval;
  long here = Stell(fd);

  if ( !img )
    return XpmNoMemory;
  img->ncolors    = 0;
  img->colorTable = NULL;
  img->data       = NULL;

  cinfo.err = jpeg_std_error((struct jpeg_error_mgr *)&jerr);
  if ( setjmp(jerr.jmp_context) )
  { DEBUG(NAME_image,
	  { char buf[1024];

	    (*jerr.jerr.format_message)((j_common_ptr)&cinfo, buf);
	    Cprintf("JPEG: %s\n", buf);
	  });

    switch(jerr.jerr.msg_code)
    { case JERR_OUT_OF_MEMORY:
	rval = XpmNoMemory;
	break;
      case JERR_NO_SOI:
	rval = XpmFileInvalid;
	break;
      default:
      rval = XpmFileInvalid;
    }

    jpeg_destroy_decompress(&cinfo);

    Sseek(fd, here, SEEK_SET);
    return rval;
  }
  jerr.jerr.error_exit = my_exit;

  jpeg_create_decompress(&cinfo);
  jpeg_iostream_src(&cinfo, fd);

  jpeg_save_markers(&cinfo, JPEG_COM, 0xffff);
  jpeg_read_header(&cinfo, TRUE);
  cinfo.quantize_colors = TRUE;
  jpeg_start_decompress(&cinfo);

  if ( (rval=convert_colourmap(cinfo.actual_number_of_colors,
			       cinfo.out_color_components,
			       cinfo.colormap,
			       img) != XpmSuccess) )
    return rval;

  row_stride = cinfo.output_width * cinfo.output_components;
  buffer = (*cinfo.mem->alloc_sarray)((j_common_ptr)&cinfo,
				      JPOOL_IMAGE, row_stride, 1);
  img->width  = cinfo.output_width;
  img->height = cinfo.output_height;
  img->data   = XpmMalloc(sizeof(XpmPixel) *
			  cinfo.output_width *
			  cinfo.output_height);
  if ( !img->data )
    return XpmNoMemory;

  while ( cinfo.output_scanline < cinfo.output_height )
  { XpmPixel *o;
    JSAMPLE *i;
    int x;

    jpeg_read_scanlines(&cinfo, buffer, 1);

    o = &img->data[cinfo.output_width*(cinfo.output_scanline - 1)];
    i = buffer[0];
    x = cinfo.output_width;

    while(--x >= 0)
      *o++ = *i++;
  }

  if ( cinfo.marker_list )
  { jpeg_saved_marker_ptr m;
    Chain ch;

    attributeObject(image, NAME_comment, (ch=newObject(ClassChain, EAV)));

    for(m = cinfo.marker_list; m; m = m->next )
    { if ( m->marker == JPEG_COM )
      { string s;

	str_set_n_ascii(&s, m->data_length, (char*)m->data);
	appendChain(ch, StringToString(&s));
      }
    }
  }

  jpeg_finish_decompress(&cinfo);
  jpeg_destroy_decompress(&cinfo);

  return XpmSuccess;
}

#endif /*HAVE_LIBJPEG*/
