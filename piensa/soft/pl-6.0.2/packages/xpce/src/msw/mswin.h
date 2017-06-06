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

#ifndef MSWIN_H_INCLUDED
#define MSWIN_H_INCLUDED

typedef enum
{ WINUNKNOWN,
  WIN32S,
  WIN95,
  WIN98,
  WINME,
  NT
} os_platform;

os_platform	ws_platform(void);	/* yield windows platform */
char *		ws_os(void);		/* platform by name */
Name		ws_appdata(const char* sub);	/* User application dir */

#endif /*MSWIN_H_INCLUDED*/
