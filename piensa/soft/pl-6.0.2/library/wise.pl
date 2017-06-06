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

:- module(wise_install,
	  [ wise_install/0,
	    wise_install_xpce/0,
	    unwise_install/0
	  ]).
:- use_module(library(progman)).
:- use_module(library(registry)).

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Helper module to get SWI-Prolog and   XPCE  installed properly under the
Wise installation shield. This module is  *not* for end-users (but might
be useful as an example for handling some Windows infra-structure).
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

:- dynamic
	variable/2.

unwise_install :-
	prompt_values,
	wise_install.

prompt_values :-
	new(D, dialog('Settings')),
	send(D, append, new(Reg, menu(register, choice))),
	send_list(Reg, append, [yes, no]),
	send(D, append, new(Ext, text_item(extension, pl))),
	send(D, append, new(Grp, text_item(group, 'SWI'))),
	expand_file_name(~, [Home]),
	send(D, append, new(Dir, text_item(directory, Home))),
	send(D, append, button(ok, message(D, return, ok))),
	send(D, append, button(cancel, message(D, destroy))),
	get(D, confirm_centered, _),
	(   get(Reg, selection, yes)
	->  assert(variable('REGISTER', true))
	;   assert(variable('REGISTER', false))
	),
	get(Ext, selection, ExtVal),
	assert(variable('EXT', ExtVal)),
	get(Grp, selection, GrpVal),
	assert(variable('GROUP', GrpVal)),
	get(Dir, selection, DirVal),
	assert(variable('PLCWD', DirVal)),
	send(D, destroy).


		 /*******************************
		 *	    COMMON PART		*
		 *******************************/

get_wise_variable(Name, Value) :-
	variable(Name, X), !,
	X = Value.
get_wise_variable(Name, Value) :-
	open_dde_conversation('WiseInst', Name, Handle),
	dde_request(Handle, -, RawVal),
	close_dde_conversation(Handle),
	name(RawVal, Chars),
	name(Value, Chars).		% --> atom or number

ensure_group(Group) :-
	progman_groups(ExistingGroups),
	(   member(Group, ExistingGroups)
	->  true
	;   progman_make_group(Group, swi)
	).


wise_install :-
	catch(do_wise_install, E, report_error(E)),
	format('~N~nAll done.', []),
	sleep(2),
	halt(0).
wise_install :-
	report_error(failed(wise_install)).

do_wise_install :-
	wise_install_xpce,
	shell_install.

shell_install :-
	(   get_wise_variable('REGISTER', true)
	->  wise_register_ext,
	    wise_register_icons
	;   true
	).

wise_register_ext :-
	(   get_wise_variable('EXT', Ext),
	    Ext \== ''
	->  shell_register_prolog(Ext),
	    current_prolog_flag(argv, [Me|_]),
	    format('Registered "~w" files to start ~w~n', [Ext, Me])
	;   true
	).

wise_register_icons :-
	(   get_wise_variable('GROUP', Group),
	    get_wise_variable('PLCWD', Cwd),
	    Cwd \== '',
	    Group \== ''
	->  Item = 'SWI-Prolog',
	    format('Installing icons in group ~w, for CWD=~w~n', [Group, Cwd]),
	    ensure_group(Group),
	    format('Created group ~w~n', [Group]),
	    current_prolog_flag(executable, PlFileName),
	    prolog_to_os_filename(PlFileName, CmdLine),
	    format('Commandline = ~w~n', [CmdLine]),
	    progman_make_item(Group, Item, CmdLine, Cwd)
	;   true
	).

wise_install_xpce :-			% no XPCE around
	\+ absolute_file_name(swi(xpce),
			      [ access(exist),
				file_type(directory),
				file_errors(fail)
			      ], _), !,
	format('Cannot find XPCE.~n', []).
wise_install_xpce :-
	delete_pce_common,
	set_prolog_flag(debug_on_error, false),
	qcompile_pce,
	qcompile_lib.

%	the file xpce/prolog/lib/pce_common.pl got into the distro by
%	accident in version 5.4.3.  We'll try to make sure to get rid
%	of it.

delete_pce_common :-
	(   absolute_file_name(swi('xpce/prolog/lib/pce_common.pl'),
			       [ access(exist),
				 file_errors(fail)
			       ],
			       Path)
	->  delete_file(Path)
	;   true
	).


		 /*******************************
		 *	 PRECOMPILED PARTS	*
		 *******************************/

qmodule(pce, library(pce)).
qmodule(lib, library(pce_manual)).
qmodule(lib, library(pcedraw)).
qmodule(lib, library('emacs/emacs')).
qmodule(lib, library('dialog/dialog')).
qmodule(lib, library('trace/trace')).

qcompile_pce :-
	set_prolog_flag(character_escapes, false),
	format('Checking library-index~n'),
	make,
	qcompile(library(pce)).

qcompile_lib :-
	format('Recompiling modules~n'),
	qmodule(lib, Module),
	format('~*c~n', [64, 0'*]),
	format('* Qcompile module ~w~n', [Module]),
	format('~*c~n', [64, 0'*]),
	once(qcompile(Module)),
	fail.
qcompile_lib.

		 /*******************************
		 *	     FEEDBACK		*
		 *******************************/

report_error(Message) :-
	format(user_error, '*******************************************~n', []),
	format(user_error, '* An error occurred~n', []),
	format(user_error, '*~n', []),
	format(user_error, '* Message: ', []),
	print_message(error, Message),
	format(user_error, '*~n', []),
	format(user_error, '* If a permission error occured on Windows NT/2000/XP~n', []),
	format(user_error, '* please re-install as administrator~n', []),
	format(user_error, '*~n', []),
	format(user_error, '* Please contact prolog-bugs@swi.psy.uva.nl~n', []),
	format(user_error, '*******************************************~n', []),
	format(user_error, '~n', []),
	format(user_error, 'Press any key to continue ...', []),
	get_single_char(_),
	halt.

:- multifile
	prolog:message/3.

prolog:message(failed(Command)) -->
	[ 'Command ~w failed for unknown reason'-[Command] ].
