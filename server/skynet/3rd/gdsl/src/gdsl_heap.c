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
 * $RCSfile: gdsl_heap.c,v $
 * $Revision: 1.14 $
 * $Date: 2012/08/21 13:00:04 $
 */


#include <config.h>


#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#include "gdsl_heap.h"


struct heap
{
    char*               name;
    ulong               card;
    gdsl_element_t*     nodes;

    gdsl_alloc_func_t   alloc_f;
    gdsl_free_func_t    free_f;
    gdsl_compare_func_t comp_f;
};

static gdsl_element_t 
default_alloc (void* e);

static void 
default_free (gdsl_element_t e);

static long int 
default_comp (gdsl_element_t e, void* key);

static gdsl_location_t
get_location (gdsl_heap_t heap, int i);

static void
taslacmite (gdsl_element_t* t, ulong k, gdsl_compare_func_t comp_f);

static ulong
taslactite (gdsl_element_t* t, ulong n, ulong k, gdsl_compare_func_t comp_f);

/******************************************************************************/
/* Management functions of heaps                                              */
/******************************************************************************/

extern gdsl_heap_t
gdsl_heap_alloc (const char* name, 
		 gdsl_alloc_func_t alloc_f, gdsl_free_func_t free_f, 
		 gdsl_compare_func_t comp_f)
{
    gdsl_heap_t heap;
  
    heap = (gdsl_heap_t) malloc (sizeof (struct heap));

    if (heap == NULL)
	{
	    return NULL;
	}

    heap->name = NULL;

    if (gdsl_heap_set_name (heap, name) == NULL)
	{
	    free (heap);
	    return NULL;
	}

    heap->nodes = (gdsl_element_t*) malloc (sizeof (gdsl_element_t));
    if (heap->nodes == NULL)
	{
	    if (heap->name != NULL)
		{
		    free (heap->name);
		}
	    free (heap);
	    return NULL;
	}

    heap->nodes [0] = NULL;
    heap->card = 0;

    heap->alloc_f = alloc_f ? alloc_f : default_alloc;
    heap->free_f  = free_f  ? free_f  : default_free;
    heap->comp_f  = comp_f  ? comp_f  : default_comp;

    return heap;
}

extern void
gdsl_heap_free (gdsl_heap_t heap)
{
    ulong i;

    assert (heap != NULL);

    if (heap->name != NULL)
	{
	    free (heap->name);
	}

    for (i = 1; i < heap->card; i++)
	{
	    heap->free_f (heap->nodes [i]);
	}

    free (heap->nodes);
    free (heap);
}

extern void
gdsl_heap_flush (gdsl_heap_t heap)
{
    ulong i;

    assert (heap != NULL);

    for (i = 1; i < heap->card; i++)
	{
	    heap->free_f (heap->nodes [i]);
	}

    heap->card = 0;
}

/******************************************************************************/
/* Consultation functions of heaps                                            */
/******************************************************************************/

extern const char*
gdsl_heap_get_name (const gdsl_heap_t heap)
{
    assert (heap != NULL);

    return heap->name;
}

extern ulong
gdsl_heap_get_size (const gdsl_heap_t heap)
{
    assert (heap != NULL);

    return heap->card;
}

extern gdsl_element_t
gdsl_heap_get_top (const gdsl_heap_t heap)
{
    assert (heap != NULL);

    return (heap->card == 0) ? NULL : heap->nodes [1];
}

extern bool 
gdsl_heap_is_empty (const gdsl_heap_t heap)
{
    assert (heap != NULL);

    return (bool) (heap->card == 0);
}

/******************************************************************************/
/* Modification functions of heaps                                            */
/******************************************************************************/

extern gdsl_heap_t
gdsl_heap_set_name (gdsl_heap_t heap, const char* name)
{
    if (heap->name != NULL)
	{
	    free (heap->name);
	    heap->name = NULL;
	}

    if (name != NULL)
	{
	    heap->name = (char*) malloc ((1 + strlen (name)) * sizeof (char));

	    if (heap->name == NULL)
		{
		    return NULL;
		}

	    strcpy (heap->name, name);
	}

    return heap;
}

extern gdsl_element_t
gdsl_heap_set_top (gdsl_heap_t heap, void* value)
{
    gdsl_element_t e;

    assert (heap != NULL);

    e = (heap->alloc_f) (value);

    if (e == NULL)
	{
	    return NULL;
	}

    heap->nodes [0] = e;

    if (taslactite (heap->nodes, heap->card, 0, heap->comp_f) == 0)
	{
	    (heap->free_f) (e);
	    heap->nodes [0] = NULL;
	    return NULL;
	}

    return heap->nodes [0];
}

extern gdsl_element_t
gdsl_heap_insert (gdsl_heap_t heap, void* value)
{
    gdsl_element_t e;

    assert (heap != NULL);

    e = (heap->alloc_f) (value);

    if (e == NULL)
	{
	    return NULL;
	}

    heap->nodes = (gdsl_element_t*) realloc (heap->nodes, (2 + heap->card)
					     * sizeof (gdsl_element_t));

    if (heap->nodes == NULL)
	{
	    (heap->free_f) (e);
	    return NULL;
	}

    heap->card++;
    heap->nodes [heap->card] = e;
    taslacmite (heap->nodes, heap->card, heap->comp_f);

    return e;
}

#if 0
extern gdsl_element_t
gdsl_heap_remove (gdsl_heap_t heap, void* value)
{
    ulong j;
    ulong k;
    ulong n;
#warning this method is not finished
    assert (heap != NULL);

    k = 1;
    n = heap->card;
    while (k <= n / 2)
	{
	    if (heap->comp_f (value, heap->nodes [k]) == 0)
		{
		    gdsl_element_t e = heap->nodes [k];

		    heap->nodes [k] = heap->nodes [heap->card];
		    heap->card--;
		    taslactite (heap->nodes, heap->card, k, heap->comp_f);

		    return e;
		}

	    j = k + k;

	    if (heap->comp_f (value, heap->nodes [j]) < 0)
	    
	    k = j;
	}

    return NULL;
}
#endif

extern gdsl_element_t
gdsl_heap_remove_top (gdsl_heap_t heap)
{
    gdsl_element_t e = NULL;

    assert (heap != NULL);

    if (heap->card == 0)
	{
	    return NULL;
	}

    e = heap->nodes [1];
    heap->nodes [1] = heap->nodes [heap->card];
    heap->card--;
    taslactite (heap->nodes, heap->card, 1, heap->comp_f);

    return e;
}

extern gdsl_heap_t
gdsl_heap_delete_top (gdsl_heap_t heap)
{
    gdsl_element_t e = gdsl_heap_remove_top (heap);

    if (e == NULL)
	{
	    return NULL;
	}

    heap->free_f (e);
    return heap;
}

/******************************************************************************/
/* Parse functions of heaps                                                   */
/******************************************************************************/

extern gdsl_element_t
gdsl_heap_map_forward (const gdsl_heap_t heap, gdsl_map_func_t map_f, void* user_data)
{
    ulong i;

    assert (heap != NULL);
    assert (map_f != NULL);

    for (i = 1; i <= heap->card; i++)
	{
	    gdsl_element_t e = heap->nodes [i];

	    if (map_f (e, get_location (heap, i), user_data) == GDSL_MAP_STOP)
		{
		    return e;
		}
	}

    return NULL;
}

/******************************************************************************/
/* Input/output functions of heaps                                            */
/******************************************************************************/

extern void
gdsl_heap_write (const gdsl_heap_t heap, gdsl_write_func_t write_f, FILE* file, 
		 void* user_data)
{
    ulong i;

    for (i = 1; i <= heap->card; i++)
	{
	    if (write_f != NULL)
		{
		    write_f (heap->nodes [i], file, get_location (heap, i), 
			     user_data);
		}
	}
}

extern void
gdsl_heap_write_xml (const gdsl_heap_t heap, gdsl_write_func_t write_f, FILE* file, 
		     void* user_data)
{
    ulong i;

    fprintf (file, "<GDSL_HEAP REF=\"%p\" NAME=\"%s\" SIZE=\"%ld\">\n",
	     (void*) heap, heap->name == NULL ? "" : heap->name, heap->card);

    for (i = 1; i <= heap->card; i++)
	{
	    fprintf (file, "<GDSL_HEAP_ENTRY VALUE=\"%ld\">\n", i);
	    if (write_f != NULL)
		{
		    write_f (heap->nodes [i], file, get_location (heap, i), 
			     user_data);
		}
	    fprintf (file, "</GDSL_HEAP_ENTRY>\n");
	}

    fprintf (file, "</GDSL_HEAP>\n");
}

extern void
gdsl_heap_dump (const gdsl_heap_t heap, gdsl_write_func_t write_f, FILE* file, 
		void* user_data)
{
    ulong i;

    fprintf (file, "<GDSL_HEAP REF=\"%p\" NAME=\"%s\" SIZE=\"%ld\">\n",
	     (void*) heap, heap->name == NULL ? "" : heap->name, heap->card);

    for (i = 1; i <= heap->card; i++)
	{
	    fprintf (file, "<GDSL_HEAP_ENTRY VALUE=\"%ld\">\n", i);
	    if (write_f != NULL)
		{
		    write_f (heap->nodes [i], file, get_location (heap, i), 
			     user_data);
		}
	    fprintf (file, "</GDSL_HEAP_ENTRY>\n");
	}

    fprintf (file, "</GDSL_HEAP>\n");
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

static long int 
default_comp (gdsl_element_t e, void* key)
{
    fprintf(stderr, "default_comp\n");
    return 0;
}

static void
taslacmite (gdsl_element_t* t, ulong k, gdsl_compare_func_t comp_f)
{
    gdsl_element_t v;
    
    v = t [k];

    /* to avoid k != 1 test below, we could
     * add the instruction t [0] = MAX_POSSIBLE_VALUE
     * but, we don't know MAX_POSSIBLE_VALUE here.
     */

    while (k != 1 && comp_f (t [k/2], v) <= 0)
	{
	    t [k] = t [k/2];
	    k /= 2;
	}

    t [k] = v;
}

static ulong
taslactite (gdsl_element_t* t, ulong n, ulong k, gdsl_compare_func_t comp_f)
{
    ulong          j;
    gdsl_element_t v;

    v = t [k];

    while (k <= n / 2)
	{
	    j = k + k;

	    if (j < n && comp_f (t [j], t [j+1]) < 0)
		{
		    j++;
		}

	    if (comp_f (t [j], v) <= 0)
		{
		    break;
		}

	    t [k] = t [j];
	    k = j;
	}

    t [k] = v;
    return k;
}

static gdsl_location_t
get_location (gdsl_heap_t heap, int i)
{
    gdsl_location_t location = GDSL_LOCATION_UNDEF;

    if (i == 1)
	{
	    location |= GDSL_LOCATION_ROOT;
	}
    
    if (i == heap->card)
	{  
	    location |= GDSL_LOCATION_LEAF;
	}
    
    if (i * 2 > heap->card)
	{
	    location |= GDSL_LOCATION_LEAF;
	}
    
    return location;
}

                                                                        
/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
