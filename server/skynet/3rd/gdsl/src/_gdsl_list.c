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
 * $RCSfile: _gdsl_list.c,v $
 * $Revision: 1.20 $
 * $Date: 2006/03/04 16:32:05 $
 */


#include <config.h>


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>


#include "_gdsl_node.h"
#include "gdsl_types.h"
#include "_gdsl_list.h"


/******************************************************************************/
/* Management functions of low-level doubly-linked lists                      */
/******************************************************************************/

extern _gdsl_list_t
_gdsl_list_alloc (const gdsl_element_t e)
{
    _gdsl_list_t list;

    list = _gdsl_node_alloc ();

    if (list == NULL)
	{
	    return NULL;
	}

    _gdsl_node_set_content (list, e);

    return list;
}

extern void 
_gdsl_list_free (_gdsl_list_t list, const gdsl_free_func_t free_f)
{
    _gdsl_node_t save;

    if (free_f != NULL)
	{
	    while (list != NULL)
		{
		    save = _gdsl_node_get_succ (list);
		    free_f (_gdsl_node_get_content (list));
		    _gdsl_node_free (list);
		    list = save;
		}

	    return;
	}

    while (list != NULL)
	{
	    save = _gdsl_node_get_succ (list);
	    _gdsl_node_free (list);
	    list = save;
	}
}

/******************************************************************************/
/* Consultation functions of low-level doubly-linked lists                    */
/******************************************************************************/

extern bool
_gdsl_list_is_empty (const _gdsl_list_t list)
{
    return (bool) (list == NULL);
}

extern ulong
_gdsl_list_get_size (const _gdsl_list_t list)
{
    ulong        card;
    _gdsl_node_t save;

    card = 0;

    for (save = list; save != NULL; save = _gdsl_node_get_succ (save))
	{
	    card++;
	}
    
    return card;
}

/******************************************************************************/
/* Modification functions of low-level doubly-linked lists                    */
/******************************************************************************/

extern void
_gdsl_list_link (_gdsl_list_t list_1, _gdsl_list_t list_2)
{
    _gdsl_node_t tmp;

    assert (list_1 != NULL);
    assert (list_2 != NULL);

    tmp = list_1;

    while (_gdsl_node_get_succ (tmp) != NULL)
	{
	    tmp = _gdsl_node_get_succ (tmp);
	}

    _gdsl_node_link (tmp, list_2);
}

extern void
_gdsl_list_insert_after (_gdsl_list_t list, _gdsl_list_t prev)
{
    _gdsl_node_t prev_succ;

    assert (list != NULL);
    assert (prev != NULL);

    prev_succ = _gdsl_node_get_succ (prev);
    _gdsl_node_link (prev, list);

    if (prev_succ != NULL)
	{
	    _gdsl_list_link (list, prev_succ);
	}
}

extern void
_gdsl_list_insert_before (_gdsl_list_t list, _gdsl_list_t succ)
{
    _gdsl_node_t prev_succ;

    assert (list != NULL);
    assert (succ != NULL);

    prev_succ = _gdsl_node_get_pred (succ);
    if (prev_succ != NULL)
	{
	    _gdsl_node_link (prev_succ, list);
	}

    _gdsl_list_link (list, succ);
}

extern void
_gdsl_list_remove (_gdsl_node_t node)
{
    _gdsl_node_t succ;
    _gdsl_node_t pred;

    assert (node != NULL);

    succ = _gdsl_node_get_succ (node);
    pred = _gdsl_node_get_pred (node);

    if (succ != NULL)
	{
	    _gdsl_node_set_pred (succ, pred);
	}

    if (pred != NULL)
	{
	    _gdsl_node_set_succ (pred, succ);
	}

    _gdsl_node_set_pred (node, NULL);
    _gdsl_node_set_succ (node, NULL);
}

/******************************************************************************/
/* Search functions of low-level doubly-linked lists                          */
/******************************************************************************/

extern _gdsl_list_t
_gdsl_list_search (const _gdsl_list_t list, const gdsl_compare_func_t comp_f, 
		   void* user_data)
{
    _gdsl_node_t tmp;

    assert (comp_f != NULL);

    for (tmp = list; tmp != NULL; tmp = _gdsl_node_get_succ (tmp))
	{
	    if (comp_f (_gdsl_node_get_content (tmp), user_data) == 0)
		{
		    return tmp;
		}
	}

    return NULL;
}

/******************************************************************************/
/* Parse functions of low-level doubly-linked lists                           */
/******************************************************************************/

extern _gdsl_list_t
_gdsl_list_map_forward (const _gdsl_list_t list, 
			const _gdsl_node_map_func_t map_f, void* user_data)
{
    _gdsl_node_t tmp;

    assert (map_f != NULL);

    for (tmp = list; tmp != NULL; tmp = _gdsl_node_get_succ (tmp))
	{
	    if (map_f (tmp, user_data) == GDSL_MAP_STOP)
		{
		    return tmp;
		}
	}

    return NULL;
}
		
extern _gdsl_list_t
_gdsl_list_map_backward (const _gdsl_list_t list, 
			 const _gdsl_node_map_func_t map_f, void* user_data)
{
    _gdsl_node_t tmp;

    assert (list != NULL);
    assert (map_f != NULL);

    /* we're first going to the end of the list */
    tmp = list;
    while (_gdsl_node_get_succ (tmp) != NULL)
	{
	    tmp = _gdsl_node_get_succ (tmp);
	}

    while (tmp != NULL)
	{
	    if (map_f (tmp, user_data) == GDSL_MAP_STOP)
		{
		    return tmp;
		}

	    tmp = _gdsl_node_get_pred (tmp);
	}

    return NULL;
}

/******************************************************************************/
/* Input/output functions of low-level doubly-linked lists                    */
/******************************************************************************/

extern void
_gdsl_list_write (const _gdsl_list_t list, 
		  const _gdsl_node_write_func_t write_f, FILE* file, 
		  void* user_data)
{
    _gdsl_node_t tmp;

    assert (write_f != NULL);
    assert (file != NULL);

    for (tmp = list; tmp != NULL; tmp = _gdsl_node_get_succ (tmp))
	{
	    _gdsl_node_write (tmp, write_f, file, user_data);
	}
}

extern void
_gdsl_list_write_xml (const _gdsl_list_t list, 
		      const _gdsl_node_write_func_t write_f, FILE* file, 
		      void* user_data)
{
    _gdsl_node_t tmp;

    assert (file != NULL);

    fprintf (file, "<_GDSL_LIST>\n");

    for (tmp = list; tmp != NULL; tmp = _gdsl_node_get_succ (tmp))
	{
	    _gdsl_node_write_xml (tmp, write_f, file, user_data);
	}

    fprintf (file, "</_GDSL_LIST>\n");
}

extern void
_gdsl_list_dump (const _gdsl_list_t list, 
		 const _gdsl_node_write_func_t write_f, FILE* file, 
		 void* user_data)
{
    _gdsl_node_t tmp;

    assert (file != NULL);

    fprintf (file, "<_GDSL_LIST REF=\"%p\">\n", (void*) list);

    for (tmp = list; tmp != NULL; tmp = _gdsl_node_get_succ (tmp))
	{
	    _gdsl_node_dump (tmp, write_f, file, user_data);
	}

    fprintf (file, "</_GDSL_LIST>\n");
}


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
