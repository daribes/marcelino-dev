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

#ifndef UTF8_H_INCLUDED
#define UTF8_H_INCLUDED

#define ISUTF8_MB(c) ((unsigned)(c) >= 0xc0 && (unsigned)(c) <= 0xfd)

#define utf8_get_char(in, chr) \
	(*(in) & 0x80 ? sgml__utf8_get_char(in, chr) \
		      : (*(chr) = *(in), (char *)(in)+1))

extern char *sgml__utf8_get_char(const char *in, int *chr);
#define utf8_get_uchar(in, chr) (unsigned char*)utf8_get_char((char*)(in), chr)

extern char *sgml_utf8_put_char(char *out, int chr);
#define utf8_put_char(out, chr) \
	((chr) < 0x80 ? out[0]=(char)(chr), out+1 \
		      : sgml_utf8_put_char(out, (chr)))

extern size_t sgml_utf8_strlen(const char *s, size_t len);
#define utf8_strlen sgml_utf8_strlen

#endif /*UTF8_H_INCLUDED*/
