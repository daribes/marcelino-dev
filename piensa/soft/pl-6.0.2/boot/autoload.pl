/*  $Id$

    Part of SWI-Prolog

    Author:        Jan Wielemaker
    E-mail:        J.Wielemaker@uva.nl
    WWW:           http://www.swi-prolog.org
    Copyright (C): 1985-2011, University of Amsterdam
			      VU University Amsterdam

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

:- module('$autoload',
	  [ '$find_library'/5,
	    '$in_library'/3,
	    '$define_predicate'/1,
	    '$update_library_index'/0,
	    make_library_index/1,
	    make_library_index/2,
	    reload_library_index/0,
	    autoload_path/1
	  ]).

:- dynamic
	library_index/3,		% Head x Module x Path
	autoload_directories/1,		% List
	index_checked_at/1.		% Time
:- volatile
	library_index/3,
	autoload_directories/1,
	index_checked_at/1.

user:file_search_path(autoload, library(.)).


%%	'$find_library'(+Module, +Name, +Arity, -LoadModule, -Library) is semidet.
%
%	Locate a predicate in the library.  Name and arity are the name
%	and arity of the predicate searched for.  `Module' is the
%	preferred target module.  The return values are the full path names
%	of the library and module declared in that file.

'$find_library'(Module, Name, Arity, LoadModule, Library) :-
	load_library_index(Name, Arity),
	functor(Head, Name, Arity),
	(   library_index(Head, Module, Library),
	    LoadModule = Module
	;   library_index(Head, LoadModule, Library)
	), !.

%%	'$in_library'(+Name, +Arity, -Path) is semidet.
%%	'$in_library'(-Name, -Arity, -Path) is nondet.
%
%	Is true if Name/Arity is in the autoload libraries.

'$in_library'(Name, Arity, Path) :-
	atom(Name), integer(Arity), !,
	load_library_index(Name, Arity),
	functor(Head, Name, Arity),
	library_index(Head, _, Path).
'$in_library'(Name, Arity, Path) :-
	load_library_index(Name, Arity),
	library_index(Head, _, Path),
	functor(Head, Name, Arity).

%%	'$define_predicate'(:Head)
%
%	Make sure PredInd can be called. First  test if the predicate is
%	defined. If not, invoke the autoloader.

:- meta_predicate
	'$define_predicate'(:).

'$define_predicate'(Head) :-
	'$defined_predicate'(Head), !.
'$define_predicate'(Term) :-
	Term = Module:Head,
	functor(Head, Name, Arity),
	'$undefined_procedure'(Module, Name, Arity, retry).


		/********************************
		*          UPDATE INDEX		*
		********************************/

'$update_library_index' :-
	setof(Dir, indexed_directory(Dir), Dirs), !,
	guarded_make_library_index(Dirs),
	(   flag('$modified_index', true, false)
	->  reload_library_index
	;   true
	).
'$update_library_index'.

guarded_make_library_index([]).
guarded_make_library_index([Dir|Dirs]) :-
	(   catch(make_library_index(Dir), E,
		  print_message(error, E))
	->  true
	;   print_message(warning, goal_failed(make_library_index(Dir)))
	),
	guarded_make_library_index(Dirs).


indexed_directory(Dir) :-
	index_file_name(IndexFile, [access(read), access(write)]),
	file_directory_name(IndexFile, Dir).
indexed_directory(Dir) :-
	absolute_file_name(library('MKINDEX'),
			   [ file_type(prolog),
			     access(read),
			     solutions(all),
			     file_errors(fail)
			   ], MkIndexFile),
	file_directory_name(MkIndexFile, Dir),
	plfile_in_dir(Dir, 'INDEX', _, IndexFile),
	access_file(IndexFile, write).


		/********************************
		*           LOAD INDEX		*
		********************************/

%%	reload_library_index
%
%	Reload the index on the next call

reload_library_index :-
	with_mutex('$autoload', clear_library_index).

clear_library_index :-
	retractall(library_index(_, _, _)),
	retractall(autoload_directories(_)),
	retractall(index_checked_at(_)).


%%	load_library_index(?Name, ?Arity) is det.
%
%	Try to find Name/Arity  in  the   library.  If  the predicate is
%	there, we are happy. If not, we  check whether the set of loaded
%	libraries has changed and if so we reload the index.

load_library_index(Name, Arity) :-
	atom(Name), integer(Arity),
	functor(Head, Name, Arity),
	library_index(Head, _, _), !.
load_library_index(_, _) :-
	notrace(with_mutex('$autoload', load_library_index_p)).

load_library_index_p :-
	index_checked_at(Time),
	get_time(Now),
	Now-Time < 60, !.
load_library_index_p :-
	findall(Index, index_file_name(Index, [access(read)]), List0),
	list_set(List0, List),
	retractall(index_checked_at(_)),
	get_time(Now),
	assert(index_checked_at(Now)),
	(   autoload_directories(List)
	->  true
	;   retractall(library_index(_, _, _)),
	    retractall(autoload_directories(_)),
	    read_index(List),
	    assert(autoload_directories(List))
	).

list_set([], R) :-			% == list_to_set/2 from library(lists)
	closel(R).
list_set([H|T], R) :-
	memberchk(H, R), !,
	list_set(T, R).

closel([]) :- !.
closel([_|T]) :-
	closel(T).


%%	index_file_name(-IndexFile, +Options) is nondet.
%
%	True if IndexFile is an autoload   index file. Options is passed
%	to  absolute_file_name/3.  This  predicate   searches  the  path
%	=autoload=.
%
%	@see file_search_path/2.

index_file_name(IndexFile, Options) :-
	absolute_file_name(autoload('INDEX'),
			   IndexFile,
			   [ file_type(prolog),
			     solutions(all),
			     file_errors(fail)
			   | Options
			   ]).

read_index([]) :- !.
read_index([H|T]) :- !,
	read_index(H),
	read_index(T).
read_index(Index) :-
	print_message(silent, autoload(read_index(Dir))),
	file_directory_name(Index, Dir),
	setup_call_cleanup(open(Index, read, In),
			   read_index_from_stream(Dir, In),
			   close(In)).

read_index_from_stream(Dir, In) :-
	repeat,
	    read(In, Term),
	    assert_index(Term, Dir), !.

assert_index(end_of_file, _) :- !.
assert_index(index(Name, Arity, Module, File), Dir) :- !,
	functor(Head, Name, Arity),
	atomic_list_concat([Dir, '/', File], Path),
	assertz(library_index(Head, Module, Path)),
	fail.
assert_index(Term, Dir) :-
	print_message(error, illegal_autoload_index(Dir, Term)),
	fail.


		/********************************
		*       CREATE INDEX.pl		*
		********************************/

%%	make_library_index(+Dir) is det.
%
%	Create an index for autoloading  from   the  directory  Dir. The
%	index  file  is  called  INDEX.pl.  In    Dir  contains  a  file
%	MKINDEX.pl, this file is loaded and we  assume that the index is
%	created by directives that appearin   this  file. Otherwise, all
%	source  files  are  scanned  for  their  module-header  and  all
%	exported predicates are added to the autoload index.
%
%	@see make_library_index/2

make_library_index(Dir0) :-
	absolute_file_name(Dir0, Dir),
	make_library_index2(Dir).

make_library_index2(Dir) :-
	plfile_in_dir(Dir, 'MKINDEX', MkIndex, AbsMkIndex),
	access_file(AbsMkIndex, read), !,
	setup_call_cleanup(working_directory(OldDir, Dir),
			   load_files(user:MkIndex, [silent(true)]),
			   working_directory(_, OldDir)).
make_library_index2(Dir) :-
	findall(Pattern, source_file_pattern(Pattern), PatternList),
	make_library_index2(Dir, PatternList).

%%	make_library_index(+Dir, +Patterns:list(atom)) is det.
%
%	Create an autoload index INDEX.pl for  Dir by scanning all files
%	that match any of the file-patterns in Patterns. Typically, this
%	appears as a directive in MKINDEX.pl.  For example:
%
%	  ==
%	  :- make_library_index(., ['*.pl']).
%	  ==
%
%	@see make_library_index/1.

make_library_index(Dir0, Patterns) :-
	absolute_file_name(Dir0, Dir),
	make_library_index2(Dir, Patterns).

make_library_index2(Dir, Patterns) :-
	plfile_in_dir(Dir, 'INDEX', Index, AbsIndex),
	access_file(AbsIndex, write), !,
	working_directory(OldDir, Dir),
	working_directory(NewDir, NewDir),
	expand_index_file_patterns(Patterns, Files),
	(   library_index_out_of_date(Index, Files)
	->  print_message(informational, make(library_index(NewDir))),
	    flag('$modified_index', _, true),
	    call_cleanup(do_make_library_index(Index, Files),
			 working_directory(_, OldDir))
	;   working_directory(_, OldDir)
	).
make_library_index2(Dir, _) :-
	throw(error(permission_error(write, index_file, Dir), _)).

source_file_pattern(Pattern) :-
	user:prolog_file_type(PlExt, prolog),
	atom_concat('*.', PlExt, Pattern).

plfile_in_dir(Dir, Base, PlBase, File) :-
	once(user:prolog_file_type(PlExt, prolog)),
	file_name_extension(Base, PlExt, PlBase),
	atomic_list_concat([Dir, '/', PlBase], File).

expand_index_file_patterns(Patterns, Files) :-
	phrase(files_from_patterns(Patterns), Files).

files_from_patterns([]) -->
	[].
files_from_patterns([P0|PT]) -->
	{ expand_file_name(P0, Files)
	},
	Files,
	files_from_patterns(PT).


library_index_out_of_date(Index, _Files) :-
	\+ exists_file(Index), !.
library_index_out_of_date(Index, Files) :-
	time_file(Index, IndexTime),
	(   time_file('.', DotTime),
	    DotTime @> IndexTime
	;   '$member'(File, Files),
	    time_file(File, FileTime),
	    FileTime @> IndexTime
	), !.


do_make_library_index(Index, Files) :-
	setup_call_cleanup(open(Index, write, Fd),
			   ( index_header(Fd),
			     index_files(Files, Fd)
			   ),
			   close(Fd)).


index_files([], _).
index_files([File|Files], Fd) :-
	open(File, read, In),
	call_cleanup(read(In, Term),
		     close(In)),
	(   Term = (:- module(Module, Public))
	->  file_name_extension(Base, _, File),
	    forall(public_predicate(Public, Name/Arity),
		   format(Fd, 'index((~k), ~k, ~k, ~k).~n',
			  [Name, Arity, Module, Base]))
	;   true
	),
	index_files(Files, Fd).

public_predicate(Public, PI) :-
	'$member'(PI0, Public),
	canonical_pi(PI0, PI).

canonical_pi(Var, _) :-
	var(Var), !, fail.
canonical_pi(Name/Arity, Name/Arity).
canonical_pi(Name//A0,   Name/Arity) :-
	Arity is A0 + 2.


index_header(Fd):-
	format(Fd, '/*  $Id', []),
	format(Fd, '$~n~n', []),
	format(Fd, '    Creator: make/0~n~n', []),
	format(Fd, '    Purpose: Provide index for autoload~n', []),
	format(Fd, '*/~n~n', []).


		 /*******************************
		 *	      EXTENDING		*
		 *******************************/

%%	autoload_path(+Path) is det.
%
%	Add Path to the libraries that are  used by the autoloader. This
%	extends the search  path  =autoload=   and  reloads  the library
%	index.  For example:
%
%	  ==
%	  :- autoload_path(library(http)).
%	  ==
%
%	If this call appears as a directive,  it is term-expanded into a
%	clause  for  user:file_search_path/2  and  a  directive  calling
%	reload_library_index/0. This keeps source information and allows
%	for removing this directive.

autoload_path(Alias) :-
	(   user:file_search_path(autoload, Alias)
	->  true
	;   assertz(user:file_search_path(autoload, Alias)),
	    reload_library_index
	).

system:term_expansion((:- autoload_path(Alias)),
		      [ user:file_search_path(autoload, Alias),
			(:- reload_library_index)
		      ]).
