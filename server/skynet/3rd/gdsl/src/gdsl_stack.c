/*
 * This file is part of the Generic Data Structures Library (GDSL).
 * Copyright (C) 1998-2006 Nicolas Darnis <ndarnis@free.fr>.
 *
 * The GDSL library is free software; you can redistribute it and/or 
 * modify it under the terms of the GNU General Public License as 
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * The GDSL library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the GDSL library; see the file COPYING.
 * If not, write to the Free Software Foundation, Inc., 
 * 59 Temple Place, Suite 330, Boston, MA  02111-1307, USA.
 *
 * $RCSfile: gdsl_stack.c,v $
 * $Revision: 1.20 $
 * $Date: 2006/03/04 16:32:05 $
 */


#include <config.h>


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>


#include "_gdsl_list.h"
#include "gdsl_types.h"
#include "gdsl_stack.h"


#define _GDSL_STACK_DEFAULT_GROWING_FACTOR 1


struct _gdsl_stack
{
    char*             name;  /* name of the stack */
    ulong             card;  /* cardinality of the stack */
    ulong             size;  /* size of the stack */
    ulong             growing_factor;
    gdsl_element_t*   nodes; /* elements of the stack */
    
    gdsl_alloc_func_t alloc_f;
    gdsl_free_func_t  free_f;
};

static gdsl_element_t 
default_alloc (void* e);

static void 
default_free (gdsl_element_t e);

static gdsl_location_t
get_location (gdsl_stack_t stack, int i);

/******************************************************************************/
/* Management functions of stacks                                             */
/******************************************************************************/

extern gdsl_stack_t
gdsl_stack_alloc (const char* name, gdsl_alloc_func_t alloc_f, 
		  gdsl_free_func_t free_f)
{
    register int i;
    gdsl_stack_t s = NULL;

    s = (gdsl_stack_t) malloc (sizeof (struct _gdsl_stack));

    if (s == NULL)
	{
	    return NULL;
	}

    s->growing_factor = _GDSL_STACK_DEFAULT_GROWING_FACTOR;

    s->nodes = (gdsl_element_t*) malloc ((1 + s->growing_factor) * sizeof (gdsl_element_t));

    if (s->nodes == NULL)
	{
	    free (s);
	    return NULL;
	}

    for (i = 0; i <= s->growing_factor; i++)
	{
	    s->nodes [i] = NULL;
	}

    s->card = 0UL;
    s->size = s->growing_factor;
    s->name = NULL;

    if (gdsl_stack_set_name (s, name) == NULL)
	{
	    free (s->nodes);
	    free (s);
	    return NULL;
	}

    s->alloc_f = alloc_f ? alloc_f : default_alloc;
    s->free_f  = free_f  ? free_f  : default_free;

    return s;
}

extern void 
gdsl_stack_free (gdsl_stack_t s)
{
    assert (s != NULL);

    if (gdsl_stack_is_empty (s) == FALSE)
	{
	    gdsl_stack_flush (s);
	}

    free (s->nodes);
    free (s->name);
    free (s);
}

extern void
gdsl_stack_flush (gdsl_stack_t s)
{
    register int i;

    assert (s != NULL);

    for (i = 1; i <= s->card; i++)
	{
	    s->free_f (s->nodes [i]);
	    s->nodes [i] = NULL;
	}

    s->card = 0UL;
}

/******************************************************************************/
/* Consultation functions of stacks                                           */
/******************************************************************************/

extern const char*
gdsl_stack_get_name (const gdsl_stack_t s)
{
    assert (s != NULL);

    return s->name;
}

extern ulong
gdsl_stack_get_size (const gdsl_stack_t s)
{
    assert (s != NULL);

    return s->card;
}

extern ulong
gdsl_stack_get_growing_factor (const gdsl_stack_t s)
{
    assert (s != NULL);

    return s->growing_factor;
}

extern bool 
gdsl_stack_is_empty (const gdsl_stack_t s)
{
    assert (s != NULL);

    return (bool) (s->card == 0 ? TRUE : FALSE);
}

extern gdsl_element_t
gdsl_stack_get_top (const gdsl_stack_t s)
{
    assert (s != NULL);

    return s->nodes [s->card];
}

extern gdsl_element_t
gdsl_stack_get_bottom (const gdsl_stack_t s)
{
    assert (s != NULL);

    return s->nodes [1];
}

/******************************************************************************/
/* Modification functions of stacks                                           */
/******************************************************************************/

extern gdsl_stack_t
gdsl_stack_set_name (gdsl_stack_t s, const char* name)
{
    assert (s != NULL);

    if (s->name != NULL)
	{
	    free (s->name);
	    s->name = NULL;
	}

    if (name != NULL)
	{
	    s->name = (char*) malloc ((1 + strlen (name)) * sizeof (char));

	    if (s->name == NULL)
		{
		    return NULL;
		}

	    strcpy (s->name, name);
	}

    return s;
}

extern void
gdsl_stack_set_growing_factor (gdsl_stack_t s, ulong growing_factor)
{
    assert (s != NULL);
    assert (growing_factor > 0);

    s->growing_factor = growing_factor;
}

extern gdsl_element_t
gdsl_stack_insert (gdsl_stack_t s, void* value)
{
    gdsl_element_t e;

    assert (s != NULL);

    e = (s->alloc_f) (value);

    if (e == NULL)
	{
	    return NULL;
	}

    if (s->card == s->size)
	{
	    s->nodes = realloc (s->nodes, (1 + s->size + s->growing_factor) 
				* sizeof (gdsl_element_t));
	    
	    if (s->nodes == NULL)
		{
		    s->free_f (e);
		    return NULL;
		}

	    s->size += s->growing_factor;
	}

    s->card++;
    s->nodes [s->card] = e;

    return e;
}

extern gdsl_element_t
gdsl_stack_remove (gdsl_stack_t s)
{
    gdsl_element_t e;

    assert (s != NULL);

    if (s->card == 0)
	{
	    return NULL;
	}

    e = s->nodes [s->card];
    s->nodes [s->card] = NULL;
    s->card--;

    return e;
}

/******************************************************************************/
/* Search functions of stacks                                                 */
/******************************************************************************/

extern gdsl_element_t
gdsl_stack_search (const gdsl_stack_t s, gdsl_compare_func_t f, void* value)
{
    register int i;

    assert (s != NULL);
    assert (f != NULL);

    for (i = 1; i <= s->card; i++)
	{
	    if (f (s->nodes [i], value) == 0)
		{
		    return s->nodes [i];
		}
	}

    return NULL;
}

extern gdsl_element_t
gdsl_stack_search_by_position (const gdsl_stack_t s, ulong pos)
{
    assert (s != NULL);
    assert (pos > 0 && pos <= s->card);

    return s->nodes [pos];
}

/******************************************************************************/
/* Parse functions of stacks                                                  */
/******************************************************************************/

extern gdsl_element_t
gdsl_stack_map_forward (const gdsl_stack_t s, gdsl_map_func_t map_f, 
			void* user_data)
{
    register int i;

    assert (s != NULL);
    assert (map_f != NULL);

    for (i = s->card; i > 0; i--)
	{
	    if (map_f (s->nodes [i], get_location (s, i), user_data) == GDSL_MAP_STOP)
		{
		    return s->nodes [i];
		}
	}

    return NULL;
}

extern gdsl_element_t
gdsl_stack_map_backward (const gdsl_stack_t s, gdsl_map_func_t map_f, 
			 void* user_data)
{
    register int i;

    assert (s != NULL);
    assert (map_f != NULL);

    for (i = 1; i <= s->card; i++)
	{
	    if (map_f (s->nodes [i], get_location (s, i), user_data) == GDSL_MAP_STOP)
		{
		    return s->nodes [i];
		}
	}

    return NULL;
}

/******************************************************************************/
/* Input/output functions of stacks                                           */
/******************************************************************************/

extern void
gdsl_stack_write (const gdsl_stack_t s, gdsl_write_func_t write_f, FILE* file, 
		  void* user_data)
{
    register int i;

    assert (s != NULL);
    assert (write_f != NULL);
    assert (file != NULL);

    for (i = s->card; i > 0; i--)
	{
	    write_f (s->nodes [i], file, get_location (s, i), user_data);
	}
}

extern void
gdsl_stack_write_xml (const gdsl_stack_t s, gdsl_write_func_t write_f, FILE* file, 
		      void* user_data)
{
    register int i;

    assert (s != NULL);
    assert (file != NULL);

    fprintf (file, "<GDSL_STACK REF=\"%p\" NAME=\"%s\" CARD=\"%ld\" TOP=\"%p\" BOTTOM=\"%p\">\n", 
	     (void*) s, s->name, s->card, (void*) &(s->nodes [s->card]), (void*) &(s->nodes [1]));

    for (i = s->card; i > 0; i--)
	{
	    fprintf (file, "<GDSL_STACK_NODE REF=\"%p\" CONTENT=\"%p\">", 
		     (void*) &(s->nodes [i]), (void*) s->nodes [i]);
      
	    if (write_f && s->nodes [i])
		{
		    write_f (s->nodes [i], file, get_location (s, i), user_data);
		}

	    fprintf (file, "</GDSL_STACK_NODE>\n");
	}

    fprintf (file, "</GDSL_STACK>\n");
}

extern void
gdsl_stack_dump (const gdsl_stack_t s, gdsl_write_func_t write_f, FILE* file, void* user_data)
{
    register int i;

    assert (s != NULL);
    assert (file != NULL);

    fprintf (file, "<GDSL_STACK REF=\"%p\" NAME=\"%s\" CARD=\"%lu\" TOP=\"%p\" BOTTOM=\"%p\" SIZE=\"%lu\" GROW_FACTOR=\"%lu\">\n", 
	     (void*) s, s->name, s->card, (void*) &(s->nodes [s->card]), 
	     (void*) &(s->nodes [1]), s->size, s->growing_factor);

    for (i = 0; i <= s->size; i++)
	{
	    fprintf (file, "<GDSL_STACK_NODE REF=\"%p\" CONTENT=\"%p\">", 
		     (void*) &(s->nodes [i]), (void*) s->nodes [i]);
      
	    if (write_f && s->nodes [i])
		{
		    write_f (s->nodes [i], file, get_location (s, i), user_data);
		}

	    fprintf (file, "</GDSL_STACK_NODE>\n");
	}
}

/******************************************************************************/
/* Private functions                                                          */
/******************************************************************************/

static gdsl_element_t 
default_alloc (void* e)
{
    return e;
}

static void 
default_free (gdsl_element_t e)
{
    ;
}

static gdsl_location_t
get_location (gdsl_stack_t stack, int i)
{
    gdsl_location_t location = GDSL_LOCATION_UNDEF;

    if (stack->card == i)
	{
	    location |= GDSL_LOCATION_TOP;
	}
    
    if (i == 1)
	{
	    location |= GDSL_LOCATION_BOTTOM;
	}

    return location;
}


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
