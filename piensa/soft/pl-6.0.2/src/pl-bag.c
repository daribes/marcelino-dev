/*  $Id$

    Part of SWI-Prolog

    Author:        Jan Wielemaker
    E-mail:        wielemak@science.uva.nl
    WWW:           http://www.swi-prolog.org
    Copyright (C): 1985-2008, University of Amsterdam

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

/*#define O_DEBUG 1*/
#include "pl-incl.h"

#undef LD
#define LD LOCAL_LD


		 /*******************************
		 *      NEW IMPLEMENTATION	*
		 *******************************/

#define FINDALL_MAGIC	0x37ac78fe

typedef struct findall_bag
{ struct findall_bag *parent;		/* parent bag */
  long		magic;			/* FINDALL_MAGIC */
  segstack	answers;		/* list of ansers */
  size_t	solutions;		/* count # solutions */
  size_t	gsize;			/* required size on stack */
} findall_bag;


static int
get_bag(term_t t, findall_bag **bag ARG_LD)
{ findall_bag *b;

  if ( PL_get_pointer(t, (void**)&b) && b->magic == FINDALL_MAGIC )
  { *bag = b;
    return TRUE;
  } else
  { PL_error(NULL, 0, NULL, ERR_CHARS_TYPE, "pointer", t);
    return FALSE;
  }
}


static
PRED_IMPL("$new_findall_bag", 1, new_findall_bag, 0)
{ PRED_LD
  findall_bag *bag = allocHeap(sizeof(*bag));

  if ( !bag )
    return PL_no_memory();

  memset(bag, 0, sizeof(*bag));
  bag->magic = FINDALL_MAGIC;
  bag->answers.unit_size = sizeof(Record);
  PL_LOCK(L_AGC);
  bag->parent = LD->bags.bags;
  LD->bags.bags = bag;
  PL_UNLOCK(L_AGC);

  return PL_unify_pointer(A1, bag);
}


static
PRED_IMPL("$add_findall_bag", 2, add_findall_bag, 0)
{ PRED_LD
  findall_bag *bag;
  Record r;

  if ( !get_bag(A1, &bag PASS_LD) )
    return FALSE;

  r = compileTermToHeap(A2, R_NOLOCK);
  if ( !pushRecordSegStack(&bag->answers, r) )
  { freeRecord(r);
    return PL_no_memory();
  }
  bag->gsize += r->gsize;
  bag->solutions++;

  if ( bag->gsize + bag->solutions*3 > limitStack(global)/sizeof(word) )
    return outOfStack(&LD->stacks.global, STACK_OVERFLOW_RAISE);

  PL_LOCK(L_AGC);			/* see queue_message() in */
  PL_UNLOCK(L_AGC);			/* pl-thread.c for the motivation */

  return FALSE;				/* force backtracking of generator */
}


static inline void
freeBag(findall_bag *bag)
{ bag->magic = 0;
  clearSegStack(&bag->answers);
  freeHeap(bag, sizeof(*bag));
}


static
PRED_IMPL("$collect_findall_bag", 3, collect_findall_bag, 0)
{ PRED_LD
  findall_bag *bag;
  Record *rp;
  term_t list = PL_copy_term_ref(A3);
  term_t answer = PL_new_term_ref();
  size_t space;
  int rc;

  if ( !get_bag(A1, &bag PASS_LD) )
    return FALSE;
  space = bag->gsize + bag->solutions*3;

  if ( !hasGlobalSpace(space) )
  { if ( (rc=ensureGlobalSpace(space, ALLOW_GC)) != TRUE )
      return raiseStackOverflow(rc);
  }

  while ( (rp=topOfSegStack(&bag->answers)) )
  { Record r = *rp;
    copyRecordToGlobal(answer, r, ALLOW_GC PASS_LD);
    PL_cons_list(list, answer, list);
    PL_LOCK(L_AGC);			/* needed for markAtomsAnswers() */
    popTopOfSegStack(&bag->answers);
    PL_UNLOCK(L_AGC);

    freeRecord(r);
  }
  DEBUG(CHK_SECURE, assert(emptySegStack(&bag->answers)));

  return PL_unify(A2, list);
}


static
PRED_IMPL("$destroy_findall_bag", 1, destroy_findall_bag, 0)
{ PRED_LD
  findall_bag *bag;

  if ( PL_get_pointer(A1, (void**)&bag) && bag->magic == FINDALL_MAGIC )
  { Record *rp;

    while ( (rp=topOfSegStack(&bag->answers)) )
    { Record r = *rp;

      PL_LOCK(L_AGC);
      popTopOfSegStack(&bag->answers);
      PL_UNLOCK(L_AGC);

      freeRecord(r);
    }

    assert(LD->bags.bags == bag);
    PL_LOCK(L_AGC);
    LD->bags.bags = bag->parent;
    PL_UNLOCK(L_AGC);

    freeBag(bag);
    succeed;
  }

  assert(0);
  fail;
}


		 /*******************************
		 *	  ATOM-GC SUPPORT	*
		 *******************************/

static void
markAtomsAnswers(void *data)
{ Record r = *((Record*)data);

  markAtomsRecord(r);
}


void
markAtomsFindall(PL_local_data_t *ld)
{ findall_bag *bag = ld->bags.bags;

  for( ; bag; bag = bag->parent )
    scanSegStack(&bag->answers, markAtomsAnswers);
}


		 /*******************************
		 *      PUBLISH PREDICATES	*
		 *******************************/

BeginPredDefs(bag)
  PRED_DEF("$new_findall_bag", 1, new_findall_bag, 0)
  PRED_DEF("$add_findall_bag", 2, add_findall_bag, 0)
  PRED_DEF("$collect_findall_bag", 3, collect_findall_bag, 0)
  PRED_DEF("$destroy_findall_bag", 1, destroy_findall_bag, 0)
EndPredDefs
