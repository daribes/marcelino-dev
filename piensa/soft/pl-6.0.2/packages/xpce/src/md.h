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

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
autoconf/config.h based machine-binding file.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#ifndef _MD_INCLUDED
#define _MD_INCLUDED

#ifdef HAVE_CONFIG_H
# include <config.h>
#else
# ifdef __WINDOWS__
#  ifdef WIN64
#   include "md/md-win64.h"
#  else
#   include "md/md-win32.h"
#  endif
# else
#  error("No config")
# endif
#endif

		 /*******************************
		 *             UXNT             *
		 *******************************/

#ifdef HAVE_UXNT_H
#include <uxnt.h>	/* must be first! */
#endif

		 /*******************************
		 *	    DEFINE UNIX?	*
		 *******************************/

#if !defined(__unix__) && defined(_AIX)
#define __unix__ 1
#endif

		 /*******************************
		 *	      ALLOCA		*
		 *******************************/

/* AIX requires this to be the first thing in the file.  */
#ifdef __GNUC__
#define alloca __builtin_alloca
#else /* not __GNUC__ */
#if HAVE_ALLOCA_H
#include <alloca.h>
#else /* not HAVE_ALLOCA_H */
#ifdef _AIX
#pragma alloca
#else /* not _AIX */
char *alloca ();
#endif /* not _AIX */
#endif /* not HAVE_ALLOCA_H */
#endif /* not __GNUC__ */


		 /*******************************
		 *          STDC_HEADERS	*
		 *******************************/

#if STDC_HEADERS || HAVE_STRING_H
#include <string.h>
/* An ANSI string.h and pre-ANSI memory.h might conflict.  */
#if !STDC_HEADERS && HAVE_MEMORY_H
#include <memory.h>
#endif /* not STDC_HEADERS and HAVE_MEMORY_H */
#else /* not STDC_HEADERS and not HAVE_STRING_H */
#include <strings.h>
/* memory.h and strings.h conflict on some systems.  */
#endif /* not STDC_HEADERS and not HAVE_STRING_H */

#ifndef HAVE_MEMMOVE
#define memmove(to, from, size)	bcopy(from, to, size)
#endif

		 /*******************************
		 *	SOME SYSTEM STUFF	*
		 *******************************/

#endif /*_MD_INCLUDED*/
