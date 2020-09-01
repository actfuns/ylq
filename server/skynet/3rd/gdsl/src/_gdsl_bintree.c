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
 * $RCSfile: _gdsl_bintree.c,v $
 * $Revision: 1.21 $
 * $Date: 2006/03/04 16:32:05 $
 */


#include <config.h>


#include <stdio.h>
#include <stdlib.h>
#include <assert.h>


#include "_gdsl_bintree.h"
#include "gdsl_types.h"
#include "gdsl_macros.h"


#define LEFT(t)       ( (t)->left )
#define RIGHT(t)      ( (t)->right )
#define PARENT(t)     ( (t)->parent )
#define CONTENT(t)    ( (t)->content )


#define IS_LEAF(t)    ( LEFT(t) == NULL && RIGHT(t) == NULL )
#define IS_EMPTY(t)   ( (t) == NULL )


struct _gdsl_bintree
{
    struct _gdsl_bintree* left;    /* Tree's left sub-tree */
    struct _gdsl_bintree* right;   /* Tree's right sub-tree */
    struct _gdsl_bintree* parent;  /* Tree's parent */
    gdsl_element_t        content; /* Tree's content */
};

static void
bintree_free (_gdsl_bintree_t t);

static void
bintree_free_with_func (_gdsl_bintree_t t, gdsl_free_func_t f);

static void
bintree_write (const _gdsl_bintree_t t, 
	       const _gdsl_bintree_write_func_t write_f, FILE* file, void* d, 
	       bool dump);

/******************************************************************************/
/* Management functions of low-level binary trees                             */
/******************************************************************************/

extern _gdsl_bintree_t
_gdsl_bintree_alloc (const gdsl_element_t e, const _gdsl_bintree_t l, 
		     const _gdsl_bintree_t r)
{
    _gdsl_bintree_t t;

    t = (_gdsl_bintree_t) malloc (sizeof (struct _gdsl_bintree));

    if (t == NULL)
	{
	    return NULL;
	}
  
    t->left  = l;
    t->right = r;

    if (l != NULL)
	{
	    l->parent = t;
	}

    if (r != NULL)
	{
	    r->parent = t;
	}

    t->parent  = t;
    t->content = e;

    return t;
}

extern void 
_gdsl_bintree_free (_gdsl_bintree_t t, const gdsl_free_func_t free_f)
{
    (free_f == NULL) ? bintree_free (t) : bintree_free_with_func (t, free_f);
}

extern _gdsl_bintree_t
_gdsl_bintree_copy (const _gdsl_bintree_t t, const gdsl_copy_func_t copy_f)
{
    _gdsl_bintree_t tmp;

    assert (copy_f != NULL);

    if (IS_EMPTY (t))
	{
	    return NULL;
	}

    tmp = _gdsl_bintree_alloc (copy_f (CONTENT (t)), NULL, NULL);

    if (tmp == NULL)
	{
	    return NULL;
	}

    tmp->left = _gdsl_bintree_copy (LEFT (t), copy_f);

    if (tmp->left != NULL)
	{
	    tmp->left->parent = tmp;
	}

    tmp->right = _gdsl_bintree_copy (RIGHT (t), copy_f);

    if (tmp->right != NULL)
	{
	    tmp->right->parent = tmp;
	}

    return tmp;
}

/******************************************************************************/
/* Consultation functions of low-level binary trees                           */
/******************************************************************************/

extern bool
_gdsl_bintree_is_empty (const _gdsl_bintree_t t)
{
    return (bool) IS_EMPTY (t);
}

extern bool
_gdsl_bintree_is_leaf (const _gdsl_bintree_t t)
{
    assert (!IS_EMPTY (t));

    return (bool) IS_LEAF (t);
}

extern bool
_gdsl_bintree_is_root (const _gdsl_bintree_t t)
{
    assert (!IS_EMPTY (t));

    return (bool) (PARENT (t) == t);
}

extern gdsl_element_t
_gdsl_bintree_get_content (const _gdsl_bintree_t t)
{
    assert (!IS_EMPTY (t));

    return CONTENT (t);
}

extern _gdsl_bintree_t
_gdsl_bintree_get_parent (const _gdsl_bintree_t t)
{
    assert (!IS_EMPTY (t));

    return PARENT (t);
}

extern _gdsl_bintree_t
_gdsl_bintree_get_left (const _gdsl_bintree_t t)
{
    assert (!IS_EMPTY (t));
  
    return LEFT (t);
}

extern _gdsl_bintree_t
_gdsl_bintree_get_right (const _gdsl_bintree_t t)
{
    assert (!IS_EMPTY (t));

    return RIGHT (t);
}

extern _gdsl_bintree_t*
_gdsl_bintree_get_left_ref (const _gdsl_bintree_t t)
{
    assert (!IS_EMPTY (t));

    return &LEFT (t);
}

extern _gdsl_bintree_t*
_gdsl_bintree_get_right_ref (const _gdsl_bintree_t t)
{
    assert (!IS_EMPTY (t));

    return &RIGHT (t);
}

extern ulong
_gdsl_bintree_get_height (const _gdsl_bintree_t t)
{
    if (IS_EMPTY (t)) 
	{
	    return 0UL;
	}

    if (IS_LEAF (t))
	{
	    return 0UL;
	}

    return (ulong) (1UL 
		    + GDSL_MAX (_gdsl_bintree_get_height (LEFT (t)), 
				_gdsl_bintree_get_height (RIGHT (t))));
}

extern ulong
_gdsl_bintree_get_size (const _gdsl_bintree_t t)
{
    if (IS_EMPTY (t))
	{
	    return 0UL;
	}

    return (ulong) (1UL 
		    + _gdsl_bintree_get_size (LEFT (t)) 
		    + _gdsl_bintree_get_size (RIGHT (t)));
}

/******************************************************************************/
/* Modification functions of low-level binary trees                           */
/******************************************************************************/

extern void
_gdsl_bintree_set_content (_gdsl_bintree_t t, const gdsl_element_t e)
{
    assert (!IS_EMPTY (t));

    t->content = e;
}

extern void
_gdsl_bintree_set_parent (_gdsl_bintree_t t, const _gdsl_bintree_t p)
{
    assert (!IS_EMPTY (t));

    t->parent = p;
}

extern void
_gdsl_bintree_set_left (_gdsl_bintree_t t, const _gdsl_bintree_t l)
{
    assert (!IS_EMPTY (t));

    t->left = l;

    if (l != NULL)
	{
	    l->parent = t;
	}
}

extern void 
_gdsl_bintree_set_right (_gdsl_bintree_t t, const _gdsl_bintree_t r)
{
    assert (!IS_EMPTY (t));

    t->right = r;

    if (r != NULL)
	{
	    r->parent = t;
	}
}

/******************************************************************************/
/* Rotation functions of low-level binary trees                               */
/******************************************************************************/

extern _gdsl_bintree_t
_gdsl_bintree_rotate_left (_gdsl_bintree_t* t)
{
    _gdsl_bintree_t rn;

    assert (!IS_EMPTY (*t));
    assert (!IS_EMPTY (RIGHT (*t)));

    rn = RIGHT (*t);
    (*t)->right = LEFT (rn);

    if (LEFT (rn) != NULL)
	{
	    rn->left->parent = *t;
	}

    rn->parent = PARENT (*t);
  
    rn->left = *t;
    (*t)->parent = rn;
    *t = rn;

    return rn;
}

extern _gdsl_bintree_t
_gdsl_bintree_rotate_right (_gdsl_bintree_t* t)
{
    _gdsl_bintree_t ln;

    assert (!IS_EMPTY (*t));
    assert (!IS_EMPTY (LEFT (*t)));

    ln = LEFT (*t);
    (*t)->left = RIGHT (ln);
  
    if (RIGHT (ln) != NULL)
	{
	    ln->right->parent = *t;
	}
  
    ln->parent = PARENT (*t);
  
    ln->right = *t;
    (*t)->parent = ln;
    *t = ln;
  
    return ln;
}

extern _gdsl_bintree_t
_gdsl_bintree_rotate_left_right (_gdsl_bintree_t* t)
{
    assert (!IS_EMPTY (*t));
    assert (!IS_EMPTY (LEFT (*t)));
    assert (!IS_EMPTY (RIGHT (LEFT (*t))));

    _gdsl_bintree_rotate_left (&LEFT (*t));

    return _gdsl_bintree_rotate_right (t);
}

extern _gdsl_bintree_t
_gdsl_bintree_rotate_right_left (_gdsl_bintree_t* t)
{
    assert (!IS_EMPTY(*t));
    assert (!IS_EMPTY (RIGHT (*t)));
    assert (!IS_EMPTY (LEFT (RIGHT (*t))));

    _gdsl_bintree_rotate_right (&RIGHT (*t));

    return _gdsl_bintree_rotate_left (t);
}

/******************************************************************************/
/* Parse functions of low-level binary trees                                  */
/******************************************************************************/

extern _gdsl_bintree_t
_gdsl_bintree_map_prefix (const _gdsl_bintree_t t, 
			  const _gdsl_bintree_map_func_t map_f, void* d)
{
    assert (map_f != NULL);

    if (!IS_EMPTY (t))
	{
	    if (map_f (t, d) == GDSL_MAP_STOP)
		{
		    return t;
		}
      
	    _gdsl_bintree_map_prefix (LEFT (t), map_f, d);
	    _gdsl_bintree_map_prefix (RIGHT (t), map_f, d); 
	}
  
    return NULL;
}

extern _gdsl_bintree_t
_gdsl_bintree_map_infix (const _gdsl_bintree_t t, 
			 const _gdsl_bintree_map_func_t map_f, void* d)
{
    assert (map_f != NULL);

    if (!IS_EMPTY (t))
	{
	    _gdsl_bintree_map_infix (LEFT (t), map_f, d);
      
	    if (map_f (t, d) == GDSL_MAP_STOP) 
		{
		    return t;
		}
      
	    _gdsl_bintree_map_infix (RIGHT (t), map_f, d); 
	}
  
    return NULL;
}

extern _gdsl_bintree_t
_gdsl_bintree_map_postfix (const _gdsl_bintree_t t, 
			   const _gdsl_bintree_map_func_t map_f, void* d)
{
    assert (map_f != NULL);

    if (!IS_EMPTY (t))
	{
	    _gdsl_bintree_map_postfix (LEFT (t), map_f, d);
	    _gdsl_bintree_map_postfix (RIGHT (t), map_f, d); 
      
	    if (map_f (t, d) == GDSL_MAP_STOP) 
		{
		    return t;
		}
	}
  
    return NULL;
}

#ifdef FOR_FUTURE_USE
extern gdsl_element_t
_gdsl_bintree_level_parse (const _gdsl_bintree_t t, 
			   const _gdsl_bintree_map_func_t map_f, 
			   void* user_data)
{
    /* !!! TO DO ... */
    return NULL;
}
#endif /* FOR_FUTURE_USE */

/******************************************************************************/
/* Input/output functions of low-level binary trees                           */
/******************************************************************************/

extern void
_gdsl_bintree_write (const _gdsl_bintree_t t, 
		     const _gdsl_bintree_write_func_t write_f, 
		     FILE* file, void* user_data)
{
    assert (write_f != NULL);
    assert (file != NULL);

    if (!IS_EMPTY (t))
	{ 
	    write_f (t, file, user_data);
	    _gdsl_bintree_write (LEFT (t), write_f, file, user_data);
	    _gdsl_bintree_write (RIGHT (t), write_f, file, user_data);
	}
}

extern void
_gdsl_bintree_write_xml (const _gdsl_bintree_t t, 
			 const _gdsl_bintree_write_func_t write_f, 
			 FILE* file, void* user_data)
{
    assert (file != NULL);

    fprintf (file, "<_GDSL_BINTREE ROOT=\"%p\">\n", (void*) t);
    bintree_write (t, write_f, file, user_data, FALSE);
    fprintf (file, "</_GDSL_BINTREE>\n");
}

extern void
_gdsl_bintree_dump (const _gdsl_bintree_t t, 
		    const _gdsl_bintree_write_func_t write_f, 
		    FILE* file, void* user_data)
{
    assert (file != NULL);

    fprintf (file, "<_GDSL_BINTREE ROOT=\"%p\">\n", (void*) t);
    bintree_write (t, write_f, file, user_data, TRUE);
    fprintf (file, "</_GDSL_BINTREE>\n");
}

/******************************************************************************/
/* Private functions                                                          */
/******************************************************************************/

static void
bintree_free (_gdsl_bintree_t t)
{
    if (!IS_EMPTY (t))
	{
	    bintree_free (LEFT (t));
	    bintree_free (RIGHT (t));
	    free (t);
	}
}

static void
bintree_free_with_func (_gdsl_bintree_t t, gdsl_free_func_t free_f)
{
    if (!IS_EMPTY (t))
	{
	    bintree_free_with_func (LEFT (t), free_f);
	    bintree_free_with_func (RIGHT (t), free_f);
	    free_f (CONTENT (t));
	    free (t);
	}
}

static void
bintree_write (const _gdsl_bintree_t t, 
	       const _gdsl_bintree_write_func_t write_f, FILE* file, void* d, 
	       bool dump)
{
    if (!IS_EMPTY (t))
	{ 
	    if (IS_LEAF (t))
		{
		    fprintf (file, "<_GDSL_BINTREE_LEAF REF=\"%p\"", (void*) t);
		}
	    else
		{
		    fprintf (file, "<_GDSL_BINTREE_NODE REF=\"%p\"", (void*) t);
		}

	    if (dump == TRUE)
		{
		    if (CONTENT (t))
			{
			    fprintf (file, " CONTENT=\"%p\"",  (void*) CONTENT (t));
			}
		    else
			{
			    fprintf (file, " CONTENT=\"\"");
			}
		}

	    if (!IS_LEAF (t))
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
      
	    if (PARENT (t) != t)
		{
		    fprintf (file, " PARENT=\"%p\"", (void*) PARENT (t));
		}
	    else
		{
		    fprintf (file, " PARENT=\"\"");
		}

	    fprintf (file, ">");

	    if (write_f != NULL)
		{
		    write_f (t, file, d);
		}

	    if (IS_LEAF (t))
		{
		    fprintf (file, "</_GDSL_BINTREE_LEAF>\n");
		}
	    else
		{
		    fprintf (file, "</_GDSL_BINTREE_NODE>\n");
		}

	    bintree_write (LEFT (t), write_f, file, d, dump);
	    bintree_write (RIGHT (t), write_f , file, d, dump);
	}
}


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
