/*  $Id$

    Part of SWI-Prolog

    Author:        Jan Wielemaker
    E-mail:        J.Wielemaker@cs.vu.nl
    WWW:           http://www.swi-prolog.org
    Copyright (C): 1985-2010, University of Amsterdam

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

:- prolog_load_context(directory, Dir),
   working_directory(_, Dir).

%	daily
%
%	True if this is a daily build

daily :-
	getenv('DAILY', true).

name :-
	daily, !,
	get_time(X),
	format_time(string(Date), '%F', X),
	format('Name "SWI-Prolog ~w"~n', [Date]).

name :-
	version(Major, Minor, Patch),
	get_time(X),
	format_time(string(Date), '%F', X),
	format('Name "SWI-Prolog ~w.~w.~w (~s)"~n',
	       [Major, Minor, Patch, Date]).

%%	outfile(-File:atom) is det.
%
%	Compute the name of the output file.

outfile(File) :-
	daily, !,
	outarch(Arch),
	get_time(X),
	format_time(string(Date), '%F', X),
	format(atom(File), '~wpl-~w.exe',
		[Arch, Date]).
outfile(File) :-
	outarch(Arch),
	version(Major, Minor, Patch),
	format(atom(File), '~wpl~w~w~w.exe',
	       [Arch, Major, Minor, Patch]).

outarch(w64) :-
	current_prolog_flag(arch, 'x64-win64'), !.
outarch(w32).

outfile :-
	outfile(File),
	format('OutFile "~w"~n', [File]).

%packages :-
%	exists_source(library(space/space)),
%	format('!define PKG_SPATIAL 1~n').
packages.

copy_script :-
	daily, !,
	tell('copypl.bat'),
	outfile(File),
	format('rsync "~s" gollem:MS-Windows/DailyBuilds~n', [File]),
	told.
copy_script.

version(Major, Minor, Patch) :-
	current_prolog_flag(version, V),
	Major is V//10000,
	Minor is V//100 mod 100,
	Patch is V mod 100.

run :-
	tell('version.nsi'),
	name,
	outfile,
	forall(packages, true),
	told,
	copy_script.


		 /*******************************
		 *	       DEFINES		*
		 *******************************/

:- dynamic
	def/2.

%%	get_defines is det.
%
%	Process /DName and /DName=Value options. Asserts facts to
%	def(Name, Value)

get_defines :-
	current_prolog_flag(argv, AV),
	append(_, [--|Argv], AV), !,
	maplist(assert_defines, Argv).
get_defines.

assert_defines(Def) :-
	atom_codes(Def, Codes),
	phrase(def(Name, Value), Codes),
	assert(def(Name, Value)).

def(Name, Value) -->
	"/D", string(NameCodes), "=", string(ValueCodes), eos, !,
	{ atom_codes(Name, NameCodes),
	  atom_codes(Value, ValueCodes)
	}.
def(Name, '1') -->
	"/D", string(NameCodes), eos, !,
	{ atom_codes(Name, NameCodes)
	}.


%%	expand_defs(+Codes, -Expanded) is det.
%
%	Expand ${Name} in Codes using defs

expand_defs([], []) :- !.
expand_defs([0'$, 0'{|T0], Expanded) :-
	append(NameCodes, [0'}|Rest], T0), !,
	atom_codes(Name, NameCodes),
	(   def(Name, Value)
	->  true
	;   throw(error(existence_error(def, Name), _))
	),
	atom_codes(Value, ValueCodes),
	append(ValueCodes, RestOut, Expanded), !,
	expand_defs(Rest, RestOut).
expand_defs([H|T0], [H|T]) :-
	expand_defs(T0, T).



		 /*******************************
		 *	       CHECK		*
		 *******************************/

:- dynamic
	install_file/1,
	install_dir/1.

parse_script(Script) :-
	retractall(install_file(_)),
	retractall(install_dir(_)),
	open(Script, read, In),
	read_line_to_codes(In, Line0),
	process_file_decls(Line0, In),
	close(In).

process_file_decls(end_of_file, _) :- !.
process_file_decls(Line, In) :-
%	format('~s~n', [Line]),
	phrase(process_file_decl, Line),
	read_line_to_codes(In, Line1),
	process_file_decls(Line1, In).

process_file_decl -->
	ws, "File", blank, ws, !,
	(   "/r", ws
	->  path(Dir),
	    { assert(install_dir(Dir))
	    }
	;   "/oname="
	->  path(_Oname),
	    blank, ws,
	    path(File)
	;   path(File),
	    { assert(install_file(File))
	    }
	),
	ws.
process_file_decl -->
	string(_),
	eos.

path(Path) -->
	token(Token),
	{ prolog_to_os_filename(Path, Token)
	}.

token(Value) -->
	(   "\""
	->  string(Codes),
	    "\""
	;   "'"
	->  string(Codes),
	    "'"
	;   string(Codes),
	    sep
	), !,
	{ expand_defs(Codes, Expanded),
	  name(Value, Expanded)
	}.

sep -->
	peek_blank, !.
sep -->
	eos.

ws -->
	blank, !,
	ws.
ws -->
	[].

blank -->
	[C],
	{ nonvar(C),
	  code_type(C, space)
	}.

string(String, In, Rest) :-
	append(String, Rest, In).

eos([], []).

peek_blank -->
	peek(C),
	{ code_type(C, space)
	}.

peek(C, X, X) :-
	X = [C|_].

%	check_covered(+Dir)
%
%	See whether all files in Dir are covered by some install
%	instruction.

check_covered([]) :- !.
check_covered([H|T]) :- !,
	check_covered(H),
	check_covered(T).
check_covered(Dir) :-
	exists_directory(Dir), !,
	(   install_dir(D),
	    same_file(Dir, D)
	->  already_covered(D)
	;   atom_concat(Dir, '/*', Pattern),
	    expand_file_name(Pattern, Entries),
	    check_covered(Entries)
	).
check_covered(File) :-
	install_file(F),
	same_file(F, File), !.
check_covered(Path) :-
	ignore_file(File),
	file_base_name(Path, File), !.
check_covered(Path) :-
	file_directory_name(Path, Dir),
	ignore_dir(Dir), !.
check_covered(File) :-
	flag(errors, E, E+1),
	print_message(error, format('File ~w is not covered by installer',
				    [File])).

already_covered(Dir) :-
	(   install_file(File),
	    atom_concat(Dir, X, File),
	    sub_atom(X, 0, _, _, /),
	    flag(errors, E, E+1),
	    print_message(error, format('File ~w already covered by ~w',
					[File, Dir])),
	    fail
	;   true
	).

check_files :-
	parse_script('pl.nsi'),
	flag(errors, Old, 0),
	check_covered(pl),
	flag(errors, New, Old),
	New == 0.

ignore_file('INDEX.pl').
ignore_file('plwin.opt').
ignore_file('pl2xpce.pdb').
ignore_file('dlltest.pdb').
ignore_file('double_metaphone.pdb').
ignore_file('porter_stem.pdb').
ignore_file('Support SWI-Prolog development.url').
ignore_file('SWI-Prolog website.url').
ignore_file('uninstall.exe').

% ignore the space-package
ignore_file('space.pdb').
ignore_file('space.dll').
ignore_file('geos.dll').
ignore_file('spatialindex1.dll').
ignore_file('space.html').

ignore_dir('pl/library/space').


		 /*******************************
		 *	       RUN IT		*
		 *******************************/

main :-
	(   get_defines,
	    run,
	    check_files,
	    halt
	;   halt(1)
	).

% :- main.

