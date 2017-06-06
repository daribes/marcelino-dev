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

#ifndef _Canvas_h
#define _Canvas_h

/****************************************************************
 *
 * Canvas widget
 *
 ****************************************************************/

/* Resources:

 Name		     Class		RepType		Default Value
 ----		     -----		-------		-------------
 eventCallback	     Callback	        Callback	NULL
 exposeCallback	     Callback		Callback	NULL
*/

/* define any special resource names here that are not in <X11/StringDefs.h> */

#define XtNeventCallback	"eventCallback"
#define XtNexposeCallback	"exposeCallback"
#define XtNresizeCallback	"resizeCallback"

/* declare specific CanvasWidget class and instance datatypes */

typedef struct _CanvasClassRec*	CanvasWidgetClass;
typedef struct _CanvasRec*	CanvasWidget;

/* declare the class constant */

extern WidgetClass canvasWidgetClass;

#endif /* _Canvas_h */
