/*
 * This file is part of the Generic Data Structures Library (GDSL).
 * Copyright (C) 1998-2013 Nicolas Darnis <ndarnis@free.fr>.
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
 * $RCSfile: gdsl_interval_heap.c,v $
 * $Revision: 1.2 $
 * $Date: 2013/06/12 16:36:13 $
 */


#include <config.h>


#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>


#include "gdsl_interval_heap.h"

#define MAX_INDEX(i) (2 * (i) + 1)

#define INDEX_MIN() (2) //the root node min
#define INDEX_MAX() (3) //the root node max

#define MIN_NODE(i) ((((i) / 2) * 2) + 0)  
#define MAX_NODE(i) ((((i) / 2) * 2) + 1)

#define PARENT_MIN(i) ((((i) / 4) * 2) + 0)
#define PARENT_MAX(i) ((((i) / 4) * 2) + 1)

#define CHILD1_MIN(i) ((((i) / 2) * 4) + 0)
#define CHILD2_MIN(i) ((((i) / 2) * 4) + 2)

#define CHILD1_MAX(i) ((((i) / 2) * 4) + 1)
#define CHILD2_MAX(i) ((((i) / 2) * 4) + 3)

#define LAST_INDEX(i) ((i) + 1)


struct heap
{
    char*               name;
    ulong               card;
    ulong               allocated;
    ulong               size;
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

static inline void
fix (gdsl_element_t* t, ulong k, gdsl_compare_func_t compf_f);

static void
taslacmite_min (gdsl_element_t* t, ulong k, gdsl_compare_func_t comp_f);

static void
taslacmite_max (gdsl_element_t* t, ulong k, gdsl_compare_func_t comp_f);

static ulong
taslactite_min (gdsl_element_t* t, ulong n, ulong k, gdsl_compare_func_t comp_f);

static ulong
taslactite_max (gdsl_element_t* t, ulong n, ulong k, gdsl_compare_func_t comp_f);

static gdsl_location_t
get_location (gdsl_interval_heap_t heap, int i);

/******************************************************************************/
/* Management functions of heaps                                              */
/******************************************************************************/

extern gdsl_interval_heap_t
gdsl_interval_heap_alloc (const char* name, 
			  gdsl_alloc_func_t alloc_f, gdsl_free_func_t free_f, 
			  gdsl_compare_func_t comp_f)
{
    gdsl_interval_heap_t heap;
  
    heap = (gdsl_interval_heap_t) malloc (sizeof (struct heap));

    if (heap == NULL)
	{
	    return NULL;
	}

    heap->name = NULL;

    if (gdsl_interval_heap_set_name (heap, name) == NULL)
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
    heap->size = INT_MAX;
    heap->allocated = 0;

    heap->alloc_f = alloc_f ? alloc_f : default_alloc;
    heap->free_f  = free_f  ? free_f  : default_free;
    heap->comp_f  = comp_f  ? comp_f  : default_comp;

    return heap;
}

extern void
gdsl_interval_heap_free (gdsl_interval_heap_t heap)
{
    ulong i;

    assert (heap != NULL);

    if (heap->name != NULL)
	{
	    free (heap->name);
	}

    for (i = 1; i < heap->card; i++)
	{
	    heap->free_f (heap->nodes [ LAST_INDEX(i) ]);
	}

    free ( heap->nodes );
    free (heap);
}

extern void
gdsl_interval_heap_flush (gdsl_interval_heap_t heap)
{
    ulong i;

    assert (heap != NULL);

    for (i = 1; i < heap->card; i++)
	{
	    heap->free_f (heap->nodes [ LAST_INDEX(i)] );
	}

    heap->card = 0;
}

/******************************************************************************/
/* Consultation functions of heaps                                            */
/******************************************************************************/

extern const char*
gdsl_interval_heap_get_name (const gdsl_interval_heap_t heap)
{
    assert (heap != NULL);

    return heap->name;
}

extern ulong
gdsl_interval_heap_get_size (const gdsl_interval_heap_t heap)
{
    assert (heap != NULL);

    return heap->card;
}

extern  void
gdsl_interval_heap_set_max_size (const gdsl_interval_heap_t H,
		    ulong size)
{
    assert (heap != NULL);

    H->size = size;
}

extern bool 
gdsl_interval_heap_is_empty (const gdsl_interval_heap_t heap)
{
    assert (heap != NULL);

    return (bool) (heap->card == 0);
}

/******************************************************************************/
/* Modification functions of heaps                                            */
/******************************************************************************/

extern gdsl_interval_heap_t
gdsl_interval_heap_set_name (gdsl_interval_heap_t heap, const char* name)
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

/*
extern gdsl_element_t
gdsl_interval_heap_set_top (gdsl_interval_heap_t heap, void* value)
{
    gdsl_element_t e;

    assert (heap != NULL);

    e = (heap->alloc_f) (value);

    if (e == NULL)
	{
	    return NULL;
	}

    heap->nodes [MAX_INDEX(0)] = e;

    if (taslactite (heap->nodes, heap->card, 0, heap->comp_f) == 0)
	{
	    (heap->free_f) (e);
	    heap->nodes [ MAX_INDEX(0) ] = NULL;
	    return NULL;
	}

    return heap->nodes [MAX_INDEX(0)];
}
*/

extern gdsl_element_t
gdsl_interval_heap_insert (gdsl_interval_heap_t heap, void* value)
{
    gdsl_element_t e;

    assert (heap != NULL);

    e = (heap->alloc_f) (value);

    if (e == NULL)
	{
	    return NULL;
	}

    if (heap->card == heap->size) 
	{
	    // the heap is full, so remove the min value and replace
	    // it with the newly inserted value
	    gdsl_element_t e1 = heap->nodes[ INDEX_MIN () ];
	    
	    // the value to be inserted is smaller than the smallest, so we just
	    // return it and do nothing.
	    if (heap->comp_f(e, e1) <= 0)
		{
		    return e;
		}
	    
        // we're inserting a node that's greater than the max
        // that means the max has to become the new min
	    if (heap->comp_f(e, heap->nodes[ INDEX_MAX() ]) > 0) 
		{
		    heap->nodes[ INDEX_MIN() ] = heap->nodes[INDEX_MAX ()];     
		    heap->nodes[ INDEX_MAX() ] = e;
		} 
	    else
		{
		    heap->nodes [ INDEX_MIN() ] = e;
		}

        taslactite_min (heap->nodes, LAST_INDEX (heap->card), LAST_INDEX (1), heap->comp_f);

        return e1;
    }

    if (3 + heap->card > heap->allocated) 
	{
	    heap->nodes = (gdsl_element_t*) realloc (heap->nodes, ((4 + (2 * heap->card)) * sizeof (gdsl_element_t)));
	    heap->allocated = (4 + (2 * heap->card));
	}

    if (heap->nodes == NULL)
	{
	    (heap->free_f) (e);
	    return NULL;
	}

    heap->card++;
    //insert into the last place available
    //if it's in the min position, it needs to be duplicated
    //in the max
    heap->nodes [ LAST_INDEX (heap->card) ] = e;
    heap->nodes [ MAX_NODE (LAST_INDEX (heap->card)) ] = e;

    fix (heap->nodes, MIN_NODE (LAST_INDEX (heap->card)), heap->comp_f);

    taslacmite_min (heap->nodes, MIN_NODE (LAST_INDEX (heap->card) ), heap->comp_f);
    taslacmite_max (heap->nodes, LAST_INDEX (heap->card), heap->comp_f);

    return NULL;
}

#if 0
extern gdsl_element_t
gdsl_interval_heap_remove (gdsl_interval_heap_t heap, void* value)
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
gdsl_interval_heap_remove_max (gdsl_interval_heap_t heap)
{
    gdsl_element_t e = NULL;

    assert (heap != NULL);

    if (heap->card == 0)
	{
	    return NULL;
	}

    // if there's only one element left, we must return the minimum
    // which is naturally also the maximum
    if (heap->card == 1)
    {
        e = heap->nodes[ INDEX_MIN () ];
        heap->card--;
        return e;
    }

    e = heap->nodes [ INDEX_MAX () ];
    heap->nodes [ INDEX_MAX () ] = heap->nodes [ LAST_INDEX (heap->card) ];

    heap->card--;
    taslactite_max (heap->nodes, LAST_INDEX (heap->card), LAST_INDEX (1), heap->comp_f);
    //gdsl_check_interval_heap_integrity(heap);
    //fprintf(stderr, "returning max: %x size: %d\n", e, heap->card);

    return e;
}

extern gdsl_element_t
gdsl_interval_heap_get_min (gdsl_interval_heap_t heap)
{
    gdsl_element_t e = NULL;

    assert (heap != NULL);

    if (heap->card == 0)
	{
	    return NULL;
	}

    e = heap->nodes [ INDEX_MIN () ];
    return e;
}


extern gdsl_element_t
gdsl_interval_heap_get_max (gdsl_interval_heap_t heap)
{
    gdsl_element_t e = NULL;

    assert (heap != NULL);

    if (heap->card == 0)
	{
	    return NULL;
	}

    if (heap->card == 1)
	{
	    e = heap->nodes [ INDEX_MIN () ];
	}
    else
	{
	    e = heap->nodes [ INDEX_MAX () ];
	}

    return e;
}

extern gdsl_element_t
gdsl_interval_heap_remove_min (gdsl_interval_heap_t heap)
{
    gdsl_element_t e = NULL;

    assert (heap != NULL);

    if (heap->card == 0)
	{
	    return NULL;
	}

    e = heap->nodes [ INDEX_MIN() ];

    if (LAST_INDEX (heap->card) == MAX_NODE (LAST_INDEX (heap->card))) 
	{
	    //the last index is a max node
	    //so we want to take the min node
	    heap->nodes [ INDEX_MIN () ] = heap->nodes [ MIN_NODE (LAST_INDEX (heap->card)) ];
	    
	    // and replace it with the max node
	    heap->nodes[ MIN_NODE (LAST_INDEX (heap->card)) ] = heap->nodes[ MAX_NODE (LAST_INDEX (heap->card)) ];
	}
    else
	{
	    //the last index is a min node so we just take that
	    heap->nodes [ INDEX_MIN () ] = heap->nodes [ LAST_INDEX (heap->card) ];
	}

    heap->card--;
    taslactite_min (heap->nodes, LAST_INDEX (heap->card), LAST_INDEX (1), heap->comp_f);

    //gdsl_check_interval_heap_integrity(heap);

    return e;
}


extern gdsl_interval_heap_t
gdsl_interval_heap_delete_min (gdsl_interval_heap_t heap)
{
    gdsl_element_t e = gdsl_interval_heap_remove_min (heap);

    if (e == NULL)
	{
	    return NULL;
	}

    heap->free_f (e);
    return heap;
}

extern gdsl_interval_heap_t
gdsl_interval_heap_delete_max (gdsl_interval_heap_t heap)
{
    gdsl_element_t e = gdsl_interval_heap_remove_max (heap);

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
gdsl_interval_heap_map_forward (const gdsl_interval_heap_t heap, gdsl_map_func_t map_f, void* user_data)
{
    ulong i;

    assert (heap != NULL);
    assert (map_f != NULL);

    for (i = 1; i <= heap->card; i++)
	{
	    gdsl_element_t e = heap->nodes [ LAST_INDEX(i) ];

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
gdsl_interval_heap_write (const gdsl_interval_heap_t heap, gdsl_write_func_t write_f, FILE* file, 
		 void* user_data)
{
    ulong i;

    for (i = 1; i <= heap->card; i++)
	{
	    if (write_f != NULL)
		{
		    write_f (heap->nodes [ LAST_INDEX(i) ], file, get_location (heap, i), 
			     user_data);
		}
	}
}

extern void
gdsl_interval_heap_write_xml (const gdsl_interval_heap_t heap, gdsl_write_func_t write_f, FILE* file, 
		     void* user_data)
{
    ulong i;

    fprintf (file, "<GDSL_INTERVAL_HEAP REF=\"%p\" NAME=\"%s\" SIZE=\"%ld\">\n",
	     (void*) heap, heap->name == NULL ? "" : heap->name, heap->card);

    for (i = 1; i <= heap->card; i++)
	{
	    fprintf (file, "<GDSL_INTERVAL_HEAP_ENTRY VALUE=\"%ld\">\n", i);
	    if (write_f != NULL)
		{
		    write_f (heap->nodes [ LAST_INDEX(i) ], file, get_location (heap, i), 
			     user_data);
		}
	    fprintf (file, "</GDSL_INTERVAL_HEAP_ENTRY>\n");
	}

    fprintf (file, "</GDSL_INTERVAL_HEAP>\n");
}

extern void
gdsl_interval_heap_dump (const gdsl_interval_heap_t heap, gdsl_write_func_t write_f, FILE* file, 
			 void* user_data)
{
    ulong i;

    fprintf (file, "<GDSL_INTERVAL_HEAP REF=\"%p\" NAME=\"%s\" SIZE=\"%ld\">\n",
	     (void*) heap, heap->name == NULL ? "" : heap->name, heap->card);

    for (i = 1; i <= heap->card; i++)
	{
	    fprintf (file, "<GDSL_INTERVAL_HEAP_ENTRY VALUE=\"%ld\">\n", i);
	    if (write_f != NULL)
		{
		    write_f (heap->nodes [ LAST_INDEX(i) ], file, get_location (heap, i), 
			     user_data);
		}
	    fprintf (file, "</GDSL_INTERVAL_HEAP_ENTRY>\n");
	}

    fprintf (file, "</GDSL_INTERVAL_HEAP>\n");
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
    return 0;
}

static void
fix (gdsl_element_t* t, ulong k, gdsl_compare_func_t comp_f) 
{
    //k should refer to the smaller element
    //of a min-max pair
    
    if (comp_f (t[k], t[k+1]) > 0) 
	{
	    // if the left element is greater than
	    // the right, then swap the two
	    gdsl_element_t temp = t[k];
	    t[k] = t[k+1];
	    t[k+1] = temp;
	}
}

static void 
taslacmite_min (gdsl_element_t* t, ulong k, gdsl_compare_func_t comp_f)
{
    /*
     * Traverse up the tree comparing and swapping minimum values.
     */
    gdsl_element_t v;
    v = t[k];
    
    while (k > INDEX_MAX () && comp_f (t[PARENT_MIN (k)], v) > 0) 
	{
	    t[ k ] = t[ PARENT_MIN (k) ];
	    k = PARENT_MIN (k);
	}
    
    t[k] = v;
}

static void 
taslacmite_max (gdsl_element_t* t, ulong k, gdsl_compare_func_t comp_f)
{
    /*
     * Traverse up the tree comparing and swapping maximum values.
     */
    gdsl_element_t v;
    v = t[k];
    
    while (k > INDEX_MAX () && comp_f (t[PARENT_MAX (k)], v) < 0) 
	{
	    t[ k ] = t[ PARENT_MAX (k) ];
	    k = PARENT_MAX (k);
	}
    
    t[k] = v;
}

static ulong
taslactite_min (gdsl_element_t* t, ulong n, ulong k, gdsl_compare_func_t comp_f)
{
    ulong          j;
    gdsl_element_t v;
    k = MIN_NODE (k);

    v = t [ k ];

    while (k <= PARENT_MIN (MIN_NODE (n)))
	{
        int comp;

        comp = comp_f (v, t[ MAX_NODE (k) ]);

        if (comp > 0) 
	    {
		gdsl_element_t *temp = v;
		v = t[ MAX_NODE (k) ];
		t[ MAX_NODE (k) ] = temp;
	    }

        j = CHILD1_MIN (k);

        if (j < MIN_NODE (n) && comp_f ( t [ j ] , t [ CHILD2_MIN (k)  ]) > 0)
        {
            j = CHILD2_MIN (k);
        }

        if (comp_f (t [ j ], v) >= 0) 
        {
            break;
        }
	
	t [ k ] = t [ j ];
	
	k = j;
	}
    
    t [ k ] = v;
    
    if (k != n)
	{
	    fix (t, k, comp_f);
	}

    return k;
}

static ulong
taslactite_max (gdsl_element_t* t, ulong n, ulong k, gdsl_compare_func_t comp_f)
{
    ulong          j;
    gdsl_element_t v;
    k = MAX_NODE (k);

    v = t [ k ];

    while (k <= PARENT_MAX (MAX_NODE (n)))
	{

        if (comp_f (t[ MIN_NODE(k) ], v) > 0) 
	    {
		gdsl_element_t *temp = v;
		v = t[MIN_NODE (k)];
		t[MIN_NODE (k)] = temp;
	    }

        j = CHILD1_MAX (k);

        if (j < MAX_NODE (n) && comp_f (t [ j ], t [ CHILD2_MAX (k)  ]) < 0)
        {
            j = CHILD2_MAX (k);
        }

        if (comp_f (t [ j ], v) <= 0) 
        {
            break;
        }

	t [ k ] = t [ j ];
	
	k = j;
	}
    
    t [ k ] = v;
    fix (t, k-1, comp_f);

    return k;
}

static gdsl_location_t
get_location (gdsl_interval_heap_t heap, int i)
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
