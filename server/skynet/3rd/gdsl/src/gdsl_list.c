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
 * $RCSfile: gdsl_list.c,v $
 * $Revision: 1.26 $
 * $Date: 2006/03/04 16:32:05 $
 */


#include <config.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>


#include "_gdsl_node.h"
#include "_gdsl_list.h"
#include "gdsl_types.h"
#include "gdsl_list.h"


struct _gdsl_list
{
  _gdsl_node_t      d;          /* begin of the list (sentinel)     */
  _gdsl_node_t      z;          /* end of the list (sentinel)       */
  char*             name;       /* name of the list                 */
  ulong             card;       /* cardinality of the list          */

  gdsl_alloc_func_t alloc_func; /* alloc element function pointer   */
  gdsl_free_func_t  free_func;  /* dealloc element function pointer */
};

struct _gdsl_list_cursor
{
    _gdsl_node_t c;
    gdsl_list_t  l;
};

static gdsl_element_t 
default_alloc (void* e);

static void 
default_free (gdsl_element_t e);

static _gdsl_node_t 
search_by_function (gdsl_list_t l, gdsl_compare_func_t comp_f, const void* v);

static _gdsl_node_t 
search_by_position (gdsl_list_t l, ulong pos);

static gdsl_element_t 
update_cursor (gdsl_list_cursor_t c, _gdsl_node_t n);

static _gdsl_node_t 
sort (_gdsl_node_t u, gdsl_compare_func_t comp_f, _gdsl_node_t z);

static _gdsl_node_t 
merge (_gdsl_node_t s, _gdsl_node_t t, gdsl_compare_func_t comp_f, 
       _gdsl_node_t z);

static gdsl_location_t
get_location (gdsl_list_t list, _gdsl_node_t node);

/******************************************************************************/
/* Management functions of doubly-linked lists                                */
/******************************************************************************/

extern gdsl_list_t
gdsl_list_alloc (const char* name, gdsl_alloc_func_t alloc_func, 
		 gdsl_free_func_t free_func)
{
    gdsl_list_t list;
    
    list = (gdsl_list_t) malloc (sizeof (struct _gdsl_list));
    
    if (list == NULL)
	{
	    return NULL;
	}
    
    list->d = _gdsl_node_alloc ();
    
    if (list->d == NULL)
	{
	    free (list);
	    return NULL;
	}
    
    list->z = _gdsl_node_alloc ();
    
    if (list->z == NULL)
	{
	    _gdsl_node_free (list->d);
	    free (list);
	    return NULL;
	}
    
    list->name = NULL;
    
    if (gdsl_list_set_name (list, name) == NULL)
	{
	    _gdsl_node_free (list->z);
	    _gdsl_node_free (list->d);
	    free (list);
	    return NULL;
	}
    
    _gdsl_node_link (list->d, list->z);
    _gdsl_node_set_succ (list->z, list->z);
    _gdsl_node_set_pred (list->d, list->d);
    
    list->card = 0UL;
    list->alloc_func = alloc_func ? alloc_func : default_alloc;
    list->free_func  = free_func  ? free_func  : default_free;
    
    return list;
}

extern void 
gdsl_list_free (gdsl_list_t list)
{
    assert (list != NULL);

    if (!gdsl_list_is_empty (list))
	{
	    gdsl_list_flush (list);
	}

    _gdsl_node_free (list->d);
    _gdsl_node_free (list->z);

    if (list->name != NULL)
	{
	    free (list->name);
	}

    free (list);
}

extern void
gdsl_list_flush (gdsl_list_t list)
{
    _gdsl_node_t save;
    _gdsl_node_t tmp;

    assert (list != NULL);

    tmp = _gdsl_node_get_succ (list->d);

    while (tmp != list->z)
	{
	    save = _gdsl_node_get_succ (tmp);
	    list->free_func (_gdsl_node_get_content (tmp));
	    _gdsl_node_free (tmp);
	    tmp = save;
	}

    _gdsl_node_link (list->d, list->z);
    _gdsl_node_set_succ (list->z, list->z);
    _gdsl_node_set_pred (list->d, list->d);

    list->card = 0UL;
}

/******************************************************************************/
/* Consultation functions of doubly-linked lists                              */
/******************************************************************************/

extern const char*
gdsl_list_get_name (const gdsl_list_t list)
{
    assert (list != NULL);

    return list->name;
}

extern ulong
gdsl_list_get_size (const gdsl_list_t list)
{
    assert (list != NULL);

    return list->card;
}

extern bool
gdsl_list_is_empty (const gdsl_list_t list)
{
    assert (list != NULL);

    return (bool) (_gdsl_node_get_succ (list->d) == list->z);
}

extern gdsl_element_t
gdsl_list_get_head (const gdsl_list_t list)
{
    assert (list != NULL);

    return _gdsl_node_get_content (_gdsl_node_get_succ (list->d));
}

extern gdsl_element_t
gdsl_list_get_tail (const gdsl_list_t list)
{
    assert (list != NULL);

    return _gdsl_node_get_content (_gdsl_node_get_pred (list->z));
}

/******************************************************************************/
/* Modification functions of doubly-linked lists                              */
/******************************************************************************/

extern gdsl_list_t
gdsl_list_set_name (gdsl_list_t list, const char* name)
{
    assert (list != NULL);

    if (list->name != NULL)
	{
	    free (list->name);
	    list->name = NULL;
	}

    if (name != NULL)
	{
	    list->name = (char*) malloc ((1 + strlen (name)) * sizeof (char));

	    if (list->name == NULL)
		{
		    return NULL;
		}

	    strcpy (list->name, name);
	}

    return list;
}

extern gdsl_element_t 
gdsl_list_insert_head (gdsl_list_t list, void* v)
{
    gdsl_element_t e;
    _gdsl_node_t   head;

    assert (list != NULL);

    head = _gdsl_node_alloc ();

    if (head == NULL)
	{
	    return NULL;
	}

    e = list->alloc_func (v);

    if (e == NULL)
	{
	    _gdsl_node_free (head);
	    return NULL;
	}

    list->card++;

    _gdsl_node_set_content (head, e);  
    _gdsl_node_link (head, _gdsl_node_get_succ (list->d));
    _gdsl_node_link (list->d, head);

    return e;
}

extern gdsl_element_t
gdsl_list_insert_tail (gdsl_list_t list, void* v)
{
    gdsl_element_t e;
    _gdsl_node_t   tail;

    assert (list != NULL);

    tail = _gdsl_node_alloc ();

    if (tail == NULL)
	{
	    return NULL;
	}

    e = list->alloc_func (v);

    if (e == NULL)
	{
	    _gdsl_node_free (tail);
	    return NULL;
	}

    list->card++;

    _gdsl_node_set_content (tail, e);
    _gdsl_node_link (_gdsl_node_get_pred (list->z), tail);
    _gdsl_node_link (tail, list->z);

    return e;
}

extern gdsl_element_t
gdsl_list_remove_head (gdsl_list_t list)
{
    assert (list != NULL);

    if (!gdsl_list_is_empty (list))
	{
	    _gdsl_node_t   head = _gdsl_node_get_succ (list->d);
	    gdsl_element_t e    = _gdsl_node_get_content (head);
      
	    _gdsl_list_remove (head);
	    _gdsl_node_free (head);
      
	    list->card--;
	    return e;
	}
  
    return NULL;
}

extern gdsl_element_t
gdsl_list_remove_tail (gdsl_list_t list)
{
    assert (list != NULL);

    if (!gdsl_list_is_empty (list))
	{
	    _gdsl_node_t tail = _gdsl_node_get_pred (list->z);
	    gdsl_element_t e = _gdsl_node_get_content (tail);

	    _gdsl_list_remove (tail);
	    _gdsl_node_free (tail);

	    list->card--;
	    return e;
	}

    return NULL;
}

extern gdsl_element_t
gdsl_list_remove (gdsl_list_t list, gdsl_compare_func_t comp_f, const void* v)
{
    _gdsl_node_t   n;
    gdsl_element_t e;

    assert (list != NULL);
    assert (comp_f != NULL);

    n = search_by_function (list, comp_f, v);

    if (n == NULL)
	{
	    return NULL;
	}

    e = _gdsl_node_get_content (n);

    _gdsl_list_remove (n);
    _gdsl_node_free (n);

    list->card--;

    return e;
}

extern gdsl_list_t
gdsl_list_delete_head (gdsl_list_t list)
{
    gdsl_element_t e;

    assert (list != NULL);

    e = gdsl_list_remove_head (list);

    if (e == NULL)
	{
	    return NULL;
	}

    list->free_func (e);

    return list;
}

extern gdsl_list_t
gdsl_list_delete_tail (gdsl_list_t list)
{
    gdsl_element_t e;

    assert (list != NULL);

    e = gdsl_list_remove_tail (list);
  
    if (e == NULL)
	{
	    return NULL;
	}

    list->free_func (e);

    return list;
}

extern gdsl_list_t
gdsl_list_delete (gdsl_list_t list, gdsl_compare_func_t comp_f, const void* v)
{
    gdsl_element_t e;

    assert (list != NULL);
    assert (comp_f != NULL);

    e = gdsl_list_remove (list, comp_f, v);

    if (e == NULL)
	{
	    return NULL;
	}

    list->free_func (e);

    return list;
}

/******************************************************************************/
/* Search functions of doubly-linked lists                                    */
/******************************************************************************/

extern gdsl_element_t
gdsl_list_search (const gdsl_list_t list, gdsl_compare_func_t comp_f, 
		  const void* value)
{
    _gdsl_node_t n;

    assert (list != NULL);
    assert (comp_f != NULL);

    n = search_by_function (list, comp_f, value);

    return (n == NULL) ? NULL : _gdsl_node_get_content (n);
}

extern gdsl_element_t
gdsl_list_search_by_position (const gdsl_list_t list, ulong pos)
{
    _gdsl_node_t n;

    assert (list != NULL);
    assert (pos > 0 && pos <= list->card);

    n = search_by_position (list, pos);

    return n ? _gdsl_node_get_content (n) : NULL;
}

extern gdsl_element_t
gdsl_list_search_max (const gdsl_list_t list, gdsl_compare_func_t comp_f)
{
    _gdsl_node_t   tmp;
    gdsl_element_t max;

    assert (list != NULL);
    assert (comp_f != NULL);

    tmp = _gdsl_node_get_succ (list->d);
    max = _gdsl_node_get_content (tmp);

    while (tmp != list->z)
	{
	    gdsl_element_t e = _gdsl_node_get_content (tmp);

	    if (comp_f (e, max) > 0)
		{
		    max = e;
		}

	    tmp = _gdsl_node_get_succ (tmp);
	}

    return max;
}

extern gdsl_element_t
gdsl_list_search_min (const gdsl_list_t list, gdsl_compare_func_t comp_f)
{
    _gdsl_node_t tmp;
    gdsl_element_t min;

    assert (list != NULL);
    assert (comp_f != NULL);

    tmp = _gdsl_node_get_succ (list->d);
    min = _gdsl_node_get_content (tmp);

    while (tmp != list->z)
	{
	    gdsl_element_t e = _gdsl_node_get_content (tmp);

	    if (comp_f (e, min) < 0)
		{
		    min = e;
		}

	    tmp = _gdsl_node_get_succ (tmp);
	}

    return min;
}

/******************************************************************************/
/* Sort functions of doubly-linked lists                                      */
/******************************************************************************/

extern gdsl_list_t
gdsl_list_sort (gdsl_list_t list, gdsl_compare_func_t comp_f
#ifdef USES_MAX
		, gdsl_element_t max
#endif
		)
{
    assert (list != NULL);
    assert (comp_f != NULL);

    /*
     * Sort the list l with merge-sort algorithm 
     *
     * VERY IMPORTANT: max must be an element NOT ALREADY PRESENT in l
     *                 AND GREATEST than ALL other l's elements!
     *
     * If max is used, the merge algorithm does not need first two tests.
     */
  
#ifdef USES_MAX
    _gdsl_node_set_content (list->z, max); /* [1] */
#endif

    _gdsl_node_link (list->d, 
		     sort (_gdsl_node_get_succ (list->d), comp_f, list->z));

#ifdef USES_MAX
    _gdsl_node_set_content (list->z, NULL);
#endif

    return list;
}

/******************************************************************************/
/* Parse functions of doubly-linked lists                                     */
/******************************************************************************/

extern gdsl_element_t 
gdsl_list_map_forward (const gdsl_list_t list, gdsl_map_func_t map_f, 
		       void* user_data)
{
    _gdsl_node_t tmp;

    assert (list != NULL);
    assert (map_f != NULL);

    tmp = _gdsl_node_get_succ (list->d);

    while (tmp != list->z)
	{
	    gdsl_element_t e = _gdsl_node_get_content (tmp);

	    if (map_f (e, get_location (list, tmp), user_data) == GDSL_MAP_STOP)
		{
		    return e;
		}

	    tmp = _gdsl_node_get_succ (tmp);
	}

    return NULL;
}

extern gdsl_element_t 
gdsl_list_map_backward (const gdsl_list_t list, gdsl_map_func_t map_f, 
			void* user_data)
{
    _gdsl_node_t tmp;

    assert (list != NULL);
    assert (map_f != NULL);

    tmp = _gdsl_node_get_pred (list->z);

    while (tmp != list->d)
	{
	    gdsl_element_t e = _gdsl_node_get_content (tmp);

	    if (map_f (e, get_location (list, tmp), user_data) == GDSL_MAP_STOP)
		{
		    return e;
		}

	    tmp = _gdsl_node_get_pred (tmp);
	}

    return NULL;
}

/******************************************************************************/
/* Input/output functions of doubly-linked lists                              */
/******************************************************************************/

extern void
gdsl_list_write (const gdsl_list_t list, gdsl_write_func_t write_f, 
		 FILE* file, void* user_data)
{
    _gdsl_node_t tmp;

    assert (list != NULL);
    assert (write_f != NULL);
    assert (file != NULL);

    tmp = _gdsl_node_get_succ (list->d);

    while (tmp != list->z)
	{
	    write_f (_gdsl_node_get_content (tmp), file, 
		     get_location (list, tmp), user_data);
	    tmp = _gdsl_node_get_succ (tmp);
	}
}

extern void
gdsl_list_write_xml (const gdsl_list_t list, gdsl_write_func_t write_f, 
		     FILE* file, void* user_data)
{
    _gdsl_node_t tmp;

    assert (list != NULL);
    assert (file != NULL);

    tmp = _gdsl_node_get_succ (list->d);

    fprintf (file, "<GDSL_LIST REF=\"%p\" NAME=\"%s\" CARD=\"%ld\" HEAD=\"%p\" TAIL=\"%p\">\n", 
	     (void*) list, list->name ? list->name : "", list->card, (void*) tmp, 
	     (void*) _gdsl_node_get_pred (list->z));

    while (tmp != list->z)
	{
	    if (tmp == _gdsl_node_get_succ (list->d))
		{
		    fprintf (file, "<GDSL_LIST_NODE REF=\"%p\" CONTENT=\"%p\" SUCC=\"%p\" PRED=\"\">", 
			     (void*) tmp, (void*) _gdsl_node_get_content (tmp), 
			     (void*) _gdsl_node_get_succ (tmp));
		}
	    else if (tmp == _gdsl_node_get_pred (list->z))
		{
		    fprintf (file, "<GDSL_LIST_NODE REF=\"%p\" CONTENT=\"%p\" SUCC=\"\" PRED=\"%p\">", 
			     (void*) tmp, (void*) _gdsl_node_get_content (tmp), 
			     (void*) _gdsl_node_get_pred (tmp));
		}
	    else
		{
		    fprintf (file, "<GDSL_LIST_NODE REF=\"%p\" CONTENT=\"%p\" SUCC=\"%p\" PRED=\"%p\">", 
			     (void*) tmp, (void*) _gdsl_node_get_content (tmp), 
			     (void*) _gdsl_node_get_succ (tmp), (void*) _gdsl_node_get_pred (tmp));
		}

	    if (write_f != NULL && _gdsl_node_get_content (tmp))
		{
		    write_f (_gdsl_node_get_content (tmp), file, 
			     get_location (list, tmp), user_data);
		}

	    fprintf (file, "</GDSL_LIST_NODE>\n");

	    tmp = _gdsl_node_get_succ (tmp);
	}

    fprintf (file, "</GDSL_LIST>\n");
}

extern void
gdsl_list_dump (const gdsl_list_t list, gdsl_write_func_t write_f, FILE* file, 
		void* user_data)
{
    _gdsl_node_t tmp;

    assert (list != NULL);
    assert (file != NULL);

    tmp = _gdsl_node_get_succ (list->d);

    fprintf (file, "<GDSL_LIST REF=\"%p\" NAME=\"%s\" CARD=\"%ld\" HEAD=\"%p\" TAIL=\"%p\">\n", 
	     (void*) list, list->name ? list->name : "", list->card, (void*) list->d, (void*) list->z);

    if (_gdsl_node_get_content (list->d))
	{
	    fprintf (file, "<GDSL_LIST_HEAD REF=\"%p\" CONTENT=\"%p\" SUCC=\"%p\" PRED=\"%p\"/>\n", 
		     (void*) list->d, (void*) _gdsl_node_get_content (list->d), 
		     (void*) _gdsl_node_get_succ (list->d), (void*) _gdsl_node_get_pred (list->d));
	}
    else
	{
	    fprintf (file, "<GDSL_LIST_HEAD REF=\"%p\" CONTENT=\"\" SUCC=\"%p\" PRED=\"%p\"/>\n", 
		     (void*) list->d, (void*) _gdsl_node_get_succ (list->d), (void*) _gdsl_node_get_pred (list->d));
	}

    while (tmp != list->z)
	{
	    if (_gdsl_node_get_content (tmp))
		{
		    fprintf (file, "<GDSL_LIST_NODE REF=\"%p\" CONTENT=\"%p\" SUCC=\"%p\" PRED=\"%p\">", 
			     (void*) tmp, (void*) _gdsl_node_get_content (tmp),
			     (void*) _gdsl_node_get_succ (tmp), (void*) _gdsl_node_get_pred (tmp));
		}
	    else
		{
		    fprintf (file, "<GDSL_LIST_NODE REF=\"%p\" CONTENT=\"\" SUCC=\"%p\" PRED=\"%p\">", 
			     (void*) tmp, (void*) _gdsl_node_get_succ (tmp), 
			     (void*) _gdsl_node_get_pred (tmp));
		}
      
	    if (write_f != NULL && _gdsl_node_get_content (tmp))
		{
		    write_f (_gdsl_node_get_content (tmp), file, 
			     get_location (list, tmp), user_data);
		}
      
	    fprintf (file, "</GDSL_LIST_NODE>\n");

	    tmp = _gdsl_node_get_succ (tmp);
	}

    if (_gdsl_node_get_content (list->z))
	{
	    fprintf (file, "<GDSL_LIST_TAIL REF=\"%p\" CONTENT=\"%p\" PRED=\"%p\" SUCC=\"%p\"/>\n</GDSL_LIST>\n", 
		     (void*) list->z, (void*) _gdsl_node_get_content (list->z), 
		     (void*) _gdsl_node_get_pred (list->z), (void*) _gdsl_node_get_succ (list->z));
	}
    else
	{
	    fprintf (file, "<GDSL_LIST_TAIL REF=\"%p\" CONTENT=\"\" PRED=\"%p\" SUCC=\"%p\"/>\n</GDSL_LIST>\n", 
		     (void*) list->z, (void*) _gdsl_node_get_pred (list->z), 
		     (void*) _gdsl_node_get_succ (list->z));
	}
}

/******************************************************************************/
/* Cursor specific functions                                                  */
/******************************************************************************/

extern gdsl_list_cursor_t
gdsl_list_cursor_alloc (const gdsl_list_t list)
{
    gdsl_list_cursor_t c;

    assert (list != NULL);

    c = (gdsl_list_cursor_t) malloc (sizeof (struct _gdsl_list_cursor));

    if (c == NULL)
	{
	    return NULL;
	}

    c->c = _gdsl_node_get_succ (list->d);
    c->l = list;

    return c;
}

extern void
gdsl_list_cursor_free (gdsl_list_cursor_t c)
{
    assert (c != NULL);

    free (c);
}

extern void
gdsl_list_cursor_move_to_head (gdsl_list_cursor_t c)
{
    assert (c != NULL);

    c->c = _gdsl_node_get_succ (c->l->d);
}

extern void
gdsl_list_cursor_move_to_tail (gdsl_list_cursor_t c)
{
    assert (c != NULL);

    c->c = _gdsl_node_get_pred (c->l->z);
}

extern gdsl_element_t
gdsl_list_cursor_move_to_value (gdsl_list_cursor_t c, gdsl_compare_func_t comp_f, void* v)
{
    assert (c != NULL);
    assert (comp_f != NULL);

    return update_cursor (c, search_by_function (c->l, comp_f, v));
}

extern gdsl_element_t
gdsl_list_cursor_move_to_position (gdsl_list_cursor_t c, ulong pos)
{
    assert (c != NULL);
    assert (pos > 0 && pos <= c->l->card);

    return update_cursor (c, search_by_position (c->l, pos));
}

extern void
gdsl_list_cursor_step_forward (gdsl_list_cursor_t c)
{
    assert (c != NULL);

    c->c = _gdsl_node_get_succ (c->c);
}

extern void
gdsl_list_cursor_step_backward (gdsl_list_cursor_t c)
{
    assert (c != NULL);

    c->c = _gdsl_node_get_pred (c->c);
}

extern bool
gdsl_list_cursor_is_on_head (const gdsl_list_cursor_t c)
{
    assert (c != NULL);

    /* Returns FALSE if L's cursor is on l->s node */
    if (gdsl_list_is_empty (c->l))
	{
	    return FALSE;
	}

    return (bool) (c->c == _gdsl_node_get_succ (c->l->d));
}

extern bool
gdsl_list_cursor_is_on_tail (const gdsl_list_cursor_t c)
{
    assert (c != NULL);

    /* Returns FALSE if L's cursor is on l->s node */
    if (gdsl_list_is_empty (c->l))
	{
	    return FALSE;
	}

    return (bool) (c->c == _gdsl_node_get_pred (c->l->z));
}

extern bool 
gdsl_list_cursor_has_succ (const gdsl_list_cursor_t c)
{
    assert (c != NULL);

    return (bool) (_gdsl_node_get_succ (c->c) != c->l->z);
}

extern bool 
gdsl_list_cursor_has_pred (const gdsl_list_cursor_t c)
{
    assert (c != NULL);

    return (bool) (_gdsl_node_get_pred (c->c) != c->l->d);
}

extern void
gdsl_list_cursor_set_content (gdsl_list_cursor_t c, gdsl_element_t e)
{
    assert (c != NULL);

    if (c->c == c->l->d)
	{
	    return;
	}

    if (c->c == c->l->z)
	{
	    return;
	}

    _gdsl_node_set_content (c->c, e);
}

extern gdsl_element_t
gdsl_list_cursor_get_content (const gdsl_list_cursor_t c)
{
    assert (c != NULL);

    if (c->c == c->l->d)
	{
	    return NULL;
	}
    
    if (c->c == c->l->z)
	{
	    return NULL;
	}

    return _gdsl_node_get_content (c->c);
}

extern gdsl_element_t
gdsl_list_cursor_insert_after (gdsl_list_cursor_t c, void* v)
{
    gdsl_element_t e;
    _gdsl_node_t   n;

    assert (c != NULL);

    if (c->c == c->l->d)
	{
	    return NULL;
	}

    if (c->c == c->l->z)
	{
	    return NULL;
	}

    n = _gdsl_node_alloc ();

    if (n == NULL)
	{
	    return NULL;
	}

    e = c->l->alloc_func (v);

    if (e == NULL)
	{
	    _gdsl_node_free (n);
	    return NULL;
	}

    _gdsl_node_set_content (n, e);
    _gdsl_list_insert_after (n, c->c);

    c->l->card++;

    return e;
}

extern gdsl_element_t
gdsl_list_cursor_insert_before (gdsl_list_cursor_t c, void* v)
{
    gdsl_element_t e;
    _gdsl_node_t   n;

    assert (c != NULL);

    if (c->c == c->l->d)
	{
	    return NULL;
	}

    if (c->c == c->l->z)
	{
	    return NULL;
	}

    n = _gdsl_node_alloc ();

    if (n == NULL)
	{
	    return NULL;
	}

    e = c->l->alloc_func (v);

    if (e == NULL)
	{
	    _gdsl_node_free (n);
	    return NULL;
	}

    _gdsl_node_set_content (n, e);
    _gdsl_list_insert_before (n, c->c);

    c->l->card++;

    return e;
}

extern gdsl_element_t
gdsl_list_cursor_remove (gdsl_list_cursor_t c)
{
    gdsl_element_t e;
    _gdsl_node_t   tmp;

    assert (c != NULL);

    if (c->c == c->l->d)
	{
	    return NULL;
	}

    if (c->c == c->l->z)
	{
	    return NULL;
	}

    tmp = _gdsl_node_get_succ (c->c);

    _gdsl_list_remove (c->c);
    e = _gdsl_node_get_content (c->c);
    _gdsl_node_free (c->c);
    c->c = tmp;
    c->l->card--;

    return e;
}

extern gdsl_element_t
gdsl_list_cursor_remove_after (gdsl_list_cursor_t c)
{
    gdsl_element_t e;
    _gdsl_node_t   tmp;

    assert (c != NULL);

    if (c->c == c->l->d)
	{
	    return NULL;
	}

    tmp = _gdsl_node_get_succ (c->c);

    if (tmp == c->l->z)
	{
	    return NULL;
	}

    _gdsl_list_remove (tmp);
    e = _gdsl_node_get_content (tmp);
    _gdsl_node_free (tmp);

    c->l->card--;

    return e;
}

extern gdsl_element_t
gdsl_list_cursor_remove_before (gdsl_list_cursor_t c)
{
    gdsl_element_t e;
    _gdsl_node_t   tmp;

    assert (c != NULL);

    if (c->c == c->l->z)
	{
	    return NULL;
	}

    tmp = _gdsl_node_get_pred (c->c);

    if (tmp == c->l->d)
	{
	    return NULL;
	}

    _gdsl_list_remove (tmp);
    e = _gdsl_node_get_content (tmp);
    _gdsl_node_free (tmp);

    c->l->card--;

    return e;
}

extern gdsl_list_cursor_t
gdsl_list_cursor_delete (gdsl_list_cursor_t c)
{
    gdsl_element_t e;

    assert (c != NULL);

    e = gdsl_list_cursor_remove (c);

    if (e != NULL)
	{
	    c->l->free_func (e);
	    return c;
	}

    return NULL;
}

extern gdsl_list_cursor_t
gdsl_list_cursor_delete_after (gdsl_list_cursor_t c)
{
    gdsl_element_t e;

    assert (c != NULL);

    e = gdsl_list_cursor_remove_after (c);

    if (e != NULL)
	{
	    c->l->free_func (e);
	    return c;
	}

    return NULL;
}

extern gdsl_list_cursor_t
gdsl_list_cursor_delete_before (gdsl_list_cursor_t c)
{
    gdsl_element_t e;

    assert (c != NULL);

    e = gdsl_list_cursor_remove_before (c);

    if (e != NULL)
	{
	    c->l->free_func (e);
	    return c;
	}

    return NULL;
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

static _gdsl_node_t 
search_by_function (gdsl_list_t l, gdsl_compare_func_t comp_f, const void* value)
{
    _gdsl_node_t left;
    _gdsl_node_t right;

    left = _gdsl_node_get_succ (l->d);
    right = _gdsl_node_get_pred (l->z);

    while (left != _gdsl_node_get_succ (right))
	{
	    if (comp_f (_gdsl_node_get_content (left), (void*) value) == 0)
		{
		    return left;
		}
            
	    if (left == right)
		{
		    return NULL;
		}

	    if (comp_f (_gdsl_node_get_content (right), (void*) value) == 0)
		{
		    return right;
		}

	    left = _gdsl_node_get_succ (left);
	    right = _gdsl_node_get_pred (right);
	}

    return NULL;
}

static _gdsl_node_t 
search_by_position (gdsl_list_t l, ulong pos)
{
    ulong        m;
    _gdsl_node_t tmp;

    if (pos <= 0 || pos > l->card)
	{
	    return NULL;
	}

    m = (l->card / 2) + 1;

    if (pos < m)
	{
	    tmp = _gdsl_node_get_succ (l->d);

	    while (pos > 1)
		{
		    tmp = _gdsl_node_get_succ (tmp);
		    pos--;
		}
	}
    else
	{
	    pos = l->card - pos;
	    tmp = _gdsl_node_get_pred (l->z);

	    while (pos > 0)
		{
		    tmp = _gdsl_node_get_pred (tmp);
		    pos--;
		}
	}

    return tmp;
}

static gdsl_element_t 
update_cursor (gdsl_list_cursor_t c, _gdsl_node_t n)
{
    if (n == NULL) 
	{
	    return NULL;
	}

    c->c = n;

    return _gdsl_node_get_content (n);
}

static _gdsl_node_t 
sort (_gdsl_node_t u, gdsl_compare_func_t comp_f, _gdsl_node_t z)
{
    _gdsl_node_t s;
    _gdsl_node_t t;

    if (_gdsl_node_get_succ (u) == z) 
	{
	    return u;
	}

    s = u;
    t = _gdsl_node_get_succ (_gdsl_node_get_succ (_gdsl_node_get_succ (u)));
    while (t != z)
	{
	    u = _gdsl_node_get_succ (u);
	    t = _gdsl_node_get_succ (_gdsl_node_get_succ (t));
	}

    t = _gdsl_node_get_succ (u);
    _gdsl_node_set_succ (u, z);

    return merge (sort (s, comp_f, z), sort (t, comp_f, z), comp_f, z);
}

static _gdsl_node_t 
merge (_gdsl_node_t s, _gdsl_node_t t, gdsl_compare_func_t comp_f, _gdsl_node_t z)
{
    _gdsl_node_t u = z;
    
    do 
	{
#ifndef USES_MAX
	    /* 
	     * The two first tests below are not necessary if in [1]
	     * we set the max value 
	     */
	    if (t == z)
		{
		    _gdsl_node_link (u, s);
		    u = s;
		    s = _gdsl_node_get_succ (s);
		    continue;
		}

	    /* same as above for this test */
	    if (s == z)
		{
		    _gdsl_node_link (u, t);
		    u = t;
		    t = _gdsl_node_get_succ (t); 
		    continue;
		}
#endif

	    if (comp_f (_gdsl_node_get_content (s), _gdsl_node_get_content (t)) <= 0)
		{
		    _gdsl_node_link (u, s);
		    u = s;
		    s = _gdsl_node_get_succ (s);
		}
	    else
		{
		    _gdsl_node_link (u, t);
		    u = t;
		    t = _gdsl_node_get_succ (t);
		}
	} 
    while (u != z);
    
    u = _gdsl_node_get_succ (z);
    _gdsl_node_set_succ (z, z);
    
    return u;
}

static gdsl_location_t
get_location (gdsl_list_t list, _gdsl_node_t node)
{
    gdsl_location_t location = GDSL_LOCATION_UNDEF;

    if (node == _gdsl_node_get_succ (list->d))
	{
	    location |= GDSL_LOCATION_HEAD;
	}

    if (node == _gdsl_node_get_pred (list->z))
	{
	    location |= GDSL_LOCATION_TAIL;
	}

    return location;
}


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */

