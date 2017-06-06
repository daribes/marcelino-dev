/*  $Id$

    Part of XPCE --- The SWI-Prolog GUI toolkit

    Author:        Jan Wielemaker and Anjo Anjewierden
    E-mail:        jan@swi.psy.uva.nl
    WWW:           http://www.swi.psy.uva.nl/projects/xpce/
    Copyright (C): 1985-2002, University of Amsterdam

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

    As a special exception, if you link this library with other files,
    compiled with a Free Software compiler, to produce an executable, this
    library does not by itself cause the resulting executable to be covered
    by the GNU General Public License. This exception does not however
    invalidate any other reasons why the executable file might be covered by
    the GNU General Public License.
*/

:- module(twm_geometry_box, []).
:- use_module(library(pce)).

:- pce_begin_class(twm_geometry_box, device).

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Class gemeotry_box defines box to give feedback for move/resize gestures
similar  to  the  TWM  window   manager.     This   class  is  by  class
twm_resize_button to implement TWM-like resizing  of subwindows or other
graphical objects.

The normal interface is formed by the methods:

	->attach: graphical		Represent the area of graphical
	->detach: graphical		Resize/move graphical and remove
	->cancel			Just remove

THIS PACKAGE GRABS THE X-SERVER AND SHOULD THEREFORE BY USED WITH CARE!
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

variable(display,	display*,	get,	"Display I'm on").

initialise(GB, W:[int], H:[int]) :->
	"Create box with all the 4 lines"::
	send(GB, send_super, initialise),
	send(GB, display, box(W, H)),
	send(GB, display, new(H1, line)),
	send(GB, display, new(H2, line)),
	send(GB, display, new(V1, line)),
	send(GB, display, new(V2, line)),
	send(H1, name, h1),
	send(H2, name, h2),
	send(V1, name, v1),
	send(V2, name, v2).


geometry(GB, X:[int], Y:[int], W:[int], H:[int]) :->
	"Change the geometry.  If displayed, properly redisplay"::
	get(GB, display, Display),
	(   Display \== @nil
	->  send(Display, draw_in, GB, @default, @on, @on)
	;   true
	),
	get(GB, member, box, B),
	get(GB, member, h1, H1),
	get(GB, member, h2, H2),
	get(GB, member, v1, V1),
	get(GB, member, v2, V2),
	send(B, set, 0, 0, W, H),
	get(B, width, BW),
	get(B, height, BH),
	send(H1, points, 0,      BH/3,   BW,     BH/3),
	send(H2, points, 0,      2*BH/3, BW,     2*BH/3),
	send(V1, points, BW/3,   0,      BW/3,   BH),
	send(V2, points, 2*BW/3, 0,	 2*BW/3, BH),
	send(GB, send_super, geometry, X, Y),
	(   Display \== @nil
	->  send(Display, draw_in, GB, @default, @on, @on)
	;   true
	).


device(GB, D:display*, Pos:[point]) :->
	"Attach/detach the box to the display"::
	(   get(GB, display, Display), Display \== @nil
	->  send(Display, draw_in, GB, @default, @on, @on)
	;   true
	),
	send(GB, slot, display, @nil),
	(   Pos \== @default
	->  send(GB, set, Pos?x, Pos?y)
	;   true
	),
	send(GB, slot, display, D),
	(   D \== @nil
	->  %  send(D, grab_server, @on),
	    send(D, draw_in, GB, Pos, @on, @on)
	;   %  send(D, grab_server, @off),
	    true
	).


attach(GB, Gr:graphical) :->
	"Attach to the indicated graphical"::
	get(Gr, display_position, point(X, Y)),
	get(Gr, size, size(W, H)),
	send(GB, set, X, Y, W, H),
	send(GB, device, Gr?display).


detach(GB, Gr:graphical) :->
	"Remove and update the graphical"::
	send(GB, device, @nil),
	get(Gr, display_position, point(X, Y)),
	get(Gr?area, position, point(GX, GY)),
	send(Gr, do_set, GX + GB?x - X, GY + GB?y - Y, GB?width, GB?height).


cancel(GB) :->
	"Remove without updating the graphical"::
	send(GB, device, @nil).

:- pce_end_class.
