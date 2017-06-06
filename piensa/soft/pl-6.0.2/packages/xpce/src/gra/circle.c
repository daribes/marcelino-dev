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

#include <h/kernel.h>
#include <h/graphics.h>

static status
initialiseCircle(Circle c, Int w)
{ initialiseGraphical(c, ZERO, ZERO, w, w);
  assign(c, fill_pattern, NIL);

  succeed;
}


static status
RedrawAreaCircle(Circle c, Area a)
{ int x, y, w, h;

  initialiseDeviceGraphical(c, &x, &y, &w, &h);
  NormaliseArea(x, y, w, h);
  r_thickness(valInt(c->pen));
  r_dash(c->texture);
  r_ellipse(x, y, w, h, c->fill_pattern);

  return RedrawAreaGraphical(c, a);
}


static status
radiusCircle(Circle c, Int r)
{ Int d = mul(r, TWO);

  return setGraphical(c, DEFAULT, DEFAULT, d, d);
}


static Int
getRadiusCircle(Circle c)
{ answer(div(c->area->w,TWO));
}


static status
rotateCircle(Circle c)
{ succeed;
}


static status
diameterCircle(Circle c, Int n)
{ return setGraphical(c, DEFAULT, DEFAULT, n, n);
}


static Int
getDiameterCircle(Circle c)
{ answer(c->area->w);
}


static status
geometryCircle(Circle c, Int x, Int y, Int w, Int h)
{ Int d;

  if ( isDefault(w) )
    d = (isDefault(h) ? (Int) DEFAULT : h);
  else
    d = (isDefault(h) ? w : valInt(w) < valInt(h) ? w : h);

  return geometryGraphical(c, x, y, d, d);
}


		 /*******************************
		 *	 CLASS DECLARATION	*
		 *******************************/

/* Type declarations */

static char *T_geometry[] =
        { "x=[int]", "y=[int]", "width=[int]", "height=[int]" };

/* Instance Variables */

static vardecl var_circle[] =
{ SV(NAME_fillPattern, "image|colour*", IV_GET|IV_STORE, fillPatternGraphical,
     NAME_appearance, "Fill pattern for internals")
};

/* Send Methods */

static senddecl send_circle[] =
{ SM(NAME_initialise, 1, "diameter=[int]", initialiseCircle,
     DEFAULT, "Create circle from diameter"),
  SM(NAME_diameter, 1, "int", diameterCircle,
     NAME_area, "Set diameter"),
  SM(NAME_geometry, 4, T_geometry, geometryCircle,
     NAME_area, "Force width and height to be equal"),
  SM(NAME_radius, 1, "int", radiusCircle,
     NAME_area, "Set radius (= half diameter)"),
  SM(NAME_DrawPostScript, 1, "{head,body}", drawPostScriptCircle,
     NAME_postscript, "Create PostScript"),
  SM(NAME_rotate, 1, "int", rotateCircle,
     NAME_rotate, "Rotate (does nothing)")
};

/* Get Methods */

static getdecl get_circle[] =
{ GM(NAME_diameter, 0, "int", NULL, getDiameterCircle,
     NAME_area, "Diameter (= twice radius)"),
  GM(NAME_radius, 0, "int", NULL, getRadiusCircle,
     NAME_area, "Radius (= half diameter")
};

/* Resources */

static classvardecl rc_circle[] =
{ RC(NAME_selectionHandles, "name", "sides",
     "Visual feedback of <->selected")
};

/* Class Declaration */

static Name circle_termnames[] = { NAME_diameter };

ClassDecl(circle_decls,
          var_circle, send_circle, get_circle, rc_circle,
          1, circle_termnames,
          "$Rev$");


status
makeClassCircle(Class class)
{ declareClass(class, &circle_decls);

  cloneStyleVariableClass(class, NAME_fillPattern, NAME_reference);
  setRedrawFunctionClass(class, RedrawAreaCircle);

  succeed;
}

