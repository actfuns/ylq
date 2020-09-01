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
 * $RCSfile: gdsl_rbtree.c,v $
 * $Revision: 1.24 $
 * $Date: 2006/03/04 16:32:05 $
 */


#include <config.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>


#include "gdsl_types.h"
#include "gdsl_rbtree.h"


#define LEFT(n)           ( (n)->left )
#define RIGHT(n)          ( (n)->right )
#define PARENT(n)         ( (n)->parent )
#define CONTENT(n)        ( (n)->content )
#define COLOR(n)          ( (n)->color )
#define SENT(t)           ( &(t)->sent )
#define ROOT(t)           ( (t)->sent.right )


typedef enum 
{ 
    RED, 
    BLACK 
} gdsl_rbtree_node_color_t;

struct gdsl_rbtree_node
{
    struct gdsl_rbtree_node* left;    /* node's left sub-tree */
    struct gdsl_rbtree_node* right;   /* node's right sub-tree */
    struct gdsl_rbtree_node* parent;  /* node's parent */
    gdsl_element_t           content; /* node's content */
    gdsl_rbtree_node_color_t color;   /* node's color */
};
typedef struct gdsl_rbtree_node* gdsl_rbtree_node_t;

struct gdsl_rbtree
{
    char *                  name;     /* Tree's name */
    ulong                   card;     /* Tree's cardinality */
    struct gdsl_rbtree_node sent;     /* Tree's sentinel */
    gdsl_alloc_func_t       alloc_f;  /* */
    gdsl_free_func_t        free_f;   /* */
    gdsl_compare_func_t     comp_f;   /* */
};

static gdsl_element_t 
default_alloc (void* v);

static void 
default_free (gdsl_element_t e);

static long int 
default_compare (gdsl_element_t e, void* v);

static gdsl_rbtree_node_t
rbtree_node_alloc (gdsl_rbtree_t t, gdsl_element_t e);

static void
rbtree_node_free (gdsl_rbtree_node_t n);

static void 
rbtree_destroy (gdsl_rbtree_node_t n, gdsl_rbtree_node_t sent, 
		gdsl_free_func_t f);

static ulong
rbtree_size (gdsl_rbtree_node_t n, gdsl_rbtree_node_t sent);

static ulong
rbtree_height (gdsl_rbtree_node_t n, gdsl_rbtree_node_t sent);

static gdsl_rbtree_node_t
rbtree_left_rot (gdsl_rbtree_node_t n);

static gdsl_rbtree_node_t
rbtree_right_rot (gdsl_rbtree_node_t n);

static gdsl_rbtree_node_t
rbtree_search (gdsl_rbtree_node_t n, gdsl_rbtree_node_t sent, 
	       gdsl_compare_func_t comp_f, void* v);

static gdsl_rbtree_node_t
rbtree_next (gdsl_rbtree_t t, gdsl_rbtree_node_t n);

static gdsl_element_t
rbtree_prefix_parse (gdsl_rbtree_node_t root, gdsl_rbtree_node_t sent, 
		     gdsl_map_func_t map_f, void* d);

static gdsl_element_t
rbtree_infix_parse (gdsl_rbtree_node_t root, gdsl_rbtree_node_t sent, 
		    gdsl_map_func_t map_f, void* d);

static gdsl_element_t
rbtree_postfix_parse (gdsl_rbtree_node_t root, gdsl_rbtree_node_t sent, 
		      gdsl_map_func_t map_f, void* d);

static void
rbtree_write (gdsl_rbtree_node_t n, gdsl_rbtree_node_t sent, 
	      gdsl_write_func_t map_f, FILE* file, void* d);

static void
rbtree_write_xml (gdsl_rbtree_node_t n, gdsl_rbtree_node_t sent, 
		  gdsl_write_func_t write_f, FILE* file, void* d);

static void
rbtree_dump (gdsl_rbtree_node_t n, gdsl_rbtree_node_t sent, gdsl_write_func_t f, 
	     FILE* file, void* d);

static gdsl_location_t
get_location (gdsl_rbtree_node_t n, gdsl_rbtree_node_t s);

/******************************************************************************/
/* Management functions of red-black trees                                    */
/******************************************************************************/

extern gdsl_rbtree_t
gdsl_rbtree_alloc (const char* name, gdsl_alloc_func_t alloc_f, 
		   gdsl_free_func_t free_f, gdsl_compare_func_t comp_f)
{
    gdsl_rbtree_t t;

    t = (gdsl_rbtree_t) malloc (sizeof (struct gdsl_rbtree));

    if (t == NULL)
	{
	    return NULL;
	}

    t->name = NULL;

    if (gdsl_rbtree_set_name (t, name) == NULL)
	{
	    free (t);
	    return NULL;
	}

    t->alloc_f = (alloc_f == NULL) ? default_alloc   : alloc_f;
    t->free_f  = (free_f == NULL)  ? default_free    : free_f; 
    t->comp_f  = (comp_f == NULL)  ? default_compare : comp_f;

    t->card = 0UL;

    t->sent.left   = SENT (t);
    t->sent.right  = SENT (t);
    t->sent.parent = SENT (t);
    t->sent.color  = BLACK;

    return t;
}

extern void 
gdsl_rbtree_free (gdsl_rbtree_t t)
{
    assert (t != NULL);

    rbtree_destroy (ROOT (t), SENT (t), t->free_f);
  
    if (t->name != NULL)
	{
	    free (t->name);
	}

    free (t);
}

extern void
gdsl_rbtree_flush (gdsl_rbtree_t t)
{
    assert (t != NULL);

    rbtree_destroy (ROOT (t), SENT (t), t->free_f);

    t->card = 0UL;

    t->sent.left   = SENT (t);
    t->sent.right  = SENT (t);
    t->sent.parent = SENT (t);
    t->sent.color  = BLACK;
}

#ifdef _FOR_FUTURE_USE_
extern gdsl_bstree_t
gdsl_rbtree_copy (gdsl_rbtree_t t)
{
    /* !! TO DO... !! */
    return NULL;
}
#endif

/******************************************************************************/
/* Consultation functions of red-black trees                                  */
/******************************************************************************/

extern char*
gdsl_rbtree_get_name (const gdsl_rbtree_t t)
{
    assert (t != NULL);

    return t->name;
}

extern bool
gdsl_rbtree_is_empty (const gdsl_rbtree_t t)
{
    assert (t != NULL);

    return (bool) (t->card == 0); /* alt. ROOT( t ) == SENT( t ) */
}

extern gdsl_element_t
gdsl_rbtree_get_root (const gdsl_rbtree_t t)
{
    assert (t != NULL);

    return CONTENT (ROOT (t));
}

extern ulong
gdsl_rbtree_get_size (const gdsl_rbtree_t t)
{
    assert (t != NULL);

    return t->card;
}

extern ulong
gdsl_rbtree_height (const gdsl_rbtree_t t)
{
    assert (t != NULL);

    return rbtree_height (ROOT (t), SENT (t));
}

/******************************************************************************/
/*  Modification functions of red-black trees                                 */
/******************************************************************************/

extern gdsl_rbtree_t
gdsl_rbtree_set_name (gdsl_rbtree_t t, const char *name)
{
    assert (t != NULL);

    if (t->name != NULL)
	{
	    free (t->name);
	    t->name = NULL;
	}

    if (name != NULL)
	{
	    t->name = (char*) malloc ((1 + strlen (name)) * sizeof (char));

	    if (t->name == NULL)
		{
		    return NULL;
		}

	    strcpy (t->name, name);
	}

    return t;
}

extern gdsl_element_t
gdsl_rbtree_insert (gdsl_rbtree_t t, void* v, int* rc)
{
    int                comp = 0;
    gdsl_element_t     e;
    gdsl_rbtree_node_t root;
    gdsl_rbtree_node_t parent;
    gdsl_rbtree_node_t n;

    assert (t != NULL);
    assert (rc != NULL);

    *rc = GDSL_INSERTED;

    /* First, we do a classic binary search tree insertion: */
    root = ROOT (t);
    parent = SENT (t);
    while (root != SENT (t))
	{
	    parent = root;
	    comp = t->comp_f (CONTENT (root), v);

	    /* Found v */
	    if (comp == 0)
		{
		    *rc = GDSL_FOUND;
		    return CONTENT (root);
		}

	    root = (comp > 0) ? LEFT (root) : RIGHT (root); 
	}

    /* Then, we create the new node n and we insert it into t */
    e = (t->alloc_f) (v);

    if (e == NULL)
	{
	    *rc = GDSL_ERR_MEM_ALLOC;
	    return NULL;
	}

    n = rbtree_node_alloc (t, e);

    if (n == NULL)
	{
	    t->free_f (e);
	    *rc = GDSL_ERR_MEM_ALLOC;
	    return NULL;
	}

    /* Insertion of n into t: */
    n->parent = parent;

    if (comp > 0)
	{
	    parent->left = n;
	}
    else
	{
	    parent->right = n;
	}

    t->card++;

    /* Finaly, we do red-black specific adjustments: */
    {
	gdsl_rbtree_node_t uncle = NULL;
	gdsl_rbtree_node_t gparent = NULL;

	while (COLOR (parent) == RED)
	    {
		gparent = PARENT (parent);
		if (parent == LEFT (gparent))
		    {
			uncle = RIGHT (gparent);
			if (COLOR (uncle) == RED)
			    {
				parent->color = BLACK;
				uncle->color = BLACK;
				gparent->color = RED;
				n = gparent;
				parent = PARENT (gparent);
			    }
			else
			    {
				if (n == RIGHT (parent))
				    {
					rbtree_left_rot (parent);
					parent = n;
				    }
				parent->color = BLACK;
				gparent->color = RED;
				rbtree_right_rot (gparent);
				break;
			    }
		    }
		else
		    {
			uncle = LEFT (gparent);
			if (COLOR (uncle) == RED)
			    {
				parent->color = BLACK;
				uncle->color = BLACK;
				gparent->color = RED;
				n = gparent;
				parent = PARENT (gparent);
			    }
			else
			    {
				if (n == LEFT (parent))
				    {
					rbtree_right_rot (parent);
					parent = n;
				    }
				parent->color = BLACK;
				gparent->color = RED;
				rbtree_left_rot (gparent);
			    }
		    }
	    }
    }

    t->sent.right->color = BLACK;

    return e;
}

extern gdsl_element_t
gdsl_rbtree_remove (gdsl_rbtree_t t, void* v)
{
    gdsl_element_t     e;
    gdsl_rbtree_node_t n;
    gdsl_rbtree_node_t child;
    
    assert (t != NULL);

    /* First, we search into t for a node n containing v: */
    n = rbtree_search (ROOT (t), SENT (t), t->comp_f, v);

    if (n == NULL)
	{
	    return NULL;
	}

    /* Then, we do a classical removing of a node n from a binary search tree t: */
    if (LEFT (n) != SENT (t) && RIGHT (n) != SENT (t))
	{
	    gdsl_rbtree_node_t next = rbtree_next (t, n);
	    gdsl_rbtree_node_t nextparent = PARENT (next);
	    gdsl_rbtree_node_color_t nextcolor = COLOR (next);

	    child = RIGHT (next);
	    child->parent = nextparent;

	    if (LEFT (nextparent) == next)
		{
		    nextparent->left = child;
		}
	    else
		{
		    nextparent->right = child;
		}

	    next->parent = PARENT (n);
	    next->left = LEFT (n);
	    next->right = RIGHT (n);
	    next->left->parent = next;
	    next->right->parent = next;
	    next->color = COLOR (n);
	    n->color = nextcolor;
      
	    if (LEFT (PARENT (n)) == n)
		{
		    n->parent->left = next;
		}
	    else
		{
		    n->parent->right = next;
		}
	}
    else
	{
	    child = LEFT (n) != SENT (t) ? LEFT (n) : RIGHT (n);

	    child->parent = PARENT (n);

	    if (n == LEFT (PARENT (n)))
		{
		    n->parent->left = child;
		}
	    else
		{
		    n->parent->right = child;
		}
	}

    t->card--;

    /* Finaly, we do red-black specific adjustments: */
    if (COLOR (n) == BLACK)
	{
	    gdsl_rbtree_node_t parent, sister;

	    t->sent.right->color = RED;

	    while (COLOR (child) == BLACK)
		{
		    parent = PARENT (child);
		    if (child == LEFT (parent))
			{
			    sister = RIGHT (parent);
			    if (COLOR (sister) == RED)
				{
				    sister->color = BLACK;
				    parent->color = RED;
				    rbtree_left_rot (parent);
				    sister = RIGHT (parent);
				}
			    if (COLOR (LEFT (sister)) == BLACK && COLOR (RIGHT (sister)) == BLACK)
				{
				    sister->color = RED;
				    child = parent;
				}
			    else
				{
				    if (COLOR (RIGHT (sister)) == BLACK)
					{
					    sister->left->color = BLACK;
					    sister->color = RED;
					    rbtree_right_rot (sister);
					    sister = RIGHT (parent);
					}
				    sister->color = COLOR (parent);
				    sister->right->color = BLACK;
				    parent->color = BLACK;
				    rbtree_left_rot (parent);
				    break;
				}
			}
		    else
			{
			    sister = LEFT (parent);
			    if (COLOR (sister) == RED)
				{
				    sister->color = BLACK;
				    parent->color = RED;
				    rbtree_right_rot (parent);
				    sister = LEFT (parent);
				}
			    if (COLOR (RIGHT (sister)) == BLACK && COLOR (LEFT (sister)) == BLACK)
				{
				    sister->color = RED;
				    child = parent;
				}
			    else
				{
				    if (COLOR (LEFT (sister)) == BLACK)
					{
					    sister->right->color = BLACK;
					    sister->color = RED;
					    rbtree_left_rot (sister);
					    sister = LEFT (parent);
					}
				    sister->color = COLOR (parent);
				    sister->left->color = BLACK;
				    parent->color = BLACK;
				    rbtree_right_rot (parent);
				    break;
				}
			}
		}

	    child->color = BLACK;
	    t->sent.right->color = BLACK;
	}

    e = CONTENT (n);
    rbtree_node_free (n);

    return e;
}

extern gdsl_rbtree_t
gdsl_rbtree_delete (gdsl_rbtree_t t, void* v)
{
    gdsl_element_t e;

    assert (t != NULL);

    e = gdsl_rbtree_remove (t, v);

    if (e == NULL)
	{
	    return NULL;
	}

    t->free_f (e);

    return t;
}

/******************************************************************************/
/* Search functions of red-black trees                                        */
/******************************************************************************/

extern gdsl_element_t
gdsl_rbtree_search (const gdsl_rbtree_t t, gdsl_compare_func_t comp_f, void* v)
{
    gdsl_rbtree_node_t n;

    assert (t != NULL);

    n = rbtree_search (ROOT (t), SENT (t), comp_f ? comp_f : t->comp_f, v);

    return (n == NULL) ? NULL : CONTENT (n);
}

/******************************************************************************/
/* Parse functions of red-black trees                                         */
/******************************************************************************/

extern gdsl_element_t
gdsl_rbtree_map_prefix (const gdsl_rbtree_t t, gdsl_map_func_t map_f, void* d)
{
    assert (t != NULL);
    assert (map_f != NULL);

    return rbtree_prefix_parse (ROOT (t), SENT (t), map_f, d);
}

extern gdsl_element_t
gdsl_rbtree_map_infix (const gdsl_rbtree_t t, gdsl_map_func_t map_f, void* d)
{
    assert (t != NULL);
    assert (map_f != NULL);

    return rbtree_infix_parse (ROOT (t), SENT (t), map_f, d);
}

extern gdsl_element_t
gdsl_rbtree_map_postfix (const gdsl_rbtree_t t, gdsl_map_func_t map_f, void* d)
{
    assert (t != NULL);
    assert (map_f != NULL);

    return rbtree_postfix_parse (ROOT (t), SENT (t), map_f, d);
}

/******************************************************************************/
/* Input/output functions of red-black trees                                  */
/******************************************************************************/

extern void
gdsl_rbtree_write (const gdsl_rbtree_t t, gdsl_write_func_t write_f, 
		   FILE* file, void* d)
{
    assert (t != NULL);
    assert (write_f != NULL);
    assert (file != NULL);

    rbtree_write (ROOT (t), SENT (t), write_f, file, d);
}

extern void
gdsl_rbtree_write_xml (const gdsl_rbtree_t t, gdsl_write_func_t write_f, 
		       FILE* file, void* d)
{
    assert (t != NULL);
    assert (file != NULL);

    fprintf (file, "<GDSL_RBTREE NAME=\"%s\" CARD=\"%ld\">\n", 
	     t->name, t->card);

    rbtree_write_xml (ROOT (t), SENT (t), write_f, file, d);

    fprintf (file, "</GDSL_RBTREE>\n");
}

extern void
gdsl_rbtree_dump (const gdsl_rbtree_t t, gdsl_write_func_t write_f, 
		  FILE* file, void* d)
{
    assert (t != NULL);
    assert (file != NULL);

    fprintf (file, "<GDSL_RBTREE REF=\"%p\" NAME=\"%s\" CARD=\"%ld\">\n", 
	     (void *) t, t->name, t->card);
    fprintf (file, "<GDSL_RBTREE_SENT REF=\"%p\" LEFT=\"%p\" RIGHT=\"%p\" PARENT=\"%p\"", 
	     (void *) SENT (t), (void *) t->sent.left, (void *) t->sent.right, 
	     (void *) PARENT (SENT (t)));
    fprintf (file, " COLOR=\"%s\"/>\n", COLOR (SENT (t)) == RED ? "RED" : "BLACK");

    rbtree_dump (ROOT (t), SENT (t), write_f, file, d);

    fprintf (file, "</GDSL_RBTREE>\n");
}

/******************************************************************************/
/* Private functions                                                          */
/******************************************************************************/

static gdsl_element_t 
default_alloc (void* v)
{
    return v;
}

static void 
default_free (gdsl_element_t e)
{
    ;
}

static long int 
default_compare (gdsl_element_t e, void* v)
{
    return 0;
}

static gdsl_rbtree_node_t
rbtree_node_alloc (gdsl_rbtree_t t, gdsl_element_t e)
{
    gdsl_rbtree_node_t n;

    n = (gdsl_rbtree_node_t) malloc (sizeof (struct gdsl_rbtree_node));

    if (n == NULL)
	{
	    return NULL;
	}
  
    n->left    = SENT (t);
    n->right   = SENT (t);
    n->parent  = SENT (t);
    n->content = e;
    n->color   = RED;

    return n;
}

static void
rbtree_node_free (gdsl_rbtree_node_t n)
{
    free (n);
}

static void 
rbtree_destroy (gdsl_rbtree_node_t n, gdsl_rbtree_node_t sent, gdsl_free_func_t free_f)
{
    if (n != sent)
	{
	    rbtree_destroy (LEFT (n), sent, free_f);
	    rbtree_destroy (RIGHT (n), sent, free_f);
	    free_f (CONTENT (n));
	    free (n);
	}
}

static ulong
rbtree_size (gdsl_rbtree_node_t n, gdsl_rbtree_node_t sent)
{
    if (n == sent)
	{
	    return 0UL;
	}

    return (ulong) (1UL 
		    + rbtree_size (LEFT (n), sent)
		    + rbtree_size (RIGHT (n), sent));
}

static ulong
rbtree_height (gdsl_rbtree_node_t n, gdsl_rbtree_node_t sent)
{
    if (n == sent)
	{
	    return 0UL;
	}

    if (LEFT (n) == sent && RIGHT (n) == sent)
	{
	    return 0UL;
	}

    return (ulong) (1UL + 
		    GDSL_MAX (rbtree_height (LEFT (n), sent),
			      rbtree_height (RIGHT (n), sent)));
}

static gdsl_rbtree_node_t
rbtree_left_rot (gdsl_rbtree_node_t n)
{
    gdsl_rbtree_node_t rn;

    rn = RIGHT (n);
    n->right = LEFT (rn);

    /* LEFT( rn ) is always != NULL */
    rn->left->parent = n;

    rn->parent = PARENT (n);
  
    if (n == LEFT (PARENT (n)))
	{
	    n->parent->left = rn;
	}
    else
	{
	    n->parent->right = rn;
	}

    rn->left = n;
    n->parent = rn;

    return rn;
}

static gdsl_rbtree_node_t
rbtree_right_rot (gdsl_rbtree_node_t n)
{
    gdsl_rbtree_node_t ln;

    ln = LEFT (n);
    n->left = RIGHT (ln);

    /* RIGHT( ln ) is always != NULL */
    ln->right->parent = n;

    ln->parent = PARENT (n);

    if (n == RIGHT (PARENT (n)))
	{
	    n->parent->right = ln;
	}
    else
	{
	    n->parent->left = ln;
	}

    ln->right = n;
    n->parent = ln;

    return ln;
}

static gdsl_rbtree_node_t
rbtree_search (gdsl_rbtree_node_t root, gdsl_rbtree_node_t sent, 
	       gdsl_compare_func_t f, void* v)
{
    int comp;

    while (root != sent)
	{
	    comp = f (CONTENT (root), v);

	    if (comp == 0)
		{
		    return root;
		}

	    root = (comp > 0) ? LEFT (root) : RIGHT (root);
	}

    return NULL;
}

static gdsl_rbtree_node_t
rbtree_next (gdsl_rbtree_t t, gdsl_rbtree_node_t n)
{
    n = RIGHT (n);
  
    while (LEFT (n) != SENT (t))
	{
	    n = LEFT (n);
	}

    return n;
}

static gdsl_element_t
rbtree_prefix_parse (gdsl_rbtree_node_t root, gdsl_rbtree_node_t sent, 
		     gdsl_map_func_t map_f, void* d)
{
    if (root != sent)
	{
	    gdsl_element_t e = CONTENT (root);

	    if (map_f (e, get_location (root, sent), d) == GDSL_MAP_STOP)
		{
		    return e;
		}

	    e = rbtree_prefix_parse (LEFT (root), sent, map_f, d);
	    if (e != NULL)
		{
		    return e;
		}

	    e = rbtree_prefix_parse (RIGHT (root), sent, map_f, d);
	    if (e != NULL)
		{
		    return e;
		}
	}

    return NULL;
}

static gdsl_element_t
rbtree_infix_parse (gdsl_rbtree_node_t root, gdsl_rbtree_node_t sent, 
		    gdsl_map_func_t map_f, void* d)
{
    if (root != sent)
	{
	    gdsl_element_t e;

	    e = rbtree_infix_parse (LEFT (root), sent, map_f, d);
	    if (e != NULL)
		{
		    return e;
		}

	    e = CONTENT (root);
	    if (map_f (e, get_location (root, sent), d) == GDSL_MAP_STOP)
		{
		    return e;
		}

	    e = rbtree_infix_parse (RIGHT (root), sent, map_f, d);
	    if (e != NULL)
		{
		    return e;
		}
	}

    return NULL;
}

static gdsl_element_t
rbtree_postfix_parse (gdsl_rbtree_node_t root, gdsl_rbtree_node_t sent, 
		      gdsl_map_func_t map_f, void* d)
{
    if (root != sent)
	{
	    gdsl_element_t e;

	    e = rbtree_postfix_parse (LEFT (root), sent, map_f, d);
	    if (e != NULL)
		{
		    return e;
		}

	    e = rbtree_postfix_parse (RIGHT (root), sent, map_f, d);
	    if (e != NULL)
		{
		    return e;
		}

	    e = CONTENT (root);

	    if (map_f (e, get_location (root, sent), d) == GDSL_MAP_STOP)
		{
		    return e;
		}
	}

    return NULL;
}

static void
rbtree_write (gdsl_rbtree_node_t n, gdsl_rbtree_node_t sent, 
	      gdsl_write_func_t write_f, FILE* file, void* d)
{
    if (n != sent)
	{
	    rbtree_write (LEFT (n), sent, write_f, file, d);
	    write_f (CONTENT (n), file, get_location (n, sent), d);
	    rbtree_write (RIGHT (n), sent, write_f, file, d);
	}
}

static void
rbtree_write_xml (gdsl_rbtree_node_t n, gdsl_rbtree_node_t sent, 
		  gdsl_write_func_t write_f, FILE* file, void* d)
{
    if (n != sent)
	{
	    rbtree_write_xml (LEFT (n), sent, write_f, file, d);

	    if (LEFT (n) == sent && RIGHT (n) == sent)
		{
		    fprintf (file, "<GDSL_RBTREE_LEAF REF=\"%p\"", (void *) n);
		}
	    else
		{
		    fprintf (file, "<GDSL_RBTREE_NODE REF=\"%p\"", (void *) n);
		}

	    if (LEFT (n) != sent || RIGHT (n) != sent)
		{
		    if (LEFT (n) != sent)
			{
			    fprintf (file, " LEFT=\"%p\"", (void *) LEFT (n));
			}
		    else
			{
			    fprintf (file, " LEFT=\"\"");
			}
	  
		    if (RIGHT (n) != sent)
			{
			    fprintf (file, " RIGHT=\"%p\"", (void *) RIGHT (n));
			}
		    else
			{
			    fprintf (file, " RIGHT=\"\"");
			}
		}

	    if (PARENT (n) != sent)
		{
		    fprintf (file, " PARENT=\"%p\"", (void *) PARENT (n));
		}
	    else
		{
		    fprintf (file, " PARENT=\"\"");
		}

	    fprintf (file, " COLOR=\"%s\">", COLOR (n) == RED ? "RED" : "BLACK");

	    if (write_f != NULL && CONTENT (n) != NULL)
		{
		    write_f (CONTENT (n), file, get_location (n, sent), d);
		}

	    if (LEFT (n) == sent && RIGHT (n) == sent)
		{
		    fprintf (file, "</GDSL_RBTREE_LEAF>\n");
		}
	    else
		{
		    fprintf (file, "</GDSL_RBTREE_NODE>\n");
		}

	    rbtree_write_xml (RIGHT (n), sent, write_f, file, d);
	}
}

static void
rbtree_dump (gdsl_rbtree_node_t n, gdsl_rbtree_node_t sent, gdsl_write_func_t write_f, 
	     FILE* file, void* d)
{
    if (n != sent)
	{
	    rbtree_dump (LEFT (n), sent, write_f, file, d);

	    if (LEFT (n) == sent && RIGHT (n) == sent)
		{
		    fprintf (file, "<GDSL_RBTREE_LEAF REF=\"%p\"", (void *) n);
		}
	    else
		{
		    fprintf (file, "<GDSL_RBTREE_NODE REF=\"%p\"", (void *) n);
		}

	    if (CONTENT (n))
		{
		    fprintf (file, " CONTENT=\"%p\"", (void *) CONTENT (n));
		}
	    else
		{
		    fprintf (file, " CONTENT=\"\"");
		}

	    fprintf (file, " LEFT=\"%p\" RIGHT=\"%p\"", (void *) LEFT (n), 
		     (void *) RIGHT (n));

	    if (PARENT (n))
		{
		    fprintf (file, " PARENT=\"%p\"", (void *) PARENT (n));
		}
	    else
		{
		    fprintf (file, " PARENT=\"\"");
		}

	    fprintf (file, " COLOR=\"%s\">", COLOR (n) == RED ? "RED" : "BLACK");

	    if (write_f != NULL && CONTENT (n) != NULL)
		{
		    write_f (CONTENT (n), file, get_location (n, sent), d);
		}

	    if (LEFT (n) == sent && RIGHT (n) == sent)
		{
		    fprintf (file, "</GDSL_RBTREE_LEAF>\n");
		}
	    else
		{
		    fprintf (file, "</GDSL_RBTREE_NODE>\n");
		}

	    rbtree_dump (RIGHT (n), sent, write_f, file, d);
	}
}

static gdsl_location_t
get_location (gdsl_rbtree_node_t n, gdsl_rbtree_node_t s)
{
    gdsl_location_t location = GDSL_LOCATION_UNDEF;

    if (LEFT (n) == s && RIGHT (n) == s)
	{
	    location |= GDSL_LOCATION_LEAF;
	}

    if (PARENT (n) == s)
	{
	    location |= GDSL_LOCATION_ROOT;
	}

    return location;
}


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
