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

#include <h/kernel.h>
#include <h/graphics.h>


static status
initialisePicture(PictureObj p, Name name, Size size, DisplayObj display)
{ initialiseWindow((PceWindow) p, name, size, display);

  return send(p, NAME_scrollbars, NAME_both, EAV);
}


		 /*******************************
		 *	 CLASS DECLARATION	*
		 *******************************/

/* Type declarations */

static char *T_initialise[] =
        { "label=[name]", "size=[size]", "display=[display]" };

/* Instance Variables */

#define var_picture NULL
/*
vardecl var_picture[] =
{
};
*/

/* Send Methods */

static senddecl send_picture[] =
{ SM(NAME_initialise, 3, T_initialise, initialisePicture,
     DEFAULT, "Create from label, size and display")
};

/* Get Methods */

#define get_picture NULL
/*
static getdecl get_picture[] =
{
};
*/

/* Resources */

static classvardecl rc_picture[] =
{ RC(NAME_size, "size", "size(400,200)",
     "Default size in pixels")
};

/* Class Declaration */

static Name picture_termnames[] = { NAME_name };

ClassDecl(picture_decls,
          var_picture, send_picture, get_picture, rc_picture,
          1, picture_termnames,
          "$Rev$");


status
makeClassPicture(Class class)
{ return declareClass(class, &picture_decls);
}

