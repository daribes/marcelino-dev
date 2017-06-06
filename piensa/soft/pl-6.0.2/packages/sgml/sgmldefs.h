/*  $Id$

    Part of SWI-Prolog

    Author:        Jan Wielemaker
    E-mail:        jan@swi.psy.uva.nl
    WWW:           http://www.swi-prolog.org
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

#ifndef SGMLDEFS_H_INCLUDED
#define SGMLDEFS_H_INCLUDED

#ifdef HAVE_CONFIG_H
#include <config.h>
#else
#ifdef __WINDOWS__
#define HAVE_MALLOC_H 1
#define HAVE_IO_H 1
#endif
#endif

#ifdef HAVE_DMALLOC_H
#include <dmalloc.h>
#endif

#define UTF8 1				/* Include UTF-8 decoding */
#define XMLNS 1				/* support XML namespaces */

#include <wchar.h>

		 /*******************************
		 *    INPUT/OUTPUT CHARACTERS	*
		 *******************************/

typedef wchar_t ichar;			/* input character */

#define SHORTMAP_SIZE	256		/* shortmaps in 0..255 */

#define USE_STRING_FUNCTIONS 1		/* use built-in str* functions */


		 /*******************************
		 *	       LIMITS		*
		 *******************************/

#define INPUT_CHARSET_SIZE	256	/* for now */
#define SYMBOLHASHSIZE		256
#define MAXSTRINGLEN	       2048
#define MAXNMLEN		256
#define MAXDECL		      10240
#define MAXATTELEM		256	/* #elements in one ATTLIST */
#define MAXNAMEGROUP		256	/* #names in a (group) */
#define MAXATTRIBUTES		256	/* attributes per element */
#define MAXMAPLEN		 32	/* max sequence length for SHORTREF */
#define SHORTENTITYFILE		100	/* short external entities in mem */


		 /*******************************
		 *	    CONSTANTS		*
		 *******************************/

#ifndef TRUE
#define TRUE 1
#define FALSE 0
#endif

#define LF 10
#define CR 13

#endif /*SGMLDEFS_H_INCLUDED*/
