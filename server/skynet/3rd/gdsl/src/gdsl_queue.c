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
 * $RCSfile: gdsl_queue.c,v $
 * $Revision: 1.18 $
 * $Date: 2006/03/04 16:32:05 $
 */


#include <config.h>


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>


#include "_gdsl_list.h"
#include "_gdsl_node.h"
#include "gdsl_types.h"
#include "gdsl_queue.h"


struct _gdsl_queue
{
    _gdsl_node_t      d;    /* begin of the queue (sentinel) */
    _gdsl_node_t      z;    /* end of the queue (sentinel) */
    char*             name; /* name of the queue */
    ulong             card; /* Cardinality of the queue */

    gdsl_alloc_func_t alloc_f;
    gdsl_free_func_t  free_f;
};

static gdsl_element_t 
default_alloc (void* e);

static void 
default_free (gdsl_element_t e);

static _gdsl_node_t
search_by_value (gdsl_queue_t queue, gdsl_compare_func_t comp_f, void* value);

static _gdsl_node_t 
search_by_position (gdsl_queue_t queue, ulong position);

static gdsl_location_t
get_location (gdsl_queue_t queue, _gdsl_node_t node);

/******************************************************************************/
/* Management functions of queues                                             */
/******************************************************************************/

extern gdsl_queue_t
gdsl_queue_alloc (const char* name, gdsl_alloc_func_t alloc_f, 
		  gdsl_free_func_t free_f)
{
    gdsl_queue_t queue = NULL;

    queue = (gdsl_queue_t) malloc (sizeof (struct _gdsl_queue));

    if (queue == NULL)
	{
	    return NULL;
	}

    queue->d = _gdsl_node_alloc ();

    if (queue->d == NULL)
	{
	    free (queue);
	    return NULL;
	}

    queue->z = _gdsl_node_alloc ();

    if (queue->z == NULL)
	{
	    _gdsl_node_free (queue->d);
	    free (queue);
	    return NULL;
	}

    queue->name = NULL;

    if (gdsl_queue_set_name (queue, name) == NULL)
	{
	    _gdsl_node_free (queue->z);
	    _gdsl_node_free (queue->d);
	    free (queue);
	    return NULL;
	}

    queue->card = 0UL;

    _gdsl_node_link (queue->d, queue->z);
    _gdsl_node_set_succ (queue->z, queue->z);
    _gdsl_node_set_pred (queue->d, queue->d);

    queue->alloc_f = alloc_f ? alloc_f : default_alloc;
    queue->free_f  = free_f  ? free_f  : default_free;

    return queue;
}

extern void 
gdsl_queue_free (gdsl_queue_t queue)
{
    assert (queue != NULL);

    if (gdsl_queue_is_empty (queue) == FALSE)
	{
	    gdsl_queue_flush (queue);
	}

    _gdsl_node_free (queue->d);
    _gdsl_node_free (queue->z);

    if (queue->name != NULL)
	{
	    free (queue->name);
	}

    free (queue);
}

extern void
gdsl_queue_flush (gdsl_queue_t queue)
{
    _gdsl_node_t save;
    _gdsl_node_t tmp;

    assert (queue != NULL);

    tmp = _gdsl_node_get_succ (queue->d);

    while (tmp != queue->z)
	{
	    save = _gdsl_node_get_succ (tmp);
	    queue->free_f (_gdsl_node_get_content (tmp));
	    _gdsl_node_free (tmp);
	    tmp = save;
	}

    queue->card = 0UL;

    _gdsl_node_link (queue->d, queue->z);
    _gdsl_node_set_succ (queue->z, queue->z);
    _gdsl_node_set_pred (queue->d, queue->d);
}

/******************************************************************************/
/* Consultation functions of queues                                           */
/******************************************************************************/

extern const char*
gdsl_queue_get_name (const gdsl_queue_t queue)
{
    assert (queue != NULL);

    return queue->name;
}

extern ulong
gdsl_queue_get_size (const gdsl_queue_t queue)
{
    assert (queue != NULL);

    return queue->card;
}

extern bool 
gdsl_queue_is_empty (const gdsl_queue_t queue)
{
    assert (queue != NULL);

    return (bool) (_gdsl_node_get_succ (queue->d) == queue->z);
}

extern gdsl_element_t
gdsl_queue_get_head (const gdsl_queue_t queue)
{
    assert (queue != NULL);

    return _gdsl_node_get_content (_gdsl_node_get_pred (queue->z));
}

extern gdsl_element_t
gdsl_queue_get_tail (const gdsl_queue_t queue)
{
    assert (queue != NULL);

    return _gdsl_node_get_content (_gdsl_node_get_succ (queue->d));
}

/******************************************************************************/
/* Modification functions of queues                                           */
/******************************************************************************/

extern gdsl_queue_t
gdsl_queue_set_name (gdsl_queue_t queue, const char* name)
{
    assert (queue != NULL);

    if (queue->name != NULL)
	{
	    free (queue->name);
	    queue->name = NULL;
	}
  
    if (name != NULL)
	{
	    queue->name = (char*) malloc ((1 + strlen (name)) * sizeof (char));

	    if (queue->name == NULL)
		{
		    return NULL;
		}
    
	    strcpy (queue->name, name);
	}

    return queue;
}

extern gdsl_element_t
gdsl_queue_insert (gdsl_queue_t queue, void* v)
{
    gdsl_element_t    e;
    _gdsl_node_t head = NULL;

    assert (queue != NULL);

    head = _gdsl_node_alloc ();

    if (head == NULL)
	{
	    return NULL;
	}

    e = (queue->alloc_f) (v);

    if (e == NULL)
	{
	    _gdsl_node_free (head);
	    return NULL;
	}

    queue->card++;
    _gdsl_node_set_content (head, e);
  
    {
	_gdsl_node_t tmp = _gdsl_node_get_succ (queue->d);
	_gdsl_node_link (queue->d, head);
	_gdsl_node_link (head, tmp);
    }
  
    return e;
}

extern gdsl_element_t
gdsl_queue_remove (gdsl_queue_t queue)
{
    assert (queue != NULL);

    if (!gdsl_queue_is_empty (queue))
	{
	    _gdsl_node_t tail = _gdsl_node_get_pred (queue->z);
	    gdsl_element_t e = _gdsl_node_get_content (tail);

	    _gdsl_list_remove (tail);
	    _gdsl_node_free (tail);

	    queue->card--;
	    return e;
	}

    return NULL;
}

/******************************************************************************/
/* Search functions of queues                                                 */
/******************************************************************************/

extern gdsl_element_t
gdsl_queue_search (const gdsl_queue_t queue, gdsl_compare_func_t f, void* value)
{
    _gdsl_node_t n;

    assert (queue != NULL);
    assert (f != NULL);

    n = search_by_value (queue, f, value);

    return (n == NULL) ? NULL : _gdsl_node_get_content (n);
}

extern gdsl_element_t
gdsl_queue_search_by_position (const gdsl_queue_t queue, ulong pos)
{
    _gdsl_node_t n;

    assert (queue != NULL);
    assert (pos > 0 && pos <= queue->card);

    n = search_by_position (queue, pos);

    return n ? _gdsl_node_get_content (n) : NULL;
}

/******************************************************************************/
/* Parse functions of queues                                                  */
/******************************************************************************/

extern gdsl_element_t 
gdsl_queue_map_forward (const gdsl_queue_t queue, gdsl_map_func_t map_f, 
			void* user_data)
{
    gdsl_element_t e;
    _gdsl_node_t   tmp;

    assert (queue != NULL);
    assert (map_f != NULL);

    tmp = _gdsl_node_get_succ (queue->d);

    while (tmp != queue->z)
	{
	    e = _gdsl_node_get_content (tmp);

	    if (map_f (e, get_location (queue, tmp), user_data) == GDSL_MAP_STOP)
		{
		    return e;
		}

	    tmp = _gdsl_node_get_succ (tmp);
	}

    return NULL;
}

extern gdsl_element_t 
gdsl_queue_map_backward (const gdsl_queue_t queue, gdsl_map_func_t map_f, 
			 void *user_data)
{
    gdsl_element_t e;
    _gdsl_node_t   tmp;

    assert (queue != NULL);
    assert (map_f != NULL);

    tmp = _gdsl_node_get_pred (queue->z);

    while (tmp != queue->d)
	{
	    e = _gdsl_node_get_content (tmp);

	    if (map_f (e, get_location (queue, tmp), user_data) == GDSL_MAP_STOP)
		{
		    return e;
		}

	    tmp = _gdsl_node_get_pred (tmp);
	}

    return NULL;
}

/******************************************************************************/
/* Input/output functions of queues                                           */
/******************************************************************************/

extern void
gdsl_queue_write (const gdsl_queue_t queue, gdsl_write_func_t write_f, FILE *file, 
		  void *user_data)
{
    _gdsl_node_t tmp;

    assert (queue != NULL);
    assert (write_f != NULL);
    assert (file != NULL);

    tmp = _gdsl_node_get_succ (queue->d);

    while (tmp != queue->z)
	{
	    write_f (_gdsl_node_get_content (tmp), file, 
		     get_location (queue, tmp), user_data);
	    tmp = _gdsl_node_get_succ (tmp);
	}
}

extern void
gdsl_queue_write_xml (const gdsl_queue_t queue, gdsl_write_func_t write_f, FILE *file, 
		      void *user_data)
{
    _gdsl_node_t tmp;

    assert (queue != NULL);
    assert (file != NULL);

    tmp = _gdsl_node_get_succ (queue->d);

    fprintf (file, "<GDSL_QUEUE REF=\"%p\" NAME=\"%s\" CARD=\"%ld\" HEAD=\"%p\" TAIL=\"%p\">\n", 
	     (void *) queue, queue->name, queue->card, (void *) tmp, 
	     (void *) _gdsl_node_get_pred (queue->z));

    while (tmp != queue->z)
	{
	    if (tmp == _gdsl_node_get_succ (queue->d))
		{
		    fprintf (file, "<GDSL_QUEUE_NODE REF=\"%p\" CONTENT=\"%p\" SUCC=\"%p\" PRED=\"\">", 
			     (void *) tmp, (void *) _gdsl_node_get_content (tmp), 
			     (void *) _gdsl_node_get_succ (tmp));
		}
	    else if (tmp == _gdsl_node_get_pred (queue->z))
		{
		    fprintf (file, "<GDSL_QUEUE_NODE REF=\"%p\" CONTENT=\"%p\" SUCC=\"\" PRED=\"%p\">", 
			     (void *) tmp, (void *) _gdsl_node_get_content (tmp), 
			     (void *) _gdsl_node_get_pred (tmp));
		}
	    else
		{
		    fprintf (file, "<GDSL_QUEUE_NODE REF=\"%p\" CONTENT=\"%p\" SUCC=\"%p\" PRED=\"%p\">", 
			     (void *) tmp, (void *) _gdsl_node_get_content (tmp), 
			     (void *) _gdsl_node_get_succ (tmp), 
			     (void *) _gdsl_node_get_pred (tmp));
		}

	    if (write_f != NULL && _gdsl_node_get_content (tmp) != NULL)
		{
		    write_f (_gdsl_node_get_content (tmp), file, get_location (queue, tmp), user_data);
		}

	    fprintf (file, "</GDSL_QUEUE_NODE>\n");

	    tmp = _gdsl_node_get_succ (tmp);
	}

    fprintf (file, "</GDSL_QUEUE>\n");
}

extern void
gdsl_queue_dump (const gdsl_queue_t queue, gdsl_write_func_t write_f, FILE *file, 
		 void *user_data)
{
    _gdsl_node_t tmp;

    assert (queue != NULL);
    assert (file != NULL);

    tmp = _gdsl_node_get_succ (queue->d);

    fprintf (file, "<GDSL_QUEUE REF=\"%p\" NAME=\"%s\" CARD=\"%ld\" HEAD=\"%p\" TAIL=\"%p\">\n", 
	     (void *) queue, queue->name, queue->card, (void *) queue->d, (void *) queue->z);

    fprintf (file, "<GDSL_QUEUE_HEAD REF=\"%p\" SUCC=\"%p\">\n", 
	     (void *) queue->d, (void *) _gdsl_node_get_succ (queue->d));

    while (tmp != queue->z)
	{
	    if (_gdsl_node_get_content (tmp) != NULL)
		{
		    fprintf (file, "<GDSL_QUEUE_NODE REF=\"%p\" CONTENT=\"%p\" SUCC=\"%p\" PRED=\"%p\">", 
			     (void *) tmp, (void *) _gdsl_node_get_content (tmp), 
			     (void *) _gdsl_node_get_succ (tmp), 
			     (void *) _gdsl_node_get_pred (tmp));
		}
	    else
		{
		    fprintf (file, "<GDSL_QUEUE_NODE REF=\"%p\" CONTENT=\"\" SUCC=\"%p\" PRED=\"%p\">", 
			     (void *) tmp, (void *) _gdsl_node_get_succ (tmp), 
			     (void *) _gdsl_node_get_pred (tmp));
		}
      
	    if (write_f != NULL && _gdsl_node_get_content (tmp) != NULL)
		{
		    write_f (_gdsl_node_get_content (tmp), file, get_location (queue, tmp), user_data);
		}
      
	    fprintf (file, "</GDSL_QUEUE_NODE>\n");

	    tmp = _gdsl_node_get_succ (tmp);
	}

    fprintf (file, "<GDSL_QUEUE_TAIL REF=\"%p\" PRED=\"%p\">\n</GDSL_QUEUE>\n", 
	     (void *) queue->z, (void *) _gdsl_node_get_pred (queue->z));
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
search_by_value (gdsl_queue_t queue, gdsl_compare_func_t f, void* value)
{
    _gdsl_node_t left;
    _gdsl_node_t right;

    for (left = _gdsl_node_get_succ (queue->d), right = _gdsl_node_get_pred (queue->z);
	 left != _gdsl_node_get_succ (right);
	 left = _gdsl_node_get_succ (left), right = _gdsl_node_get_pred (right))
	{
	    if (f (_gdsl_node_get_content (left), value) == 0)
		{
		    return left;
		}
      
	    if (f (_gdsl_node_get_content (right), value) == 0)
		{
		    return right;
		}
      
	    if (left == right)
		{
		    return NULL;
		}
	}

    return NULL;
}

static _gdsl_node_t 
search_by_position (gdsl_queue_t queue, ulong pos)
{
    ulong        m;
    _gdsl_node_t tmp;

    if (pos <= 0 || pos > queue->card)
	{
	    return NULL;
	}

    m = (queue->card / 2) + 1;

    if (pos < m)
	{
	    tmp = _gdsl_node_get_succ (queue->d);

	    while (pos > 1)
		{
		    tmp = _gdsl_node_get_succ (tmp);
		    pos--;
		}
	}
    else
	{
	    pos = queue->card - pos;
	    tmp = _gdsl_node_get_pred (queue->z);

	    while (pos > 0)
		{
		    tmp = _gdsl_node_get_pred (tmp);
		    pos--;
		}
	}

    return tmp;
}

static gdsl_location_t
get_location (gdsl_queue_t queue, _gdsl_node_t node)
{
    gdsl_location_t location = GDSL_LOCATION_UNDEF;

    if (node == _gdsl_node_get_succ (queue->d))
	{
	    location |= GDSL_LOCATION_HEAD;
	}

    if (node == _gdsl_node_get_pred (queue->z))
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
