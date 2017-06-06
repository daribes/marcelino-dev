/*  $Id$

    Part of SWI-Prolog

    Author:        Jan Wielemaker
    E-mail:        J.Wielemaker@uva.nl
    WWW:           http://www.swi-prolog.org
    Copyright (C): 1985-2007, University of Amsterdam

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

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Segmented stack handling. A segmented stack is a stack that is allocated
in segments, This means we cannot   compare  addresses otherwise then by
identity.  We use a segmented stack for cycle detection.

Measurements with the chunksize on SuSE Linux  10.2 indicate there is no
measurable performance change above approximately  256 bytes. We'll keep
the figure on the safe  side  for   systems  with  less efficient malloc
implementations.

Note  that  atom-gc  requires   completely    asynchronous   calling  of
scanSegStack() and therefore pushSegStack()/popSegStack()  must push the
data before updating the pointers.

TBD: Avoid instruction/cache write reordering in push/pop.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

void
initSegStack(segstack *stack, size_t unit_size, size_t len, void *data)
{ stack->unit_size = unit_size;

  if ( len )
  { segchunk *chunk = data;

    DEBUG(CHK_SECURE, assert(len > sizeof(*chunk)));
    chunk->size = len;
    stack->base = stack->top = chunk->top = chunk->data;
    stack->last = stack->first = chunk;
    stack->max  = addPointer(chunk, len);
    memset(&chunk->allocated, 0,
	   offsetof(segchunk,data)-offsetof(segchunk,allocated));
  } else
  { memset(&stack->first, 0, sizeof(*stack)-offsetof(segstack,first));
  }
}


int
pushSegStack_(segstack *stack, void *data)
{ if ( stack->top + stack->unit_size <= stack->max )
  { memcpy(stack->top, data, stack->unit_size);
    stack->top += stack->unit_size;

    return TRUE;
  } else
  { segchunk *chunk = PL_malloc(SEGSTACK_CHUNKSIZE);

    if ( !chunk )
      return FALSE;			/* out of memory */

    chunk->allocated = TRUE;
    chunk->size = SEGSTACK_CHUNKSIZE;
    chunk->next = NULL;
    chunk->previous = stack->last;
    chunk->top = chunk->data;		/* async scanning */
    if ( stack->last )
    { stack->last->next = chunk;
      stack->last->top = stack->top;
      stack->top = chunk->top;		/* async scanning */
      stack->last = chunk;
    } else
    { stack->top = chunk->top;		/* async scanning */
      stack->last = stack->first = chunk;
    }

    stack->base = chunk->data;
    stack->max  = addPointer(chunk, chunk->size);
    memcpy(chunk->data, data, stack->unit_size);
    stack->top  = chunk->data + stack->unit_size;

    return TRUE;
  }
}


int
pushRecordSegStack(segstack *stack, Record r)
{ if ( stack->top + sizeof(r) <= stack->max )
  { Record *rp = (Record*)stack->top;

    *rp++ = r;
    stack->top = (char*)rp;

    return TRUE;
  } else
  { int rc;

    PL_LOCK(L_AGC);
    rc = pushSegStack_(stack, &r);
    PL_UNLOCK(L_AGC);

    return rc;
  }
}


/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Pop data. Note that we leave the first chunk associated with the stack
to speedup frequent small usage.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

int
popSegStack_(segstack *stack, void *data)
{ again:

  if ( stack->top >= stack->base + stack->unit_size )
  { stack->top -= stack->unit_size;
    memcpy(data, stack->top, stack->unit_size);

    return TRUE;
  } else
  { segchunk *chunk = stack->last;

    if ( chunk )
    { if ( chunk->previous )
      { stack->last = chunk->previous;
	stack->last->next = NULL;
	if ( chunk->allocated )
	  PL_free(chunk);

	chunk = stack->last;
	stack->base = chunk->data;
	stack->max  = addPointer(chunk, chunk->size);
	stack->top  = chunk->top;
	goto again;
      }
    }

    return FALSE;
  }
}


void *
topOfSegStack(segstack *stack)
{ segchunk *chunk;

  if ( stack->top >= stack->base + stack->unit_size )
  { return stack->top - stack->unit_size;
  } else if ( stack->last && (chunk=stack->last->previous) )
  { assert(chunk->top - stack->unit_size >= chunk->data);
    return chunk->top - stack->unit_size;
  }

  return NULL;
}


void
popTopOfSegStack(segstack *stack)
{ again:

  if ( stack->top >= stack->base + stack->unit_size )
  { stack->top -= stack->unit_size;
  } else
  { segchunk *chunk = stack->last;

    if ( chunk )
    { if ( chunk->previous )
      { stack->last = chunk->previous;
	stack->last->next = NULL;
	if ( chunk->allocated )
	  PL_free(chunk);

	chunk = stack->last;
	stack->base = chunk->data;
	stack->max  = addPointer(chunk, chunk->size);
	stack->top  = chunk->top;
	goto again;
      }
    }

    assert(0);
  }
}


/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
scanSegStack(segstack *stack, void (*func)(void *cell))
Walk along all living cells on the stack and call func on them.  The stack
is traversed last-to-first.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

static inline void
scan_chunk(segstack *stack, char *top, char *base, void (*func)(void *cell))
{ while(top >= base+stack->unit_size)
  { top -= stack->unit_size;
    (*func)((void*)top);
  }
}


void
scanSegStack(segstack *stack, void (*func)(void *cell))
{ segchunk *chunk;

  if ( (chunk=stack->last) )		/* something there */
  { chunk->top = stack->top;		/* close last chunk */
    for(; chunk; chunk=chunk->previous)
      scan_chunk(stack, chunk->top, chunk->data, func);
  }
}


void
clearSegStack(segstack *s)
{ segchunk *c;

  if ( (c = s->first) )
  { segchunk *n;

    if ( !c->allocated )		/* statically allocated first chunk */
    { n = c->next;

      c->next = NULL;
      s->last = c;
      s->base = s->top = c->top;
      s->max  = addPointer(c, c->size);

      for(c=n; c; c = n)
      { n = c->next;
	PL_free(c);
      }
    } else				/* all dynamic chunks */
    { for(; c; c = n)
      { n = c->next;
	PL_free(c);
      }
      memset(s, 0, sizeof(*s));
    }
  }
}
