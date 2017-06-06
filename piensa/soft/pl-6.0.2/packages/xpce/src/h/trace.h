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

#ifndef PCE_TRACE_H
#define PCE_TRACE_H

GLOBAL PceGoal	CurrentGoal;		/* current active goal */
GLOBAL int	ServiceMode;		/* Running a service  call-back */
GLOBAL int	MaxGoalDepth;		/* maximum recursion level */

#define NO_MAX_GOAL_DEPTH INT_MAX 	/* Setting for MaxGoalDepth if unlimited */

#define DebuggingProgramObject(o, flags) \
	(PCEdebugging && (ServiceMode == PCE_EXEC_USER) && onDFlag((o), (flags)))

#define ServiceMode(mode, code) \
  { int _smode = ServiceMode; \
    ServiceMode = mode; \
    { code; } \
    ServiceMode = _smode; \
  }

COMMON(void)	writeGoal(PceGoal g);
COMMON(int)	isProperGoal(PceGoal g);
COMMON(void)	pceBackTrace(PceGoal g, int depth);

#endif /*PCE_TRACE_H*/
