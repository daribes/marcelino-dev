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
#include <h/dialog.h>

Class ClassIntItem;

typedef struct int_item *IntItem;

NewClass(int_item)
    ABSTRACT_TEXTITEM
End;

static status rangeIntItem(IntItem ii, Int low, Int high);

static status
initialiseIntItem(IntItem ii, Name name, Int selection, Code msg,
		  Int low, Int high)
{ Int v0;

  if ( isDefault(name) )
    name = NAME_integer;
  v0 = isDefault(selection) ? ZERO : selection;

  initialiseTextItem((TextItem)ii, name, v0, msg);
  styleTextItem((TextItem)ii, NAME_stepper);

  rangeIntItem(ii, low, high);

  if ( isDefault(selection) )
    send(ii, NAME_clear, EAV);

  succeed;
}


static int
width_text(FontObj f, const char *s)
{ CharArray ctmp = CtoScratchCharArray(s);
  Int w = getWidthFont(f, ctmp);

  doneScratchCharArray(ctmp);

  return(valInt(w));
}


static status
rangeIntItem(IntItem ii, Int low, Int high)
{ char buf[48];
  Type t = NULL;
  char s1[24], s2[24];
  int b = valInt(getClassVariableValueObject(ii, NAME_border));

  obtainClassVariablesObject(ii);

  if ( isDefault(low) )
  { if ( isDefault(high) )
    { t = TypeInt;
      sprintf(s1, INTPTR_FORMAT, PCE_MIN_INT);
      sprintf(s2, INTPTR_FORMAT, PCE_MAX_INT);
    } else
    { sprintf(s1, INTPTR_FORMAT, PCE_MIN_INT);
      sprintf(s2, INTPTR_FORMAT, valInt(high));
      sprintf(buf, ".." INTPTR_FORMAT, valInt(high));
    }
  } else
  { if ( isDefault(high) )
    { sprintf(s1, INTPTR_FORMAT, valInt(low));
      sprintf(s2, INTPTR_FORMAT, PCE_MAX_INT);
      sprintf(buf, INTPTR_FORMAT "..", valInt(low));
    } else
    { sprintf(s1, INTPTR_FORMAT, valInt(low));
      sprintf(s2, INTPTR_FORMAT, valInt(high));
      sprintf(buf, INTPTR_FORMAT ".." INTPTR_FORMAT,
	      valInt(low), valInt(high));
    }
  }

  if ( !t )
    t = checkType(CtoName(buf), TypeType, NIL);

  assign(ii, type, t);
  assign(ii, hor_stretch, ZERO);
  valueWidthTextItem((TextItem)ii,
		     toInt(max(width_text(ii->value_font, s1),
			       width_text(ii->value_font, s2))
			   + 2*b + 5 +
			   + text_item_combo_width((TextItem)ii)));

  succeed;
}


static Int
getLowIntItem(IntItem ii)
{ Type t = ii->type;

  if ( t->kind == NAME_intRange )
  { Tuple tup = t->context;
    if ( isInteger(tup->first) )
      answer(tup->first);
  }

  answer(toInt(PCE_MIN_INT));
}


static Int
getHighIntItem(IntItem ii)
{ Type t = ii->type;

  if ( t->kind == NAME_intRange )
  { Tuple tup = t->context;
    if ( isInteger(tup->second) )
      answer(tup->second);
  }

  answer(toInt(PCE_MAX_INT));
}



		 /*******************************
		 *	   EVENT HANDLING	*
		 *******************************/

static status
typedIntItem(IntItem ii, EventId id)
{ CharArray save = getCopyCharArray(ii->value_text->string);
  status rval = typedTextItem((TextItem)ii, id);

  if ( rval &&
       !checkType(ii->value_text->string, TypeInt, NIL) &&
       getSizeCharArray(ii->value_text->string) != ZERO )
  { displayedValueTextItem((TextItem)ii, save);
    return errorPce(ii, NAME_cannotConvertText,
		    ii->value_text->string, ii->type);
  }

  doneObject(save);
  return rval;
}


static status
addIntItem(IntItem ii, Int change)
{ Int ival;
  long val;
  char buf[100];
  CharArray ctmp;
  Int low, high;

  if ( (ival = toInteger(ii->value_text->string)) )
    val = valInt(ival);
  else
    val = 0;
  val += valInt(change);
  if ( (low=getLowIntItem(ii)) )
    val = max(val, valInt(low));
  if ( (high = getHighIntItem(ii)) )
    val = min(val, valInt(high));
  sprintf(buf, "%ld", val);
  ctmp = CtoScratchCharArray(buf);
  displayedValueTextItem((TextItem)ii, ctmp);
  doneScratchCharArray(ctmp);

  applyTextItem((TextItem)ii, OFF);

  succeed;
}


static status
incrementIntItem(IntItem ii)
{ return addIntItem(ii, ONE);
}


static status
decrementIntItem(IntItem ii)
{ return addIntItem(ii, toInt(-1));
}


static status
typeIntItem(IntItem ii, Type type)
{ assign(ii, type, type);

  while(type->kind == NAME_alias)
    type = type->context;

  if ( type->kind == NAME_intRange )
  { Tuple t = type->context;
    rangeIntItem(ii, t->first, t->second);
  } else if ( type->kind == NAME_int )
    rangeIntItem(ii, DEFAULT, DEFAULT);

  succeed;
}


		 /*******************************
		 *	 CLASS DECLARATION	*
		 *******************************/

/* Type declarations */

static char *T_initialise[] =
        { "name=[name]", "default=[function|int]", "message=[code]*",
	  "low=[int]", "high=[int]" };
static char *T_range[] =
	{ "low=[int]", "high=[int]" };

/* Instance Variables */

#define var_int_item NULL
/*
static vardecl var_int_item[] =
{
};
*/

/* Send Methods */

static senddecl send_int_item[] =
{ SM(NAME_initialise, 5, T_initialise, initialiseIntItem,
     DEFAULT, "Create from name, selection and font"),
  SM(NAME_range, 2, T_range, rangeIntItem,
     NAME_type, "Allowed range"),
  SM(NAME_typed, 1, "event_id", typedIntItem,
     NAME_event, "Process keyboard event"),
  SM(NAME_increment, 0, NULL, incrementIntItem,
     NAME_selection, "Increment the selection"),
  SM(NAME_decrement, 0, NULL, decrementIntItem,
     NAME_selection, "Decrement the selection"),
  SM(NAME_type, 1, "type", typeIntItem,
     NAME_type, "Adjust ->low and ->high")
};

/* Get Methods */

#define get_int_item NULL
/*
static getdecl get_int_item[] =
{
};
*/

/* Resources */

#define rc_int_item NULL
/*
static classvardecl rc_int_item[] =
{
};
*/

/* Class Declaration */

static Name int_item_termnames[] = { NAME_name, NAME_default, NAME_message };

ClassDecl(int_item_decls,
          var_int_item, send_int_item, get_int_item, rc_int_item,
          3, int_item_termnames,
          "$Rev$");

status
makeClassIntItem(Class class)
{ return declareClass(class, &int_item_decls);
}

