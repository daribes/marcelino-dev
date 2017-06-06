/*  $Id$

    Part of SWI-Prolog

    Author:        Jan Wielemaker
    E-mail:        jan@swi.psy.uva.nl
    WWW:           http://www.swi-prolog.org
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

:- module(thr_local_1,
	  [ thr_local_1/0
	  ]).

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
This test validates the operation of thread-local dynamic predicates. It
creates 5 threads asserting the 1000 facts 1...1000 and checks they can
be retracted in the proper order.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

:- thread_local
	foo/1.

thr_local_1 :-
	thr_local_1(5, 1000).

thr_local_1(Threads, Asserts) :-
	thread_create(join(Threads), Id, []),
	forall(between(1, Threads, _),
	       thread_create(test_foo(Asserts), _,
			     [ at_exit(done(Id))
			     ])),
	join_ok(Id).

join(Times) :-
	forall(between(1, Times, _),
	       (   thread_get_message(done(Done)),
		   join_ok(Done)
	       )).

join_ok(Id) :-
	thread_join(Id, Return),
	(   Return == true
	->  true
	;   format('~N~p returned ~p~n', [Id, Return]),
	    fail
	).


test_foo(N) :-
	forall(between(0, N, X),
	       assert(foo(X))),
	predicate_property(foo(_), number_of_clauses(Count)),
	(   Count =:= N+1
	->  true
	;   format(user_error, '~D clauses!?~n', [Count])
	),
	findall(X, retract(foo(X)), List),
	(   check(0, N, List)
	->  true
	;   numlist(0, N, OkList),
	    ord_subtract(OkList, List, Missing),
	    compact(Missing, Ranges),
	    thread_self(TID),
	    format(user_error, '~N[~w] MISSING: ~q~n', [TID, Ranges]),
	    fail
	).

check(I, N, []) :-
	I > N, !.
check(I, N, [I|T]) :-
	NI is I + 1,
	check(NI, N, T).

compact([], []).
compact([H|T0], [Range|T]) :-
	subsequent(T0, H, E, T1),
	(   H == E
	->  Range = H
	;   Range = (H-E)
	),
	compact(T1, T).

subsequent([H|T], X, E, R) :-
	H =:= X+1, !,
	subsequent(T, H, E, R).
subsequent(L, X, X, L).


done(Report) :-
	thread_self(Me),
	thread_send_message(Report, done(Me)).
