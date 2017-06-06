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

#include "include.h"

		 /*******************************
		 *	     DEBUGGING		*
		 *******************************/

HashTable
MsObjectTable()
{ static HashTable table;

  if ( !table )
    table = globalObject(CtoName("ms_objects"), ClassHashTable, EAV);

  return table;
}


		 /*******************************
		 *	INPUT (MODAL LOOP)	*
		 *******************************/

void
ws_discard_input(const char *msg)
{
/*
  char buf[1024];

  Cprintf("%s; discarding input ...", msg);
  Cgetline(buf, sizeof(buf));
  Cprintf("ok\n");
*/
}

		 /*******************************
		 *	FIND XPCE WINDOW	*
		 *******************************/

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
These functions are used to associate an  XPCE object with an MS-windows
window. In older versions,  we  used   data  associated  with the window
itself. As of 4.10.1, XPCE objects can  be bound to existing MS-Windows,
and we want to make as  few   as  possible assumptions on these windows.
Hence, we use our own hashtable.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#define WINASSOC_TABLESIZE 256

typedef struct _winassoc
{ HWND			hwnd;		/* MS-Windows window handle */
  Any			object;		/* Associated object */
  struct _winassoc     *next;		/* Next in chain */
} winassoc, *WinAssoc;

static WinAssoc wintable[WINASSOC_TABLESIZE];

static int
handleKey(HWND handle)
{ const char *p = (const char *)&handle;
  int i;
  int key = 0;

  for(i=0; i<sizeof(handle); i++)
    key ^= *p++;

  return key & (WINASSOC_TABLESIZE-1);
}

void
assocObjectToHWND(HWND hwnd, Any obj)
{ int key = handleKey(hwnd);
  WinAssoc *p = &wintable[key];
  WinAssoc  a = *p;

  if ( isNil(obj) )			/* delete from table */
  { for( ; a ; p = &a->next, a = a->next )
    { if ( a->hwnd == hwnd )
      { *p = a->next;
        unalloc(sizeof(winassoc), a);
	return;
      }
    }
					/* not in the table!? */
  } else
  { WinAssoc n = alloc(sizeof(winassoc));
    n->next   = *p;
    n->hwnd   = hwnd;
    n->object = obj;
    *p = n;
  }

  DEBUG(NAME_window, Cprintf("Binding 0x%04x --> %s\n", hwnd, pp(obj)));
}

Any
getObjectFromHWND(HWND hwnd)
{ int key = handleKey(hwnd);
  WinAssoc a = wintable[key];

  for( ; a; a=a->next )
  { if ( a->hwnd == hwnd )
      return a->object;
  }

  fail;
}

		 /*******************************
		 *	   THREAD STUFF		*
		 *******************************/

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
destroyThreadWindows(Class class)
    Destroy all objects that are in the HWND table and have a window
    that belongs to the current thread.  Note that here we decide to
    *destroy* such objects.  We could also have choosen for `uncreate',
    leaving the object around but destroying the Windows.

    This routine is called from DllMain() in mswin.c
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

void
destroyThreadWindows(Class class)
{ Chain ch = newObject(ClassChain, EAV);
  int i;
  DWORD tid = GetCurrentThreadId();
  Any obj;

  for(i=0; i<WINASSOC_TABLESIZE; i++)
  { WinAssoc a;

    for(a = wintable[i]; a; a = a->next)
    { if ( instanceOfObject(a->object, class) &&
	   tid == GetWindowThreadProcessId(a->hwnd, NULL) )
	appendChain(ch, a->object);
    }
  }

  for_chain(ch, obj,
	    { DEBUG(NAME_thread, Cprintf("Destroying %s owned by 0x%x\n",
					 pp(obj), tid));
	      sendv(obj, NAME_destroy, 0, NULL);
	    });

  freeObject(ch);
}


		 /*******************************
		 *	       FRAME		*
		 *******************************/

HWND
getHwndFrame(FrameObj fr)
{ WsFrame f;

  if ( (f = fr->ws_ref) )
  { DEBUG(NAME_window, Cprintf("HWND of %s --> 0x%04x\n",
			       pp(fr), f->hwnd));
    return f->hwnd;
  }

  return 0;
}


void
setHwndFrame(FrameObj fr, HWND ref)
{ WsFrame f;

  if ( ref )
  { if ( !(f=fr->ws_ref) )
    { fr->ws_ref = alloc(sizeof(ws_frame));
      f = fr->ws_ref;
    }

    memset(f, 0, sizeof(*f));
    f->hwnd         = ref;
  } else
  { if ( fr->ws_ref )
    { unalloc(sizeof(ws_frame), fr->ws_ref);
      fr->ws_ref = NULL;
    }
  }
}


HWND
getHwndWindow(PceWindow sw)
{ WsWindow w;

  if ( (w = sw->ws_ref) )
  { /*DEBUG(NAME_window, Cprintf("HWND of %s --> 0x%04x\n",
			      pp(sw), w->hwnd));*/
    return w->hwnd;
  }

  return 0;
}


void
setHwndWindow(PceWindow sw, HWND ref)
{ WsWindow w;

  if ( ref )
  { if ( !(w=sw->ws_ref) )
    { sw->ws_ref = alloc(sizeof(ws_window));
      w = sw->ws_ref;
    }

    w->hwnd		      = ref;
    w->saved_window_procedure = NULL;
    w->hcursor		      = 0;
    w->capture		      = 0;
  } else
  { if ( sw->ws_ref )
    { unalloc(sizeof(ws_window), sw->ws_ref);
      sw->ws_ref = NULL;
    }
  }
}


		 /*******************************
		 *	  EVENT HANDLING	*
		 *******************************/

static int	emulate_three_buttons;
static HWND	emu_hwnd;		/* Emulating for this window */

int
ws_emulate_three_buttons(int time)
{ int old = emulate_three_buttons;

  if ( time >= 0 )
    emulate_three_buttons = time;

  return old;
}


static int
IsDownKey(code)
{ short mask = GetKeyState(code);

  DEBUG(NAME_key, Cprintf("IsDownKey(%d): mask = 0x%x\n", code, mask));

  return mask & 0x8000;
}


Any
messageToKeyId(UINT message, UINT wParam, LONG lParam, unsigned long *bmask)
{ Any id = FAIL;
  unsigned long state = 0L;

  if ( IsDownKey(VK_CONTROL) )
    state |= BUTTON_control;
  if ( IsDownKey(VK_SHIFT) )
    state |= BUTTON_shift;
  if ( IsDownKey(VK_MENU) )
    state |= BUTTON_meta;

  switch(message)
  { case WM_KEYDOWN:
    { switch((int) wParam)
      { case VK_DELETE:		id = toInt(127);	break;
        case VK_LEFT:		id = NAME_cursorLeft;	break;
        case VK_RIGHT:		id = NAME_cursorRight;	break;
        case VK_UP:		id = NAME_cursorUp;	break;
        case VK_DOWN:		id = NAME_cursorDown;	break;
        case VK_HOME:		id = NAME_cursorHome;	break;
	case VK_PRIOR:		id = NAME_pageUp;	break;
	case VK_NEXT:		id = NAME_pageDown;	break;
	case VK_END:		id = NAME_end;		break;
	case VK_PAUSE:		id = NAME_pause;	break;

	case VK_SELECT:		id = NAME_select;	break;
	case VK_PRINT:		id = NAME_print;	break;
	case VK_EXECUTE:	id = NAME_execute;	break;
	case VK_INSERT:		id = NAME_insert;	break;
	case VK_HELP:		id = NAME_help;		break;
	case VK_APPS:		id = NAME_menu;		break; /* ??? */

        case VK_F1:		id = NAME_keyTop_1;	break;
        case VK_F2:		id = NAME_keyTop_2;	break;
        case VK_F3:		id = NAME_keyTop_3;	break;
        case VK_F4:		id = NAME_keyTop_4;	break;
        case VK_F5:		id = NAME_keyTop_5;	break;
        case VK_F6:		id = NAME_keyTop_6;	break;
        case VK_F7:		id = NAME_keyTop_7;	break;
        case VK_F8:		id = NAME_keyTop_8;	break;
        case VK_F9:		id = NAME_keyTop_9;	break;
        case VK_F10:		id = NAME_keyTop_10;	break;
        case '2':			/* ^@ */
	  if ( state & BUTTON_control )
	    id = ZERO;
	  break;
	case 0xbd:			/* OEM specific Control('_') ??? */
	  if ( (state & BUTTON_control) && !(state & BUTTON_shift) )
	    id = toInt(Control('_'));
	  break;
	case 0x56:			/* OEM specific 'V' ??? */
	  if ( (state & BUTTON_control) && (state & BUTTON_meta) )
	    id = toInt(Control('V') + META_OFFSET);
	  break;
	case 0x49:			/* OEM specific 'I' ??? */
	  if ( (state & BUTTON_control) && (state & BUTTON_meta) )
	    id = toInt(Control('I') + META_OFFSET);
	  break;
      }

      break;
    }
    case WM_SYSCHAR:			/* handle ALT keys myself */
      id = toInt(wParam + META_OFFSET);
      state |= BUTTON_meta;
      break;

    case WM_CHAR:
    { id = toInt(wParam);

      if ( wParam == ' ' &&  (state & BUTTON_control) )
        id = ZERO;			/* ^-space --> ^@ */
      else if ( wParam == 8 && !(state & BUTTON_control) )
	id = NAME_backspace;

      break;
    }

#ifdef WM_MOUSEWHEEL
    case WM_MOUSEWHEEL:
    { id = NAME_wheel;

      break;
    }
#endif
  }

  if ( id && bmask )
    *bmask = state;

  return id;
}


EventObj
messageToEvent(HWND hwnd, UINT message, UINT wParam, LONG lParam)
{ Any id = NIL;
  Int x = DEFAULT, y = DEFAULT;
  Int buttons = DEFAULT;
  Any window = getObjectFromHWND(hwnd);
  int mouse_ev = FALSE;
  int double_click = FALSE;
  Name ctx_name = NULL;
  Any ctx = NULL;

  DEBUG(NAME_event,
	Cprintf("messageToEvent(%s(0x%04x), 0x%04x, 0x%04x, 0x%08lx)\n",
		pp(window), hwnd, message, wParam, lParam));

  switch(message)
  { case WM_KEYDOWN:			/* Named keys */
    case WM_SYSCHAR:			/* ALT-commands */
    case WM_CHAR:			/* Printable keys */
    { unsigned long state = 0L;

      if ( (id = messageToKeyId(message, wParam, lParam, &state)) )
	buttons = toInt(state);
      else
	id = NIL;

      break;
    }
					/* BEGIN MOUSE STUFF */
    case WM_LBUTTONUP:
      if ( emu_hwnd == hwnd )
      { if ( (wParam & MK_RBUTTON) )
	{ id = NAME_msMiddleUp;
	  mouse_ev++;
	} else
	{ emu_hwnd = 0;
	}
      } else
      { id = NAME_msLeftUp;
	mouse_ev++;
	emu_hwnd = 0;
      }

      break;
    case WM_LBUTTONDBLCLK:
      double_click = TRUE;
    case WM_LBUTTONDOWN:
      id = NAME_msLeftDown;

      if ( emulate_three_buttons )
      { MSG msg;

	Sleep(emulate_three_buttons);
        if ( PeekMessage(&msg, hwnd,
			 WM_RBUTTONDOWN, WM_RBUTTONDOWN, PM_REMOVE) )
	{ id = NAME_msMiddleDown;
	  emu_hwnd = hwnd;
	}
      }

      mouse_ev++;
      break;
    case WM_MBUTTONUP:
      id = NAME_msMiddleUp;
      mouse_ev++;
      break;
    case WM_MBUTTONDBLCLK:
      double_click = TRUE;
    case WM_MBUTTONDOWN:
      id = NAME_msMiddleDown;
      mouse_ev++;
      break;
    case WM_RBUTTONUP:
      if ( emu_hwnd == hwnd )
      { if ( (wParam & MK_LBUTTON) )
	{ id = NAME_msMiddleUp;
	  mouse_ev++;
	} else
	{ emu_hwnd = 0;
	}
      } else
      { id = NAME_msRightUp;
	mouse_ev++;
	emu_hwnd = 0;
      }

      break;
    case WM_RBUTTONDBLCLK:
      double_click = TRUE;
    case WM_RBUTTONDOWN:
      id = NAME_msRightDown;

      if ( emulate_three_buttons )
      { MSG msg;

	Sleep(emulate_three_buttons);
        if ( PeekMessage(&msg, hwnd,
			 WM_LBUTTONDOWN, WM_LBUTTONDOWN, PM_REMOVE) )
	{ id = NAME_msMiddleDown;
	  emu_hwnd = hwnd;
	}
      }

      mouse_ev++;
      break;
    case WM_MOUSEMOVE:
    { if ( emu_hwnd == hwnd )
      { id = NAME_msMiddleDrag;
      } else
      { if ( wParam & MK_LBUTTON )
	  id = NAME_msLeftDrag;
	else if ( wParam & MK_MBUTTON )
	  id = NAME_msMiddleDrag;
	else if ( wParam & MK_RBUTTON )
	  id = NAME_msRightDrag;
	else
	  id = NAME_locMove;
      }

      mouse_ev++;
      break;
    }
#ifdef WM_MOUSEWHEEL			/* appears to be sent to frame! */
    case WM_MOUSEWHEEL:
    { id = NAME_wheel;
      ctx_name = NAME_rotation;
      ctx = toInt(HIWORD(wParam));

      mouse_ev++;
      break;
    }
#endif
					/* END MOUSE STUFF */
    case WM_WINENTER:
      id = NAME_areaEnter;
      mouse_ev++;
      break;

    case WM_WINEXIT:
#ifdef WM_MOUSELEAVE			/* Windows NT 4.0 they say! */
    case WM_MOUSELEAVE:
#endif
      id = NAME_areaExit;
      mouse_ev++;
      break;
  }

  if ( mouse_ev )
  { POINTS pt = MAKEPOINTS(lParam);
    int state = 0;
    static PceWindow lastwin;
    static int lastx;
    static int lasty;

    x = toInt(pt.x);
    y = toInt(pt.y);

				/* Some versions of windows sometimes */
				/* give fake move-events.  We suppress these */
    if ( id == NAME_locMove )
    { if ( pt.x == lastx && pt.y == lasty && window == lastwin )
	fail;
      else
      { lastx = pt.x;
	lasty = pt.y;
	lastwin = window;
      }
    }

    if ( wParam & MK_CONTROL )
      state |= BUTTON_control;
    if ( wParam & MK_SHIFT )
      state |= BUTTON_shift;
    if ( wParam & MK_LBUTTON )
      state |= BUTTON_ms_left;
    if ( wParam & MK_MBUTTON )
      state |= BUTTON_ms_middle;
    if ( wParam & MK_RBUTTON )
      state |= BUTTON_ms_right;

    if ( double_click )
      state |= CLICK_TYPE_double;

    buttons = toInt(state);
  }

  if ( notNil(id) )
  { EventObj ev;
    setLastEventTime((unsigned long) GetTickCount());

    DEBUG(NAME_event, Cprintf("\t--> %s at %s,%s on %s\n",
			      pp(id), pp(x), pp(y), pp(window)));

    ev = answerObject(ClassEvent,
		      id,
		      window,
		      x, y,
		      buttons,
		      EAV);

    if ( ctx_name )
      attributeObject(ev, ctx_name, ctx);

    return ev;
  } else
    fail;
}
