# SWI-Prolog install-script

!define TEMP1 $R0 ; Temp variable
!define EXT    $3 ; Filename extension for Prolog sources
!define CWD    $4 ; Working directory for startmenu shortcut
!define GRP    $5 ; Startmenu group
!define SHCTX  $6 ; Shell context (current/all)
!define ARCH   $7 ; Architecture (x86, ia64 or amd64)
!define SXSLEN $8 ; The length of the string of the location of the SideBySide directory

!ifdef WIN64
!define REGKEY SOFTWARE\SWI\Prolog64
!else
!define REGKEY SOFTWARE\SWI\Prolog
!endif

!system "pl\bin\swipl.exe -f mkinstaller.pl -g true -t main -- /DPTHREAD=${PTHREAD} /DZLIB=${ZLIB} /DBOOT=${BOOT}" = 0
!include "version.nsi"

RequestExecutionLevel admin
SetCompressor bzip2
MiscButtonText "<back" "next>" "abort" "finished"

# Preload files that are needed by the installer itself
ReserveFile "${NSISDIR}\Plugins\UserInfo.dll"
ReserveFile "${NSISDIR}\Plugins\InstallOptions.dll"
ReserveFile "options.ini"

InstallDir $PROGRAMFILES\pl
InstallDirRegKey HKLM ${REGKEY} "home"
ComponentText "This will install the SWI-Prolog on your computer. \
               Select which optional components you want installed."
DirText "This program will install SWI-Prolog on your computer.\
         Choose a directory"

LicenseData pl\COPYING.TXT
LicenseText "SWI-Prolog is governed by the LGPL"

InstType "Typical (all except debug symbols)"	# 1
InstType "Minimal (no graphics)"		# 2
InstType "Full"					# 3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Make sure we have the VC8 runtime environment
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!ifdef WIN64
!define MACHTYPE "amd"
!define REDISTFILE "vcredist_x64.exe"
!define VCRT_URL "http://download.microsoft.com/download/d/2/4/d242c3fb-da5a-4542-ad66-f9661d0a8d19/vcredist_x64.exe"
!else
!define MACHTYPE "x86"
!define REDISTFILE "vcredist_x32.exe"
!define VCRT_URL "http://download.microsoft.com/download/d/d/9/dd9a82d0-52ef-40db-8dab-795376989c03/vcredist_x86.exe"
!endif


!macro CallFindFiles DIR FILE CBFUNC
Push "${DIR}"
Push "${FILE}"
Push $0
GetFunctionAddress $0 "${CBFUNC}"
Exch $0
Call FindFiles
!macroend

Section "Microsoft VC runtime libraries"
  SectionIn 1 2 3
  ; Only checking the Windows Side-by-Side folder for occurences of mcvcr90.dll
  ; Change msvcr90.dll into something non-existen to force download for testing
  ; purposes.
  ; Set length of the windows side by side string length.
  StrLen ${SXSLEN} "$WINDIR\WinSxS\"
  !insertmacro CallFindFiles "$WINDIR\WinSxS" msvcr90.dll FindVCRT
  ; have to check again, now to deteremine to launch the downloader (or not)...
  StrCmp $0 ${MACHTYPE} found not_found
    found:
    Return
    not_found:
    ; for debug
    ; MessageBox MB_OK "Couldn't find msvcr_90.dll"
    call GetVCRT
SectionEnd


Function GetVCRT
        MessageBox MB_YESNO "Microsoft Visual C++ 2008 SP1 Redistributable will now be$\r$\n\
                             downloaded and installed.$\r$\n$\n\
                             Administrative rights might be required! Do you want \
                             to continue?"\
                   IDYES download_install IDNO abort_install

        download_install:
        StrCpy $2 "$TEMP\${REDISTFILE}"
        nsisdl::download /TIMEOUT=30000 ${VCRT_URL} $2
        Pop $R0 ;Get the return value
                StrCmp $R0 "success" +3
                MessageBox MB_OK "Download failed: $R0"
                Quit
        ClearErrors
        ExecWait "$2 /q"
        IfErrors failure dl_ok

        failure:
        MessageBox MB_OK "An error has occured, Microsoft Visual C++ 2008 SP1 \
                          Redistributable$\r$\n\
                          has not been installed"
        goto abort_install

        dl_ok:
        MessageBox MB_YESNO "Microsoft Visual C++ 2008 SP1 Redistributable$\r$\n\
                             has been installed successfully to your system,$\r$\n\
                             in order to finalise the installation, a reboot is \
                             required.$\r$\n$\n\
                             Would you like to reboot now?"\
                   IDYES re_boot IDNO abort_install

        re_boot:
        MessageBox MB_OK "After your system has rebooted, you will have to re-start the$\r$\n\
                          the SWI-Prolog installation process by clicking on the installer."
        Delete $2
        Reboot
        Return

        abort_install:
        Abort "Installation has been interupted"
FunctionEnd


Function FindVCRT
  Pop $0

  ; Checking for the first 3 characters of the WinSxS sub-dirs, they start with
  ; either amd64_ or x86_, so first get those 3 characters:
  StrCpy $0 $0 3 ${SXSLEN}
  ; and then compare
  StrCmp $0 ${MACHTYPE} found not_found

  found:
  ; set the stop criterium
  Push "stop"
  Return

  not_found:
  ; avoid stack corruption
  Push "continue"
FunctionEnd

; Function taken from here: http://nsis.sourceforge.net/Search_For_a_File

Function FindFiles
  Exch $R5 # callback function
  Exch
  Exch $R4 # file name
  Exch 2
  Exch $R0 # directory
  Push $R1
  Push $R2
  Push $R3
  Push $R6

  Push $R0 # first dir to search

  StrCpy $R3 1

  nextDir:
    Pop $R0
    IntOp $R3 $R3 - 1
    ClearErrors
    FindFirst $R1 $R2 "$R0\*.*"
    nextFile:
      StrCmp $R2 "." gotoNextFile
      StrCmp $R2 ".." gotoNextFile

      StrCmp $R2 $R4 0 isDir
        Push "$R0\$R2"
        Call $R5
        Pop $R6
        StrCmp $R6 "stop" 0 isDir
          loop:
            StrCmp $R3 0 done
            Pop $R0
            IntOp $R3 $R3 - 1
            Goto loop

      isDir:
        IfFileExists "$R0\$R2\*.*" 0 gotoNextFile
          IntOp $R3 $R3 + 1
          Push "$R0\$R2"

  gotoNextFile:
    FindNext $R1 $R2
    IfErrors 0 nextFile

  done:
    FindClose $R1
    StrCmp $R3 0 0 nextDir

  Pop $R6
  Pop $R3
  Pop $R2
  Pop $R1
  Pop $R0
  Pop $R5
  Pop $R4
FunctionEnd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; End MSVCRT check/install
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!ifdef WIN64
Page custom Check64 "" ": Checking for AMD64 architecture"
!endif
Page license
Page components
Page directory
Page custom SetCustom "" ": Installation options"
Page instfiles

Section "Base system (required)"
  SectionIn RO			# do not allow to delete this

  Delete $INSTDIR\bin\*.pdb
  RmDir /r pl\custom		# old location of pl\customize

  SetOutPath $INSTDIR\bin
  File pl\bin\swipl.exe
  File pl\bin\swipl-win.exe
  File pl\bin\swipl.dll
  File pl\bin\plterm.dll
  File pl\bin\plregtry.dll
  File pl\bin\${PTHREAD}.dll

  SetOutPath $INSTDIR
  File /r pl\customize
  File pl\${BOOT}
  File pl\COPYING.TXT
  File pl\README.TXT
  File pl\VERSION
  File pl\swipl.home

  SetOutPath $INSTDIR\library
; SYSTEM STUFF
  File pl\library\listing.pl
  File pl\library\qsave.pl
  File pl\library\statistics.pl
  File pl\library\writef.pl
  File pl\library\shlib.pl
  File pl\library\system.pl
  File pl\library\threadutil.pl
  File pl\library\thread.pl
  File pl\library\thread_pool.pl
  File pl\library\tty.pl
  File pl\library\dif.pl
  File pl\library\when.pl
  File pl\library\varnumbers.pl
  File pl\library\prolog_stack.pl
  File pl\library\prolog_clause.pl
  File pl\library\prolog_xref.pl
  File pl\library\prolog_source.pl
  File pl\library\prolog_history.pl
  File pl\library\prolog_breakpoints.pl
  File pl\library\prolog_autoload.pl
  File pl\library\prolog_colour.pl
  File pl\library\predicate_options.pl

; COMPATIBILITY
  File pl\library\backcomp.pl
  File pl\library\edinburgh.pl
  File pl\library\qpforeign.pl
  File pl\library\quintus.pl
  File pl\library\files.pl
  File pl\library\charsio.pl
  File pl\library\codesio.pl
  File pl\library\arithmetic.pl

; `STANDARD LIBRARIES'
  File pl\library\ctypes.pl
  File pl\library\gensym.pl
  File pl\library\lists.pl
  File pl\library\sort.pl
  File pl\library\ugraphs.pl
  File pl\library\occurs.pl
  File pl\library\ordsets.pl
  File pl\library\oset.pl
  File pl\library\assoc.pl
  File pl\library\rbtrees.pl
  File pl\library\nb_rbtrees.pl
  File pl\library\nb_set.pl
  File pl\library\operators.pl
  File pl\library\heaps.pl
  File pl\library\broadcast.pl
  File pl\library\error.pl
  File pl\library\pairs.pl
  File pl\library\record.pl
  File pl\library\settings.pl
  File pl\library\terms.pl
  File pl\library\apply_macros.pl
  File pl\library\apply.pl
  File pl\library\aggregate.pl
  File pl\library\pure_input.pl
  File pl\library\pio.pl
  File pl\library\coinduction.pl

; WINDOWS
  File pl\library\dde.pl
  File pl\library\progman.pl
  File pl\library\registry.pl
  File pl\library\win_menu.pl
  File pl\library\wise.pl

; DEVELOPMENT
  File pl\library\edit.pl
  File pl\library\make.pl
  File pl\library\hotfix.pl
  File pl\library\explain.pl
  File pl\library\debug.pl
  File pl\library\portray_text.pl
  File pl\library\vm.pl
  File pl\library\check.pl
  File pl\library\checklast.pl
  File pl\library\checkselect.pl
  File pl\library\shell.pl

; WEB STUFF
  File pl\library\www_browser.pl
  File pl\library\url.pl
  File pl\library\utf8.pl
  File pl\library\base32.pl
  File pl\library\base64.pl

; MISC
  File pl\library\am_match.pl
  File pl\library\readln.pl
  File pl\library\readutil.pl
  File pl\library\streampool.pl
  File pl\library\option.pl
  File pl\library\date.pl
  File pl\library\main.pl
  File pl\library\csv.pl
  File pl\library\persistency.pl
  File pl\library\ansi_term.pl
  File pl\library\optparse.pl

; UNICODE
  SetOutPath $INSTDIR\library\unicode
  File pl\library\unicode\blocks.pl
  File pl\library\unicode\unicode_data.pl

  SetOutPath $INSTDIR\doc
  File pl\doc\windows.html
  SetOutPath $INSTDIR\doc\packages
  File pl\doc\packages\index.html

  WriteRegStr HKLM ${REGKEY} "home" "$INSTDIR"

  ; Write uninstaller
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SWI-Prolog" "DisplayName" "SWI-Prolog (remove only)"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SWI-Prolog" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteUninstaller "uninstall.exe"
SectionEnd

Section "Documentation and Help-system"
  SectionIn 1 3
  SetOutPath $INSTDIR
  File pl\RelNotes-5.10.TXT
  SetOutPath $INSTDIR\library
  File pl\library\MANUAL
  File pl\library\helpidx.pl
  File pl\library\help.pl
SectionEnd

Section "PDT support files"
  SectionIn 1 3
  SetOutPath $INSTDIR\library
  File pl\library\pdt_console.pl
  SetOutPath $INSTDIR\bin
  File pl\bin\pdt_console.dll
  SetOutPath $INSTDIR\doc\packages
  File pl\doc\packages\pdt.html
SectionEnd

Section "Unicode library (utf8proc)"
  SectionIn 1 3
  SetOutPath $INSTDIR\library
  File pl\library\unicode.pl
  SetOutPath $INSTDIR\bin
  File pl\bin\unicode4pl.dll
  SetOutPath $INSTDIR\doc\packages
  File pl\doc\packages\utf8proc.html
SectionEnd

Section "Constraint Handling Rules"
  SectionIn 1 3
  SetOutPath $INSTDIR\library
  File pl\library\chr.pl
  SetOutPath $INSTDIR\library\chr
  File pl\library\chr\chr_runtime.pl
  File pl\library\chr\chr_messages.pl
  File pl\library\chr\chr_debug.pl
  File pl\library\chr\chr_op.pl
  File pl\library\chr\chr_translate.pl
  File pl\library\chr\pairlist.pl
  File pl\library\chr\a_star.pl
  File pl\library\chr\binomialheap.pl
  File pl\library\chr\builtins.pl
  File pl\library\chr\chr_hashtable_store.pl
  File pl\library\chr\clean_code.pl
  File pl\library\chr\find.pl
  File pl\library\chr\listmap.pl
  File pl\library\chr\guard_entailment.pl
  File pl\library\chr\chr_compiler_options.pl
  File pl\library\chr\chr_compiler_utility.pl
  File pl\library\chr\chr_compiler_errors.pl
  File pl\library\chr\chr_integertable_store.pl
  File pl\library\chr\README.TXT
  SetOutPath $INSTDIR\doc\packages\examples
  File /r pl\doc\packages\examples\chr
SectionEnd

Section "CLP"
  SectionIn 1 3
  SetOutPath $INSTDIR\library\clp
  File pl\library\clp\bounds.pl
  File pl\library\clp\clp_events.pl
  File pl\library\clp\clp_distinct.pl
  File pl\library\clp\simplex.pl
  File pl\library\clp\clpfd.pl
SectionEnd

Section "CLP on real and rational numbers: CLP(Q,R)"
  SectionIn 1 3
  Delete $INSTDIR\library\clp\clpqr\ugraphs.pl
  SetOutPath $INSTDIR\library\clp
  File /r pl\library\clp\clpr
  File /r pl\library\clp\clpq
  File /r pl\library\clp\clpqr
  File pl\library\clp\clpr.pl
  File pl\library\clp\clpq.pl
SectionEnd

Section "Portability (YAP, SICStus, Ciao, BIM, IF/Prolog) support"
  SectionIn 1 3
  SetOutPath $INSTDIR\library
  File pl\library\fastrw.pl
  File pl\library\dialect.pl
  File /r pl\library\dialect
SectionEnd

Section "Demo files"
  SectionIn 1 3
  SetOutPath $INSTDIR
  File /r pl\demo
  SetOutPath $INSTDIR\bin
  File pl\bin\dlltest.dll
SectionEnd

Section "C/C++ Interface"
  SectionIn 1 3
  SetOutPath $INSTDIR\lib
  File pl\lib\swipl.lib
  File pl\lib\plterm.lib
  File pl\lib\${PTHREAD}.lib
  SetOutPath $INSTDIR
  File /r pl\include
  SetOutPath $INSTDIR\bin
  File pl\bin\swipl-ld.exe
  File pl\bin\swipl-rc.exe
  SetOutPath $INSTDIR\doc\packages
  File pl\doc\packages\pl2cpp.html
SectionEnd

Section "JPL -- Java <-> Prolog"
  SectionIn 1 3
  SetOutPath $INSTDIR\bin
  File pl\bin\jpl.dll
  SetOutPath $INSTDIR\lib
  File pl\lib\jpl.jar
  SetOutPath $INSTDIR\library
  File pl\library\jpl.pl
  SetOutPath $INSTDIR\doc\packages
  File /r pl\doc\packages\jpl
  SetOutPath $INSTDIR\doc\packages\examples
  File /r pl\doc\packages\examples\jpl
SectionEnd

Section "XPCE graphics library"
  SectionIn 1 3
  SetOutPath $INSTDIR
  Delete $INSTDIR\xpce\prolog\lib\pce_common.pl
  File /r pl\xpce
  File pl\swipl-win.rc
  SetOutPath $INSTDIR\bin
  File pl\bin\pl2xpce.dll
  File pl\bin\xpce-stub.exe
SectionEnd

Section "Package CLIB"
  SectionIn 1 3
  SetOutPath $INSTDIR\bin
  File pl\bin\cgi.dll
  File pl\bin\crypt.dll
  File pl\bin\files.dll
  File pl\bin\sha4pl.dll
  File pl\bin\uri.dll
  File pl\bin\memfile.dll
  File pl\bin\mime.dll
  File pl\bin\socket.dll
  File pl\bin\time.dll
  File pl\bin\readutil.dll
  File pl\bin\process.dll
  SetOutPath $INSTDIR\library
  File pl\library\cgi.pl
  File pl\library\crypt.pl
  File pl\library\filesex.pl
  File pl\library\sha.pl
  File pl\library\uri.pl
  File pl\library\memfile.pl
  File pl\library\mime.pl
  File pl\library\socket.pl
  File pl\library\prolog_server.pl
  File pl\library\random.pl
  File pl\library\time.pl
  File pl\library\process.pl
  SetOutPath $INSTDIR\doc\packages
  File pl\doc\packages\clib.html
SectionEnd

Section "SSL Interface"
  SectionIn 1 3
  SetOutPath $INSTDIR\bin
  File pl\bin\ssl4pl.dll
  SetOutPath $INSTDIR\library
  File pl\library\ssl.pl
# SetOutPath $INSTDIR\library\http
# File pl\library\http\http_ssl_plugin.pl
  SetOutPath $INSTDIR\doc\packages
  File pl\doc\packages\ssl.html
  SetOutPath $INSTDIR\doc\packages\examples
  File /r pl\doc\packages\examples\ssl
SectionEnd

Section "ODBC Interface"
  SectionIn 1 3
  SetOutPath $INSTDIR\bin
  File pl\bin\odbc4pl.dll
  SetOutPath $INSTDIR\library
  File pl\library\odbc.pl
  SetOutPath $INSTDIR\doc\packages
  File pl\doc\packages\odbc.html
SectionEnd

Section "Google protocol buffers"
  SectionIn 1 3
  SetOutPath $INSTDIR\bin
  File pl\bin\protobufs.dll
  SetOutPath $INSTDIR\library
  File pl\library\protobufs.pl
  SetOutPath $INSTDIR\doc\packages
  File pl\doc\packages\protobufs.html
SectionEnd

Section "SGML/XML/HTML parser"
  SectionIn 1 3
  SetOutPath $INSTDIR\bin
  File pl\bin\sgml2pl.dll
  SetOutPath $INSTDIR\library
  File /r pl\library\DTD
  File pl\library\sgml.pl
  File pl\library\sgml_write.pl
  File pl\library\xsdp_types.pl
  File pl\library\iso_639.pl
  File pl\library\xpath.pl
  File pl\library\pwp.pl
  SetOutPath $INSTDIR\doc\packages
  File pl\doc\packages\sgml.html
SectionEnd

Section "RDF and Semantic Web Library"
  SectionIn 1 3
  SetOutPath $INSTDIR\bin
  File pl\bin\rdf_db.dll
  File pl\bin\turtle.dll

  SetOutPath $INSTDIR\library
  File pl\library\rdf.pl
  File pl\library\rdf_parser.pl
  File pl\library\rdf_triple.pl
  File pl\library\rewrite.pl
  File pl\library\rdf_ntriples.pl
  File pl\library\rdf_write.pl
  File /r pl\library\semweb

  SetOutPath $INSTDIR\doc\packages
  File pl\doc\packages\rdf2pl.html
  File pl\doc\packages\semweb.html
  File pl\doc\packages\modules.gif
SectionEnd

Section "HTTP Client/Server package"
  SectionIn 1 3
  SetOutPath $INSTDIR\bin
  File pl\bin\http_stream.dll
  File pl\bin\json.dll
  SetOutPath $INSTDIR\library
  File /r pl\library\http
  SetOutPath $INSTDIR\doc\packages
  File pl\doc\packages\http.html
  File pl\doc\packages\httpserver.gif
  SetOutPath $INSTDIR\doc\packages\examples
  File /r pl\doc\packages\examples\http
SectionEnd

Section "Table package"
  SectionIn 1 3
  SetOutPath $INSTDIR\bin
  File pl\bin\table.dll
  SetOutPath $INSTDIR\library
  File pl\library\table.pl
  File pl\library\table_util.pl
  SetOutPath $INSTDIR\doc\packages
  File pl\doc\packages\table.html
SectionEnd

Section "NLP package"
  SectionIn 1 3
  SetOutPath $INSTDIR\bin
  File pl\bin\porter_stem.dll
  File pl\bin\snowball.dll
  File pl\bin\double_metaphone.dll
  File pl\bin\isub.dll
  SetOutPath $INSTDIR\library
  File pl\library\porter_stem.pl
  File pl\library\snowball.pl
  File pl\library\double_metaphone.pl
  File pl\library\isub.pl
  SetOutPath $INSTDIR\doc\packages
  File pl\doc\packages\nlp.html
SectionEnd

Section "R-project interface"
  SectionIn 1 3
  SetOutPath $INSTDIR\library
  File pl\library\R.pl
  SetOutPath $INSTDIR\doc\packages
  File pl\doc\packages\R.html
  SetOutPath $INSTDIR\doc\packages\examples
  File /r pl\doc\packages\examples\R
SectionEnd

Section "ZLIB package"
  SectionIn 1 3
  SetOutPath $INSTDIR\bin
  File pl\bin\zlib4pl.dll
  File pl\bin\${ZLIB}.dll
  SetOutPath $INSTDIR\library
  File pl\library\zlib.pl
  SetOutPath $INSTDIR\doc\packages
  File pl\doc\packages\zlib.html
SectionEnd

Section "Unit test package"
  SectionIn 1 3
  SetOutPath $INSTDIR\library
  File pl\library\plunit.pl
  File pl\library\test_wizard.pl
  File pl\library\test_cover.pl
  SetOutPath $INSTDIR\doc\packages
  File pl\doc\packages\plunit.html
  SetOutPath $INSTDIR\doc\packages\examples
  File /r pl\doc\packages\examples\plunit
SectionEnd

Section "Documentation package"
  SectionIn 1 3
  SetOutPath $INSTDIR\library
  File /r pl\library\pldoc
  SetOutPath $INSTDIR\library
  File pl\library\pldoc.pl
  File pl\library\doc_http.pl
  File pl\library\doc_latex.pl
  SetOutPath $INSTDIR\doc\packages
  File pl\doc\packages\pldoc.html
  SetOutPath $INSTDIR\doc
  File /r pl\doc\Manual
  SetOutPath $INSTDIR\doc\packages\examples
  File /r pl\doc\packages\examples\pldoc
SectionEnd

Section "C Debugging Symbols (.pdb files)"
  SectionIn 3
  SetOutPath $INSTDIR\bin
  File pl\bin\cgi.pdb
  File pl\bin\swipl.pdb
  File pl\bin\memfile.pdb
  File pl\bin\mime.pdb
  File pl\bin\odbc4pl.pdb
  File pl\bin\plterm.pdb
  File pl\bin\swipl-win.pdb
  File pl\bin\sgml2pl.pdb
  File pl\bin\socket.pdb
  File pl\bin\time.pdb
  File pl\bin\readutil.pdb
  File pl\bin\process.pdb
  File pl\bin\ssl4pl.pdb
  File pl\bin\zlib4pl.pdb
  File pl\bin\sha4pl.pdb
  File pl\bin\uri.pdb
  File pl\bin\files.pdb
  File pl\bin\http_stream.pdb
  File pl\bin\json.pdb
  File pl\bin\snowball.pdb
  File pl\bin\isub.pdb
  File pl\bin\protobufs.pdb
  File pl\bin\plregtry.pdb
  File pl\bin\unicode4pl.pdb
SectionEnd

Section "Sources for system predicates"
  SectionIn 1 3
  SetOutPath $INSTDIR
  File /r pl\boot
  SetOutPath $INSTDIR\bin
  File pl\bin\mkboot.bat
SectionEnd

Section "Shell Extensions" SecShell
  SectionIn 1 2 3
  ClearErrors
  ; back up old value of .pl
  ReadRegStr $1 HKCR .${EXT} ""
  IfErrors Label1
  StrCmp $1 "" Label1
    StrCmp $1 "PrologFile" Label1
    WriteRegStr HKCR .${EXT} "backup_val" $1
  Label1:
  WriteRegStr HKCR .${EXT} "" "PrologFile"

  ReadRegStr $0 HKCR "PrologFile" ""
  IfErrors 0 readOK
    StrCpy $0 "";
  readOK:
  StrCmp $0 "" 0 skipNSIAssoc
	WriteRegStr HKCR "PrologFile" "" "Prolog Source"
	WriteRegStr HKCR "PrologFile\shell" "" "open"
	WriteRegStr HKCR "PrologFile\DefaultIcon" "" $INSTDIR\bin\swipl-win.exe,0
  skipNSIAssoc:
  ; OPEN
  WriteRegStr HKCR "PrologFile\shell\open\command" "" '"$INSTDIR\bin\swipl-win.exe" "%1"'
  ; Bind `edit' to call PceEmacs
  WriteRegStr HKCR "PrologFile\shell\pceEmacs" "" "Open in PceEmacs"
  WriteRegStr HKCR "PrologFile\shell\pceEmacs\command" "" '"$INSTDIR\bin\swipl-win.exe" -g start_emacs,send(@(pce),show_console,iconic),send(@(emacs),show_buffer_menu)'
  WriteRegStr HKCR "PrologFile\shell\pceEmacs\ddeexec" "" "edit %1"
  WriteRegStr HKCR "PrologFile\shell\pceEmacs\ddeexec\Application" "" "PceEmacs"
  WriteRegStr HKCR "PrologFile\shell\pceEmacs\ddeexec\Topic" "" "control"
!ifdef SHELL_DDE
  ; EDIT (these are not yet correct)
  ; CONSULT
  WriteRegStr HKCR "PrologFile\shell\consult" "" "Load Prolog Source"
  WriteRegStr HKCR "PrologFile\shell\consult\command" "" '"$INSTDIR\bin\swipl-win.exe'
  WriteRegStr HKCR "PrologFile\shell\consult\ddeexec" "" "consult('%1')"
  WriteRegStr HKCR "PrologFile\shell\consult\ddeexec" "Application" "prolog"
  WriteRegStr HKCR "PrologFile\shell\consult\ddeexec" "ifexec" ""
  WriteRegStr HKCR "PrologFile\shell\consult\ddeexec" "Topic" "control"
!endif

  WriteRegStr HKLM ${REGKEY} fileExtension ${EXT}

  IfErrors 0 NoError
    MessageBox MB_OK "Could not write registry to register filetypes\n \
		      You may wish to retry the installation with\n \
		      sufficient privileges or accept the ${EXT} files\n \
		      cannot be opened from the shell and Prolog does not\n \
		      appear in the start menu"
NoError:
SectionEnd

!macro Create_Internet_Shorcut URLName URLhost
  FileOpen $0 "$INSTDIR\doc\${URLName}.url" w
  FileWrite $0 "[InternetShortcut]$\r$\n"
  FileWrite $0 "URL=${URLhost}"
  FileClose $0
  CreateShortCut "$SMPROGRAMS\${GRP}\${URLName}.lnk" \
		 "$INSTDIR\doc\${URLName}.url" "" \
		 "$INSTDIR\doc\${URLName}.url" \
		 0 "SW_SHOWNORMAL" "" "Visit the Web site"
!macroend

Section "Start Menu shortcuts"
  SectionIn 1 2 3
  SetOutPath ${CWD}
  CreateDirectory "$SMPROGRAMS\${GRP}"
  IfFileExists "$SMPROGRAMS\${GRP}\XPCE.lnk" 0 NoOldXPCE
    Delete "$SMPROGRAMS\${GRP}\XPCE.lnk"
  NoOldXPCE:
  CreateShortCut "$SMPROGRAMS\${GRP}\Prolog.lnk" \
		 "$INSTDIR\bin\swipl-win.exe" \
		 "--win_app" \
		 "$INSTDIR\bin\swipl-win.exe" \
		 0
  SetOutPath $INSTDIR
  CreateShortCut "$SMPROGRAMS\${GRP}\Readme.lnk" \
		  "$INSTDIR\doc\windows.html" "" \
		  "$INSTDIR\doc\windows.html" 0 \
		  "SW_SHOWNORMAL" "" "View readme"
  !insertmacro Create_Internet_Shorcut "SWI-Prolog website" \
		 "http://www.swi-prolog.org"
  !insertmacro Create_Internet_Shorcut "Support SWI-Prolog development" \
		 "http://www.swi-prolog.org/donate.html"
  CreateShortCut "$SMPROGRAMS\${GRP}\Uninstall.lnk" \
		 "$INSTDIR\uninstall.exe" \
		 "" \
		 "$INSTDIR\uninstall.exe" \
		 0

  WriteRegStr HKLM ${REGKEY} group   ${GRP}
  WriteRegStr HKLM ${REGKEY} cwd     ${CWD}
  WriteRegStr HKLM ${REGKEY} context ${SHCTX}
SectionEnd

Section "Update library index"
  SectionIn RO			# do not allow to delete this
  ExecWait '"$INSTDIR\bin\swipl-win.exe" -f none -g "make_library_index(swi(library)),halt"'
  ExecWait '"$INSTDIR\bin\swipl-win.exe" -f none -g "win_flush_filetypes,halt"'
SectionEnd

Section "Precompiled libraries"
  SectionIn RO			# do not allow to delete this
  ExecWait '"$INSTDIR\bin\swipl-win.exe" -f none -g wise_install_xpce,halt'
SectionEnd

################################################################
# The uninstaller
################################################################

UninstallText "This will uninstall SWI-Prolog. Hit Uninstall to continue."

Section "Uninstall"
  ReadRegStr ${EXT}   HKLM Software\SWI\Prolog fileExtension
  ReadRegStr ${GRP}   HKLM Software\SWI\Prolog group
  ReadRegStr ${SHCTX} HKLM Software\SWI\Prolog context

  StrCmp ${SHCTX} "all" 0 +2
    SetShellVarContext all

  MessageBox MB_YESNO "Delete the following components?$\r$\n \
                       Install dir: $INSTDIR$\r$\n \
		       Extension: ${EXT}$\r$\n \
		       Program Group ${GRP}" \
		      IDNO Done

  StrCmp ".${EXT}" "" NoExt
    ReadRegStr $1 HKCR .${EXT} ""
    StrCmp $1 "PrologFile" 0 NoOwn ; only do this if we own it
      ReadRegStr $1 HKCR .${EXT} "backup_val"
      StrCmp $1 "" 0 RestoreBackup ; if backup == "" then delete the whole key
	DeleteRegKey HKCR .${EXT}
      Goto NoOwn
      RestoreBackup:
	WriteRegStr HKCR .${EXT} "" $1
	DeleteRegValue HKCR .${EXT} "backup_val"
    NoOwn:
  NoExt:

  StrCmp "${GRP}" "" NoGrp
    MessageBox MB_OK "Deleting $SMPROGRAMS\${GRP}"
    RMDir /r "$SMPROGRAMS\${GRP}"
  NoGrp:

  IfFileExists "$INSTDIR\bin\swipl-win.exe" 0 NoDir
    RMDir /r "$INSTDIR"
    goto Done

  NoDir:
    MessageBox MB_OK "Folder $INSTDIR doesn't seem to contain Prolog"

  Done:
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SWI-Prolog"
    DeleteRegKey HKLM ${REGKEY}
SectionEnd

################################################################
# FUNCTIONS
################################################################

Function .onInit

  ;Extract InstallOptions files
  ;$PLUGINSDIR will automatically be removed when the installer closes

  InitPluginsDir
  File /oname=$PLUGINSDIR\options.ini "options.ini"

!ifdef WIN64
# We are a 32-bit app, the real path for 64-bit apps is in ProgramW6432
  ReadEnvStr $INSTDIR ProgramW6432
  StrCpy $INSTDIR "$INSTDIR\pl"
!endif

FunctionEnd

################################################################
# Check 64-bit environment
# Note that NSIS is a 32-bit executable.  Such executables have
# set PROCESSOR_ARCHITEW6432 to IA64 or AMD64 on 64-bit platforms
################################################################

Function Check64
  ClearErrors
  ReadEnvStr ${ARCH} PROCESSOR_ARCHITEW6432
  IfErrors WrongArch
  StrCmpS ${ARCH} "AMD64" 0 WrongArch
    Return

WrongArch:
  MessageBox MB_OK \
	"Not an AMD64 version of Windows!$\r$\n\
	 This version of SWI-Prolog runs on 64-bits Windows$\r$\n\
	 using the AMD64/X64 architecture only"
  Quit
FunctionEnd

################################################################
# Handle customisation;  Settings are maintained in
#
#	HKLM ${REGKEY}
#
# Using the following mapping:
#
#	${EXT} fileExtension
################################################################

Function SetCustom
# Basic system info
  Call UserInfo

# Filename extension
  ReadRegStr ${EXT} HKLM ${REGKEY} fileExtension
  StrCmp ${EXT} "" 0 HasExt
    StrCpy ${EXT} "pl"
  HasExt:
  WriteINIStr $PLUGINSDIR\options.ini "Field 4" "State" ${EXT}

# Startmenu program group
  ReadRegStr ${GRP} HKLM ${REGKEY} group
  StrCmp ${GRP} "" 0 HasGroup
    StrCpy ${GRP} "SWI-Prolog"
  HasGroup:
  WriteINIStr $PLUGINSDIR\options.ini "Field 6" "State" ${GRP}

# Start the dialog
  Push ${TEMP1}
  InstallOptions::dialog "$PLUGINSDIR\options.ini"
  Pop ${TEMP1}
  Pop ${TEMP1}

# Get the results
  ReadINIStr ${EXT} $PLUGINSDIR\options.ini "Field 4" "State"
  ReadINIStr ${GRP} $PLUGINSDIR\options.ini "Field 6" "State"
FunctionEnd

Function UserInfo
  ClearErrors
  UserInfo::GetName
  IfErrors Win9x
  Pop $0
  UserInfo::GetAccountType
  Pop $1

  StrCmp $1 "Admin" 0 +4
    SetShellVarContext all
    StrCpy ${SHCTX} "all"
    Goto done
  StrCmp $1 "Power" 0 +3
    StrCpy ${SHCTX} "all"
    Goto done
  StrCmp $1 "User" 0 +3
    StrCpy ${SHCTX} "current"
    Goto done
  StrCmp $1 "Guest" 0 +3
    StrCpy ${SHCTX} "current"
    Goto done
  StrCpy ${SHCTX} "current"		# Unkown accounttype
    Goto done

  Win9x:
    StrCpy ${SHCTX}  "current"
    Goto end

  done:
    StrCmp ${SHCTX} "all" 0 +2
      SetShellVarContext all

  end:
FunctionEnd

Function .onInstSuccess
  MessageBox MB_YESNO "Installation complete. View readme?" /SD IDNO IDNO NoReadme
  ExecShell "open" "$INSTDIR\doc\windows.html"
  NoReadme:
FunctionEnd

Function .onInstFailed
  MessageBox MB_OK "Installation failed.$\r$\n\
		    If you cannot resolve the issue or it is a bug in the$\r$\n\
		    installer, please contact bugs@swi-prolog.org"
FunctionEnd
