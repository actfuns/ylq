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
 * $RCSfile: gdsl_bstree.c,v $
 * $Revision: 1.24 $
 * $Date: 2006/03/04 16:32:05 $
 */


#include <config.h>


#include <stdlib.h>
#include <string.h>
#include <assert.h>


#include "gdsl_types.h"
#include "_gdsl_bintree.h"
#include "gdsl_bstree.h"


#define LEFT(t)       ( _gdsl_bintree_get_left ((t)) )
#define RIGHT(t)      ( _gdsl_bintree_get_right ((t)) )
#define CONTENT(t)    ( _gdsl_bintree_get_content ((t)) )
#define PARENT(t)     ( _gdsl_bintree_get_parent ((t)) )
#define SENT(t)       ( (t)->sent )
#define ROOT(t)       ( _gdsl_bintree_get_right (SENT (t)) )


struct gdsl_bstree
{
    char*               name;    /* tree's name */
    ulong               card;    /* tree's cardinality */
    _gdsl_bintree_t     sent;    /* tree's sentinel */

    gdsl_alloc_func_t   alloc_f; /* */
    gdsl_free_func_t    free_f;  /* */
    gdsl_compare_func_t comp_f;  /* */
};

static gdsl_element_t 
default_alloc (void* e);

static void 
default_free (gdsl_element_t e);

static long int 
default_comp (gdsl_element_t e, void* key);

static void 
bstree_free (_gdsl_bintree_t n, _gdsl_bintree_t sent, gdsl_free_func_t f);

static ulong
bstree_height (_gdsl_bintree_t n, _gdsl_bintree_t sent);

static _gdsl_bintree_t
bstree_search (_gdsl_bintree_t n, _gdsl_bintree_t sent, gdsl_compare_func_t f,
	       void* v );

static _gdsl_bintree_t
bstree_next (gdsl_bstree_t t, _gdsl_bintree_t n);

static gdsl_element_t
bstree_prefix_parse (_gdsl_bintree_t t, _gdsl_bintree_t sent, gdsl_map_func_t f, 
		     void* d);

static gdsl_element_t
bstree_infix_parse (_gdsl_bintree_t t, _gdsl_bintree_t sent, gdsl_map_func_t f, 
		    void* d);

static gdsl_element_t
bstree_postfix_parse (_gdsl_bintree_t t, _gdsl_bintree_t sent, gdsl_map_func_t f, 
		      void* d);

static void
bstree_write (_gdsl_bintree_t n, _gdsl_bintree_t sent, gdsl_write_func_t f,
	      FILE* file, void* d);

static void
bstree_write_xml (_gdsl_bintree_t n, _gdsl_bintree_t sent, 
		  gdsl_write_func_t f, FILE* file, void* d);
static void
bstree_dump (_gdsl_bintree_t n, _gdsl_bintree_t sent, gdsl_write_func_t f, 
	     FILE* file, void* d);

static gdsl_location_t
get_location (_gdsl_bintree_t t, _gdsl_bintree_t n);

/******************************************************************************/
/* Management functions of binary search trees                                */
/******************************************************************************/

extern gdsl_bstree_t
gdsl_bstree_alloc (const char* name, const gdsl_alloc_func_t alloc_f, 
		   gdsl_free_func_t free_f, gdsl_compare_func_t comp_f)
{
    gdsl_bstree_t t;

    t = (gdsl_bstree_t) malloc (sizeof (struct gdsl_bstree));

    if (t == NULL)
	{
	    return NULL;
	}

    t->sent = _gdsl_bintree_alloc (NULL, NULL, NULL);

    if (t->sent == NULL)
	{
	    free (t);
	    return NULL;
	}

    _gdsl_bintree_set_parent ((_gdsl_bintree_t) (t->sent), (_gdsl_bintree_t) (t->sent));
    _gdsl_bintree_set_left ((_gdsl_bintree_t) (t->sent), (_gdsl_bintree_t) (t->sent));
    _gdsl_bintree_set_right ((_gdsl_bintree_t) (t->sent), (_gdsl_bintree_t) (t->sent));

    t->name = NULL;

    if (gdsl_bstree_set_name (t, name) == NULL)
	{
	    free (t);
	    return NULL;
	}

    t->comp_f  = comp_f  ? comp_f  : default_comp;
    t->alloc_f = alloc_f ? alloc_f : default_alloc;
    t->free_f  = free_f  ? free_f  : default_free;

    t->card = 0UL;

    return t;
}

extern void
gdsl_bstree_free (gdsl_bstree_t t)
{
    assert (t != NULL);

    bstree_free (ROOT (t), SENT (t), t->free_f);

    /*
     * NOTE:
     * As SENT(t) is allocated, we must deallocate it, so we set
     * its left and right sons to NULL to avoid infinite recursion:
     */
    _gdsl_bintree_set_left ((_gdsl_bintree_t) SENT (t), NULL);
    _gdsl_bintree_set_right ((_gdsl_bintree_t) SENT (t), NULL);
    _gdsl_bintree_free (SENT (t), NULL);

    if (t->name != NULL)
	{
	    free (t->name);
	}

    free (t);
}

extern void
gdsl_bstree_flush (gdsl_bstree_t t)
{
    assert (t != NULL);

    bstree_free (ROOT (t), SENT (t), t->free_f);
    _gdsl_bintree_set_left ((_gdsl_bintree_t) SENT (t), (_gdsl_bintree_t) SENT (t));
    _gdsl_bintree_set_right ((_gdsl_bintree_t) SENT (t), (_gdsl_bintree_t) SENT (t));
    t->card = 0UL;
}

#if 0
extern gdsl_bstree_t
gdsl_bstree_copy (const gdsl_bstree_t t)
{
    /* !! TO DO... !! */
    return NULL;
}
#endif

/******************************************************************************/
/* Consultation functions of binary search trees                              */
/******************************************************************************/

extern const char*
gdsl_bstree_get_name (const gdsl_bstree_t t)
{
    assert (t != NULL);

    return t->name;
}

extern bool
gdsl_bstree_is_empty (const gdsl_bstree_t t)
{
    assert (t != NULL);

    return (bool) (t->card == 0); /* alt. ROOT( t ) == SENT( t ) */
}

extern gdsl_element_t
gdsl_bstree_get_root (const gdsl_bstree_t t)
{
    assert (t != NULL);

    return CONTENT (ROOT (t));
}

extern ulong
gdsl_bstree_get_size (const gdsl_bstree_t t)
{
    assert (t != NULL);

    return t->card;
}

extern ulong
gdsl_bstree_get_height (const gdsl_bstree_t t)
{
    assert (t != NULL);

    return bstree_height (ROOT (t), SENT (t));
}

/******************************************************************************/
/* Modification functions of binary search trees                              */
/******************************************************************************/

extern gdsl_bstree_t
gdsl_bstree_set_name (gdsl_bstree_t t, const char* name)
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
gdsl_bstree_insert (gdsl_bstree_t t, void* v, int* rc)
{
    int             comp = 0;
    gdsl_element_t  e;
    _gdsl_bintree_t root;
    _gdsl_bintree_t parent;
    _gdsl_bintree_t n;

    assert (t != NULL);
    assert (rc != NULL);

    *rc = GDSL_INSERTED;

    /* Classic binary search tree insertion */
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

    n = _gdsl_bintree_alloc (e, NULL, NULL);

    if (n == NULL)
	{
	    t->free_f (e);
	    *rc = GDSL_ERR_MEM_ALLOC;
	    return NULL;
	}

    /* Insertion of n into t */
    _gdsl_bintree_set_parent ((_gdsl_bintree_t) n, (_gdsl_bintree_t) parent);
    _gdsl_bintree_set_left ((_gdsl_bintree_t) n, (_gdsl_bintree_t) SENT (t));
    _gdsl_bintree_set_right ((_gdsl_bintree_t) n, (_gdsl_bintree_t) SENT (t));
  
    if (parent == SENT(t) || comp < 0)
	{
	    _gdsl_bintree_set_right ((_gdsl_bintree_t) parent, (_gdsl_bintree_t) n);
	}
    else
	{
	    _gdsl_bintree_set_left ((_gdsl_bintree_t) parent, (_gdsl_bintree_t) n);
	}

    t->card++;

    return e;
}

extern gdsl_element_t
gdsl_bstree_remove (gdsl_bstree_t t, void* v)
{
    gdsl_element_t e;
    _gdsl_bintree_t n;
    _gdsl_bintree_t child;

    assert (t != NULL);

    /* First we search into t for a node n containing v: */
    n = bstree_search (ROOT (t), SENT (t), t->comp_f, v);

    if (n == NULL)
	{
	    return NULL;
	}

    /* Then, we do a classical removing of node n from a binary search tree t: */
    if (LEFT (n) != SENT (t) && RIGHT (n) != SENT (t))
	{
	    _gdsl_bintree_t next = bstree_next (t, n);
	    _gdsl_bintree_t nextparent = PARENT (next);

	    child = RIGHT (next);
	    _gdsl_bintree_set_parent (child, nextparent);

	    if (LEFT (nextparent) == next)
		{
		    _gdsl_bintree_set_left (nextparent, child);
		}
	    else
		{
		    _gdsl_bintree_set_right (nextparent, child);
		}

	    _gdsl_bintree_set_parent (next, PARENT (n));
	    _gdsl_bintree_set_left (next, LEFT (n));
	    _gdsl_bintree_set_right (next, RIGHT (n));
	    _gdsl_bintree_set_parent (LEFT (next), next);
	    _gdsl_bintree_set_parent (RIGHT (next), next);
      
	    if (LEFT (PARENT (n)) == n)
		{
		    _gdsl_bintree_set_left (PARENT (n), next);
		}
	    else
		{
		    _gdsl_bintree_set_right (PARENT (n), next);
		}
	}
    else
	{
	    child = LEFT (n) != SENT (t) ? LEFT (n) : RIGHT (n);

	    _gdsl_bintree_set_parent (child, PARENT (n));

	    if (n == LEFT (PARENT (n)))
		{
		    _gdsl_bintree_set_left (PARENT (n), child);
		}
	    else
		{
		    _gdsl_bintree_set_right (PARENT (n), child);
		}
	}

    t->card--;

    e = CONTENT (n);
    _gdsl_bintree_set_left ((_gdsl_bintree_t) n, NULL);
    _gdsl_bintree_set_right ((_gdsl_bintree_t) n, NULL);
    _gdsl_bintree_free (n, NULL);

    return e;
}

extern gdsl_bstree_t
gdsl_bstree_delete (gdsl_bstree_t t, void* v)
{
    gdsl_element_t e;

    assert (t != NULL);

    e = gdsl_bstree_remove (t, v);

    if (e == NULL)
	{
	    return NULL;
	}

    t->free_f (e);

    return t;
}

/******************************************************************************/
/* Search functions of binary search trees                                    */
/******************************************************************************/

extern gdsl_element_t
gdsl_bstree_search (const gdsl_bstree_t t, gdsl_compare_func_t f, void* v)
{
    _gdsl_bintree_t n;

    assert (t != NULL);
 
    n = bstree_search (ROOT (t), SENT (t), f ? f : t->comp_f, v);

    return (n == NULL) ? NULL : CONTENT (n);
}

/******************************************************************************/
/* Parse functions of binary search trees                                     */
/******************************************************************************/

extern gdsl_element_t
gdsl_bstree_map_prefix (const gdsl_bstree_t t, gdsl_map_func_t map_f, 
			void* d)
{
    assert (t != NULL);
    assert (map_f != NULL);

    return bstree_prefix_parse (ROOT (t), SENT (t), map_f, d);
}

extern gdsl_element_t
gdsl_bstree_map_infix (const gdsl_bstree_t t, gdsl_map_func_t map_f, void* d)
{
    assert (t != NULL);
    assert (map_f != NULL);

    return bstree_infix_parse (ROOT (t), SENT (t), map_f, d);
}

extern gdsl_element_t
gdsl_bstree_map_postfix (const gdsl_bstree_t t, gdsl_map_func_t map_f, 
			 void* d)
{
    assert (t != NULL);
    assert (map_f != NULL);

    return bstree_postfix_parse (ROOT (t), SENT (t), map_f, d);
}

#if 0
extern gdsl_element_t
gdsl_bstree_level_parse (const gdsl_bstree_t t, gdsl_map_func_t map_f, void* d)
{
    assert (t != NULL);
    assert (map_f != NULL);

    /* !! TO DO... !! */
    return NULL;
}
#endif

/******************************************************************************/
/* Input/output functions of binary search trees                              */
/******************************************************************************/

extern void
gdsl_bstree_write (const gdsl_bstree_t t, gdsl_write_func_t write_f, FILE* file,
		   void* d)
{
    assert (t != NULL);
    assert (write_f != NULL);
    assert (file != NULL);

    bstree_write (ROOT (t), SENT (t), write_f, file, d);
}

extern void
gdsl_bstree_write_xml (const gdsl_bstree_t t, gdsl_write_func_t write_f, 
		       FILE* file, void* d)
{
    assert (t != NULL);
    assert (file != NULL);

    fprintf (file, "<GDSL_BSTREE REF=\"%p\" NAME=\"%s\" CARD=\"%ld\">\n",
	     (void*) t, t->name, t->card);

    bstree_write_xml (ROOT (t), SENT (t), write_f, file, d);

    fprintf (file, "</GDSL_BSTREE>\n");
}

extern void
gdsl_bstree_dump (const gdsl_bstree_t t, gdsl_write_func_t write_f, FILE* file, 
		  void* d)
{
    assert (t != NULL);
    assert (file != NULL);

    fprintf (file, "<GDSL_BSTREE REF=\"%p\" NAME=\"%s\" CARD=\"%ld\">\n",
	     (void*) t, t->name, t->card);
    fprintf (file, "<GDSL_BSTREE_SENT REF=\"%p\" LEFT=\"%p\" RIGHT=\"%p\" PARENT=\"%p\"/>\n", 
	     (void*) SENT (t), (void*) LEFT (SENT (t)), 
	     (void*) RIGHT (SENT (t)), (void*) PARENT (SENT (t)));

    bstree_dump (ROOT (t), SENT (t), write_f, file, d);

    fprintf (file, "</GDSL_BSTREE>\n");
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
bstree_free (_gdsl_bintree_t n, _gdsl_bintree_t sent, gdsl_free_func_t f)
{
    if (n != sent)
	{
	    bstree_free (LEFT (n), sent, f);
	    bstree_free (RIGHT (n), sent, f);
	    f (CONTENT (n));
	    free (n);
	}
}

static ulong
bstree_height (_gdsl_bintree_t n, _gdsl_bintree_t sent)
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
		    GDSL_MAX (bstree_height (LEFT (n), sent),
			      bstree_height (RIGHT (n), sent)));
}

static _gdsl_bintree_t
bstree_search (_gdsl_bintree_t root, _gdsl_bintree_t sent, gdsl_compare_func_t f, void* v)
{
    int comp;

    while (root != sent)
	{
	    comp = f (CONTENT (root), v);

	    if (comp == 0)
		{
		    return root;
		}

	    if (comp > 0)
		{
		    root = LEFT (root);
		}
	    else
		{
		    root = RIGHT (root);
		}
	}

    return NULL;
}

static _gdsl_bintree_t
bstree_next (gdsl_bstree_t t, _gdsl_bintree_t n)
{
    n = RIGHT (n);

    while (LEFT (n) != SENT (t))
	{
	    n = LEFT (n);
	}

    return n;
}

static gdsl_element_t
bstree_prefix_parse (_gdsl_bintree_t root, _gdsl_bintree_t sent, 
		     gdsl_map_func_t map_f, void* user_data)
{
    if (root != sent)
	{
	    gdsl_element_t e = CONTENT (root);

	    if (map_f (e, get_location (root, sent), user_data) == GDSL_MAP_STOP) 
		{
		    return e;
		}

	    bstree_prefix_parse (LEFT (root), sent, map_f, user_data);
	    bstree_prefix_parse (RIGHT (root), sent, map_f, user_data); 
	}

    return NULL;
}

static gdsl_element_t
bstree_infix_parse (_gdsl_bintree_t root, _gdsl_bintree_t sent, 
		    gdsl_map_func_t map_f, void* user_data)
{
    if (root != sent)
	{
	    gdsl_element_t e;

	    bstree_infix_parse (LEFT (root), sent, map_f, user_data);

	    e = CONTENT (root);

	    if (map_f (e, get_location (root, sent), user_data) == GDSL_MAP_STOP) 
		{
		    return e;
		}

	    bstree_infix_parse (RIGHT (root), sent, map_f, user_data);
	}

    return NULL;
}

static gdsl_element_t
bstree_postfix_parse (_gdsl_bintree_t root, _gdsl_bintree_t sent, 
		      gdsl_map_func_t map_f, void* user_data)
{
    if (root != sent)
	{
	    gdsl_element_t e;

	    bstree_postfix_parse (LEFT (root), sent, map_f, user_data);
	    bstree_postfix_parse (RIGHT (root), sent, map_f, user_data);

	    e = CONTENT (root);

	    if (map_f (e, get_location (root, sent), user_data) == GDSL_MAP_STOP) 
		{
		    return e;
		}
	}

    return NULL;
}

static void
bstree_write (_gdsl_bintree_t n, _gdsl_bintree_t sent, 
	      gdsl_write_func_t write_f, FILE* file, void* d)
{
    if (n != sent)
	{
	    bstree_write (LEFT (n), sent, write_f, file, d);
	    write_f (CONTENT (n), file, get_location (n, sent), d);
	    bstree_write (RIGHT (n), sent, write_f, file, d);
	}
}

static void
bstree_write_xml (_gdsl_bintree_t n, _gdsl_bintree_t sent, 
		  gdsl_write_func_t write_f, FILE* file, void* d)
{
    if (n != sent)
	{
	    bstree_write_xml (LEFT (n), sent, write_f, file, d);

	    if (LEFT (n) == sent && RIGHT (n) == sent)
		{
		    fprintf (file, "<GDSL_BSTREE_LEAF REF=\"%p\"", (void*) n);
		}
	    else
		{
		    fprintf (file, "<GDSL_BSTREE_NODE REF=\"%p\"", (void*) n);
		}

	    if (LEFT (n) != sent || RIGHT (n) != sent)
		{
		    if (LEFT (n) != sent)
			{
			    fprintf (file, " LEFT=\"%p\"", (void*) LEFT (n));
			}
		    else
			{
			    fprintf (file, " LEFT=\"\"");
			}
	  
		    if (RIGHT (n) != sent)
			{
			    fprintf (file, " RIGHT=\"%p\"", (void*) RIGHT (n));
			}
		    else
			{
			    fprintf (file, " RIGHT=\"\"");
			}
		}

	    if (PARENT (n) != sent)
		{
		    fprintf (file, " PARENT=\"%p\">", (void*) PARENT (n));
		}
	    else
		{
		    fprintf (file, " PARENT=\"\">");
		}

	    if (write_f != NULL)
		{
		    write_f (CONTENT (n), file, get_location (n, sent), d);
		}

	    if (LEFT (n) == sent && RIGHT (n) == sent)
		{
		    fprintf (file, "</GDSL_BSTREE_LEAF>\n");
		}
	    else
		{
		    fprintf (file, "</GDSL_BSTREE_NODE>\n");
		}

	    bstree_write_xml (RIGHT (n), sent, write_f, file, d);
	}
}

static void
bstree_dump (_gdsl_bintree_t n, _gdsl_bintree_t sent, 
	     gdsl_write_func_t write_f, FILE* file, void* d)
{
    if (n != sent)
	{
	    bstree_dump (LEFT (n), sent, write_f, file, d);

	    if (LEFT (n) == sent && RIGHT (n) == sent)
		{
		    fprintf (file, "<GDSL_BSTREE_LEAF REF=\"%p\"", (void*) n);
		}
	    else
		{
		    fprintf (file, "<GDSL_BSTREE_NODE REF=\"%p\"", (void*) n);
		}

	    if (CONTENT (n) != NULL)
		{
		    fprintf (file, " CONTENT=\"%p\"", (void*) CONTENT (n));
		}
	    else
		{
		    fprintf (file, " CONTENT=\"\"");
		}

	    fprintf (file, " LEFT=\"%p\" RIGHT=\"%p\"", (void*) LEFT (n), (void*) RIGHT (n));

	    if (PARENT (n) != NULL)
		{
		    fprintf (file, " PARENT=\"%p\">", (void*) PARENT (n));
		}
	    else
		{
		    fprintf (file, " PARENT=\"\">");
		}

	    if (write_f != NULL)
		{
		    write_f (CONTENT (n), file, get_location (n, sent), d);
		}

	    if (LEFT (n) == sent && RIGHT (n) == sent)
		{
		    fprintf (file, "</GDSL_BSTREE_LEAF>\n");
		}
	    else
		{
		    fprintf (file, "</GDSL_BSTREE_NODE>\n");
		}

	    bstree_dump (RIGHT (n), sent, write_f, file, d);
	}
}

static gdsl_location_t
get_location (_gdsl_bintree_t n, _gdsl_bintree_t s)
{
    gdsl_location_t location = GDSL_LOCATION_UNDEF;

    if (PARENT (n) == s)
	{
	    location |= GDSL_LOCATION_ROOT;
	}

    if (LEFT (n) == s && RIGHT (n) == s)
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
