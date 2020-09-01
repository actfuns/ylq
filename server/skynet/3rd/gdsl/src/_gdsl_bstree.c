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
 * $RCSfile: _gdsl_bstree.c,v $
 * $Revision: 1.30 $
 * $Date: 2006/03/04 16:32:05 $
 */


#include <config.h>


#include <stdlib.h>
#include <assert.h>


#include "gdsl_types.h"
#include "_gdsl_bstree.h"


#define LEFT(t)       ( (_gdsl_bstree_t) _gdsl_bintree_get_left ((_gdsl_bintree_t) (t)) )
#define RIGHT(t)      ( (_gdsl_bstree_t) _gdsl_bintree_get_right ((_gdsl_bintree_t) (t)) )
#define PARENT(t)     ( (_gdsl_bstree_t) _gdsl_bintree_get_parent ((_gdsl_bintree_t) (t)) )
#define CONTENT(t)    ( _gdsl_bintree_get_content ((_gdsl_bintree_t) (t)) )


#define IS_LEAF(t)    ( _gdsl_bintree_is_leaf ((_gdsl_bintree_t) t) )
#define IS_EMPTY(t)   ( _gdsl_bintree_is_empty ((_gdsl_bintree_t) t) )


static gdsl_element_t
destroy_max (_gdsl_bstree_t* t);

static gdsl_element_t
destroy_min (_gdsl_bstree_t* t);

static void
bstree_write (const _gdsl_bstree_t t, 
	      const _gdsl_bstree_write_func_t write_f, FILE* file, 
	      void* user_data, bool dump);

/******************************************************************************/
/* Management functions of low-level binary search trees                      */
/******************************************************************************/

extern _gdsl_bstree_t
_gdsl_bstree_alloc (const gdsl_element_t e)
{
    return (_gdsl_bstree_t) _gdsl_bintree_alloc (e, NULL, NULL);
}

extern void 
_gdsl_bstree_free (_gdsl_bstree_t t, const gdsl_free_func_t free_f)
{
    _gdsl_bintree_free ((_gdsl_bintree_t) t, free_f);
}

extern _gdsl_bstree_t
_gdsl_bstree_copy (const _gdsl_bstree_t t, const gdsl_copy_func_t copy_f)
{
    assert (copy_f != NULL);

    return (_gdsl_bstree_t) _gdsl_bintree_copy ((_gdsl_bintree_t) t, copy_f);
}

/******************************************************************************/
/* Consultation functions of low-level binary search trees                    */
/******************************************************************************/

extern bool
_gdsl_bstree_is_empty (const _gdsl_bstree_t t)
{
    return IS_EMPTY (t);
}

extern bool
_gdsl_bstree_is_leaf (const _gdsl_bstree_t t)
{
    assert (!IS_EMPTY (t));

    return IS_LEAF (t);
}

extern gdsl_element_t
_gdsl_bstree_get_content (const _gdsl_bstree_t t)
{
    assert (!IS_EMPTY (t));

    return CONTENT (t);
}

extern bool
_gdsl_bstree_is_root (const _gdsl_bstree_t t)
{
    assert (!IS_EMPTY (t));

    return _gdsl_bintree_is_root ((_gdsl_bintree_t) t);
}

extern _gdsl_bstree_t
_gdsl_bstree_get_parent (const _gdsl_bstree_t t)
{
    assert (!IS_EMPTY (t));

    return PARENT (t);
}

extern _gdsl_bstree_t
_gdsl_bstree_get_left (const _gdsl_bstree_t t)
{
    assert (!IS_EMPTY (t));

    return LEFT (t);
}

extern _gdsl_bstree_t
_gdsl_bstree_get_right (const _gdsl_bstree_t t)
{
    assert (!IS_EMPTY (t));

    return RIGHT (t);
}

extern ulong
_gdsl_bstree_get_size (const _gdsl_bstree_t t)
{
    return _gdsl_bintree_get_size ((_gdsl_bintree_t) t);
}

extern ulong
_gdsl_bstree_get_height (const _gdsl_bstree_t t)
{
    return _gdsl_bintree_get_height ((_gdsl_bintree_t) t);
}

/******************************************************************************/
/* Modification functions of low-level binary search trees                    */
/******************************************************************************/

extern _gdsl_bstree_t
_gdsl_bstree_insert (_gdsl_bstree_t* t, const gdsl_compare_func_t comp_f, 
		     const gdsl_element_t v, int* rc)
{
    int             comp = 0;
    _gdsl_bintree_t parent = NULL;
    _gdsl_bintree_t root = (_gdsl_bintree_t) *t;
    _gdsl_bstree_t  n = NULL;

    assert (comp_f != NULL);
    assert (rc != NULL);

    *rc = GDSL_INSERTED;

    while (!IS_EMPTY (root))
	{
	    comp = comp_f (CONTENT (root), v);

	    /* Found v */
	    if (comp == 0)
		{
		    *rc = GDSL_FOUND;
		    return root;
		}

	    parent = root;
	    root = (comp > 0) ? LEFT (root) : RIGHT (root);
	}
  
    n = (_gdsl_bstree_t) _gdsl_bintree_alloc (v, NULL, NULL);
	
    if (n == NULL)
	{
	    *rc = GDSL_ERR_MEM_ALLOC;
	    return NULL;
	}
	
    _gdsl_bintree_set_parent (n, parent);
	
    if (parent == NULL)
	{
	    *t = n;
	    return n;
	}

    if (comp > 0)
	{
	    _gdsl_bintree_set_left (parent, n);
	}
    else
	{
	    _gdsl_bintree_set_right (parent, n);
	}

    return n;
}

extern gdsl_element_t
_gdsl_bstree_remove (_gdsl_bstree_t* t, const gdsl_compare_func_t comp_f, 
		     const gdsl_element_t v)
{
    gdsl_element_t e;
    _gdsl_bstree_t l;
    _gdsl_bstree_t r;

    assert (comp_f != NULL);

    if (IS_EMPTY (*t))
	{
	    return NULL;
	}

    e = CONTENT (*t);

    {
	int comp = comp_f (v, e);
    
	if (comp < 0)
	    {
		return _gdsl_bstree_remove (_gdsl_bintree_get_left_ref (*t), comp_f, v);
	    }

	if (comp > 0)
	    {
		return _gdsl_bstree_remove (_gdsl_bintree_get_right_ref (*t), comp_f, v);
	    }
    }
  
    /* comp == 0 */
    l = LEFT (*t);
    r = RIGHT (*t);

    if (IS_EMPTY (l))
	{
	    e = CONTENT (*t);
	    free (*t);

	    if (!IS_EMPTY (r))
		{
		    _gdsl_bintree_set_parent (r, r);
		}

	    *t = r;
	    return e;
	}
 
    if (IS_EMPTY (r))
	{
	    e = CONTENT (*t);
	    free (*t);

	    if (!IS_EMPTY (l))
		{
		    _gdsl_bintree_set_parent (l, l);
		}

	    *t = l;
	    return e;
	}

    /*
     * NOTE: here, we choose to remove the max element from t's left sub-tree. But
     * there exists another alternative that consist of removing the min element
     * from t's right sub-tree. It's an arbitrary choice, but R. Sedgewick tells
     * that statistically, the first method is more efficient.
     *
     * To use the alternative:
     * _gdsl_bintree_set_content ((_gdsl_bintree_t) (*t), 
     *                           destroy_min (_gdsl_bintree_get_right_ref (*t)));
     */
    _gdsl_bintree_set_content ((_gdsl_bintree_t) (*t), 
			       destroy_max (_gdsl_bintree_get_left_ref (*t)));

    return e;
}

/******************************************************************************/
/* Search functions of low-level binary search trees                          */
/******************************************************************************/

extern _gdsl_bstree_t
_gdsl_bstree_search (const _gdsl_bstree_t t, const gdsl_compare_func_t comp_f, 
		     const gdsl_element_t v)
{
    _gdsl_bstree_t tmp = t;

    assert (comp_f != NULL);

    while (!IS_EMPTY (tmp))
	{
	    int comp = comp_f (CONTENT (tmp), v);

	    if (comp == 0)
		{
		    return tmp;
		}

	    if (comp > 0)
		{
		    tmp = LEFT (tmp);
		}
	    else
		{
		    tmp = RIGHT (tmp);
		}
	}

    return NULL;
}

extern _gdsl_bstree_t
_gdsl_bstree_search_next (const _gdsl_bstree_t t, const gdsl_compare_func_t comp_f,
			  const gdsl_element_t v)
{
    _gdsl_bstree_t b;
    _gdsl_bstree_t c;

    assert (comp_f != NULL);

    b = _gdsl_bstree_search (t, comp_f, v);

    if (IS_EMPTY (b))
	{
	    return NULL;
	}

    c = (_gdsl_bstree_t) _gdsl_bintree_get_right ((_gdsl_bintree_t) b);

    if (!IS_EMPTY (c))
	{
	    while (!IS_EMPTY (_gdsl_bintree_get_left ((_gdsl_bintree_t) c)))
		{
		    c = (_gdsl_bstree_t) _gdsl_bintree_get_left ((_gdsl_bintree_t) c);
		}

	    return c;
	}

    c = (_gdsl_bstree_t) _gdsl_bintree_get_parent ((_gdsl_bintree_t) b);

    while (b != t && (_gdsl_bstree_t) _gdsl_bintree_get_right ((_gdsl_bintree_t) c) == b)
	{
	    b = c;
	    c = (_gdsl_bstree_t) _gdsl_bintree_get_parent ((_gdsl_bintree_t) c);
	}

    if ((_gdsl_bstree_t) _gdsl_bintree_get_left ((_gdsl_bintree_t) c) == b)
	{
	    return c;
	}

    return NULL;
}

/******************************************************************************/
/* Parse functions of low-level binary search trees                           */
/******************************************************************************/

extern _gdsl_bstree_t
_gdsl_bstree_map_prefix (const _gdsl_bstree_t t, 
			 const _gdsl_bstree_map_func_t map_f, void* user_data)
{
    assert (map_f != NULL);

    if (!IS_EMPTY (t))
	{
	    if (map_f (t, user_data) == GDSL_MAP_STOP) 
		{
		    return t;
		}

	    _gdsl_bstree_map_prefix ((_gdsl_bstree_t) _gdsl_bintree_get_left ((_gdsl_bintree_t) t), map_f, user_data);
	    _gdsl_bstree_map_prefix ((_gdsl_bstree_t) _gdsl_bintree_get_right ((_gdsl_bintree_t) t), map_f, user_data); 
	}

    return NULL;
}

extern _gdsl_bstree_t
_gdsl_bstree_map_infix (const _gdsl_bstree_t t, 
			const _gdsl_bstree_map_func_t map_f, void* user_data)
{
    assert (map_f != NULL);

    if (!IS_EMPTY (t))
	{
	    _gdsl_bstree_map_infix ((_gdsl_bstree_t) _gdsl_bintree_get_left ((_gdsl_bintree_t) t), map_f, user_data);

	    if (map_f (t, user_data) == GDSL_MAP_STOP) 
		{
		    return t;
		}

	    _gdsl_bstree_map_infix ((_gdsl_bstree_t) _gdsl_bintree_get_right ((_gdsl_bintree_t) t), map_f, user_data);
	}

    return NULL;
}

extern _gdsl_bstree_t
_gdsl_bstree_map_postfix (const _gdsl_bstree_t t, 
			  const _gdsl_bstree_map_func_t map_f, void* user_data)
{
    assert (map_f != NULL);

    if (!IS_EMPTY (t))
	{
	    _gdsl_bstree_map_postfix ((_gdsl_bstree_t) _gdsl_bintree_get_left ((_gdsl_bintree_t) t), map_f, user_data);
	    _gdsl_bstree_map_postfix ((_gdsl_bstree_t) _gdsl_bintree_get_right ((_gdsl_bintree_t) t), map_f, user_data); 

	    if (map_f (t, user_data) == GDSL_MAP_STOP) 
		{
		    return t;
		}
	}

    return NULL;
}

#ifdef FOR_FUTURE_USE
extern _gdsl_bstree_t
_gdsl_bstree_level_parse (const _gdsl_bstree_t t, 
			  const _gdsl_bstree_map_func_t map_f, void* d)
{
    /* !! TO DO... !! */
    return NULL;
}
#endif /* FOR_FUTURE_USE */

/******************************************************************************/
/* Input/output functions of low-level binary search trees                    */
/******************************************************************************/

extern void
_gdsl_bstree_write (const _gdsl_bstree_t t, 
		    const _gdsl_bstree_write_func_t write_f, FILE* file, 
		    void* user_data)
{
    assert (write_f != NULL);
    assert (file != NULL);

    _gdsl_bintree_write ((_gdsl_bintree_t) t, write_f, file, user_data);
}

extern void
_gdsl_bstree_write_xml (const _gdsl_bstree_t t, 
			const _gdsl_bstree_write_func_t write_f, FILE* file, 
			void* user_data)
{
    assert (file != NULL);

    fprintf (file, "<_GDSL_BSTREE>\n");
    bstree_write (t, write_f, file, user_data, FALSE);
    fprintf (file, "</_GDSL_BSTREE>\n");
}

extern void
_gdsl_bstree_dump (const _gdsl_bstree_t t, 
		   const _gdsl_bstree_write_func_t write_f, FILE* file, 
		   void* user_data)
{
    assert (file != NULL);

    fprintf (file, "<_GDSL_BSTREE REF=\"%p\">\n", (void*) t);
    bstree_write (t, write_f, file, user_data, TRUE);
    fprintf (file, "</_GDSL_BSTREE>\n");
}

/******************************************************************************/
/* Private functions                                                          */
/******************************************************************************/

static gdsl_element_t
destroy_max (_gdsl_bstree_t* tree)
{
    if (IS_EMPTY (RIGHT (*tree)))
	{
	    gdsl_element_t max = CONTENT (*tree);
	    _gdsl_bstree_t t = LEFT (*tree);
	    free (*tree);
	    *tree = t;
	    return max;
	}

    return destroy_max (_gdsl_bintree_get_right_ref (*tree));
}

static gdsl_element_t
destroy_min (_gdsl_bstree_t* tree)
{
    if (IS_EMPTY (LEFT (*tree)))
	{
	    gdsl_element_t min = CONTENT (*tree);
	    _gdsl_bstree_t t = RIGHT (*tree);
	    free (*tree);
	    *tree = t;
	    return min;
	}
  
    return destroy_min (_gdsl_bintree_get_left_ref (*tree));
}

static void
bstree_write (const _gdsl_bstree_t t, 
	      const _gdsl_bstree_write_func_t write_f, FILE* file, 
	      void* user_data, bool dump)
{
    if (!IS_EMPTY (t))
	{ 
	    bstree_write (LEFT (t), write_f, file, user_data, dump);

	    if (IS_LEAF (t) == TRUE)
		{
		    fprintf (file, "<_GDSL_BSTREE_LEAF REF=\"%p\"", (void*) t);
		}
	    else
		{
		    fprintf (file, "<_GDSL_BSTREE_NODE REF=\"%p\"", (void*) t);
		}
      
	    if (dump == TRUE)
		{
		    if (CONTENT (t) != NULL)
			{
			    fprintf (file, " CONTENT=\"%p\"",  (void*) CONTENT (t));
			}
		    else
			{
			    fprintf (file, " CONTENT=\"\"");
			}
		}
      
	    if (IS_LEAF (t) == FALSE)
		{
		    if (LEFT (t) != NULL)
			{
			    fprintf (file, " LEFT=\"%p\"", (void*) LEFT (t));
			}
		    else
			{
			    fprintf (file, " LEFT=\"\"");
			}
      
		    if (RIGHT (t) != NULL)
			{
			    fprintf (file, " RIGHT=\"%p\"", (void*) RIGHT (t));
			}
		    else
			{
			    fprintf (file, " RIGHT=\"\"");
			}
		}
      
	    fprintf (file, " PARENT=\"%p\">", (void*) PARENT (t));

	    if (write_f != NULL)
		{
		    write_f (t, file, user_data);
		}

	    if (IS_LEAF (t) == TRUE)
		{
		    fprintf (file, "</_GDSL_BSTREE_LEAF>\n");
		}
	    else
		{
		    fprintf (file, "</_GDSL_BSTREE_NODE>\n");
		}

	    bstree_write (RIGHT (t), write_f , file, user_data, dump);
	}
}


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
