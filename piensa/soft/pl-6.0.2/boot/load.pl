/*  $Id$

    Part of SWI-Prolog

    Author:        Jan Wielemaker
    E-mail:        J.Wielemaker@vu.nl
    WWW:           http://www.swi-prolog.org
    Copyright (C): 1985-2011, University of Amsterdam
			      Vu University Amsterdam

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

    As a special exception, if you link this library with other files,
    compiled with a Free Software compiler, to produce an executable, this
    library does not by itself cause the resulting executable to be covered
    by the GNU General Public License. This exception does not however
    invalidate any other reasons why the executable file might be covered by
    the GNU General Public License.
*/


% Load the rest of the system as modules, so we can write a bit more
% readable code.  First we need to load term-expansion, etc. because
% this gives us DCGs.  Then we need to replace the dummy clauses for
% '$expand_term'/2 and '$expand_goal'/2 with links to the real thing.

:- consult([ expand,
	     dcg
	   ]).

:- abolish('$expand_goal'/2),
   asserta(('$expand_goal'(In, Out) :- expand_goal(In, Out))),
   abolish('$expand_term'/2),
   asserta(('$expand_term'(In, Out) :- expand_term(In, Out))).

:- consult([ license,			% requires DCG
	     syspred,
	     messages,
	     toplevel,
	     attvar,
	     bags,
	     apply,
	     history,
	     dwim,
	     parms,
	     autoload,
	     qlf,
	     rc,
	     predopts,
	     user:topvars
	   ]).
