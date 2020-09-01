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
 * $RCSfile: gdsl_hash.c,v $
 * $Revision: 1.34 $
 * $Date: 2006/07/06 12:46:41 $
 */


#include <config.h>


#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#include "_gdsl_node.h"
#include "gdsl_hash.h"
#include "gdsl_list.h"


#define _GDSL_HASH_DEFAULT_HASH_SIZE    51
#define _GDSL_HASH_POW_BASE              2


struct hash_table 
{
    char*             name;
    gdsl_list_t*      lists;
    ushort            lists_count;
    ushort            lists_max_size;
    gdsl_key_func_t   key_func;
    gdsl_hash_func_t  hash_func;
    gdsl_alloc_func_t alloc_func;
    gdsl_free_func_t  free_func;
};

typedef struct hash_element 
{
    const char*    key;
    gdsl_element_t content;
} *hash_element;

typedef void* (* hash_fct_ptr_t) (void*, void*, void*);

struct infos 
{
    hash_fct_ptr_t f;
    void*          ud;
    void*          d;
    gdsl_element_t e;
};

static gdsl_element_t 
default_alloc (void* e);

static void 
default_free (gdsl_element_t e);

static const char* 
default_key (void* value);

static long int 
search_element_by_key (gdsl_element_t e, void* key);

static int 
local_map_f (gdsl_element_t e, gdsl_location_t location, void* user_data);

static void
local_write_f (gdsl_element_t e, FILE* file, gdsl_location_t location, void* user_data);

static void
local_write_xml_f (gdsl_element_t e, FILE* file, gdsl_location_t location, void* user_data);

static int 
destroy_element (gdsl_element_t e, gdsl_location_t location, void* user_infos);

/******************************************************************************/
/* Generic hash function                                                      */
/******************************************************************************/

extern ulong
gdsl_hash (const char* key)
{
    ulong hash = 0;
    char* ptr = (char*) key;

    while (*ptr != '\0')
	{
	    hash = hash * _GDSL_HASH_POW_BASE + *ptr++;
	}

    return hash;
}

/******************************************************************************/
/* Management functions of hashtables                                         */
/******************************************************************************/

extern gdsl_hash_t
gdsl_hash_alloc (const char* name, 
		 gdsl_alloc_func_t alloc_func, gdsl_free_func_t free_func, 
		 gdsl_key_func_t key_func, gdsl_hash_func_t hash_func,
		 ushort initial_size)
{
    ushort i;
    ushort j;
    gdsl_hash_t ht;
  
    ht = (gdsl_hash_t) malloc (sizeof (struct hash_table));

    if (ht == NULL)
	{
	    return NULL;
	}

    ht->name = NULL;

    if (gdsl_hash_set_name (ht, name) == NULL)
	{
	    free (ht);
	    return NULL;
	}

    ht->lists_count = (initial_size < 2) ? _GDSL_HASH_DEFAULT_HASH_SIZE : initial_size;

    ht->lists = (gdsl_list_t*) malloc (ht->lists_count * sizeof (gdsl_list_t));

    if (ht->lists == NULL)
	{
	    free (ht->name);
	    free (ht);
	    return NULL;
	}

    for (i = 0; i < ht->lists_count; i++)
	{
	    ht->lists [i] = gdsl_list_alloc (NULL, NULL, NULL);

	    if (ht->lists [i] == NULL)
		{
		    for (j = 0; j < i; j++)
			{
			    gdsl_list_free (ht->lists [j]);
			}

		    if (ht->name != NULL)
			{
			    free (ht->name);
			}

		    free (ht->lists);
		    free (ht);
		    return NULL;
		}
	}

    ht->lists_max_size = 0;

    ht->key_func   = (key_func == NULL)   ? default_key   : key_func;
    ht->hash_func  = (hash_func == NULL)  ? gdsl_hash     : hash_func;
    ht->alloc_func = (alloc_func == NULL) ? default_alloc : alloc_func;
    ht->free_func  = (free_func == NULL)  ? default_free  : free_func;

    return ht;
}

extern void
gdsl_hash_free (gdsl_hash_t ht)
{
    ushort i;
  
    for (i = 0; i < ht->lists_count; i++)
	{
	    gdsl_list_map_forward (ht->lists [i], destroy_element, (void *) ht);
	    gdsl_list_free (ht->lists [i]);
	}

    if (ht->name != NULL)
	{
	    free (ht->name);
	}

    free (ht->lists);
    free (ht);
}

extern void
gdsl_hash_flush (gdsl_hash_t ht)
{
    ushort i;
  
    for (i = 0; i < ht->lists_count; i++)
	{
	    gdsl_list_map_forward (ht->lists [i], destroy_element, (void *) ht);
	    gdsl_list_flush (ht->lists [i]);
	}
}

/******************************************************************************/
/* Consultation functions of hashtables                                       */
/******************************************************************************/

extern const char*
gdsl_hash_get_name (const gdsl_hash_t ht)
{
    return ht->name;
}

extern ushort
gdsl_hash_get_entries_number (const gdsl_hash_t ht)
{
    return ht->lists_count;
}

extern ushort
gdsl_hash_get_lists_max_size (const gdsl_hash_t ht)
{
    return ht->lists_max_size;
}

extern ushort
gdsl_hash_get_longest_list_size (const gdsl_hash_t ht)
{
    ushort i;
    ushort m = 0;

    for (i = 0; i < ht->lists_count; i++)
	{
	    if (gdsl_list_get_size (ht->lists [i]) > m)
		{
		    m = gdsl_list_get_size (ht->lists [i]);
		}
	}

    return m;
}

extern ulong
gdsl_hash_get_size (const gdsl_hash_t ht)
{
    ushort i;
    ulong  n = 0;

    for (i = 0; i < ht->lists_count; i++)
	{
	    n += gdsl_list_get_size (ht->lists [i]);
	}

    return n;
}

extern double
gdsl_hash_get_fill_factor (const gdsl_hash_t ht)
{
    return (double) gdsl_hash_get_size (ht) / (double) ht->lists_count;
}

/******************************************************************************/
/* Modification functions of hashtables                                       */
/******************************************************************************/

extern gdsl_hash_t
gdsl_hash_set_name (gdsl_hash_t ht, const char* name)
{
    if (ht->name != NULL)
	{
	    free (ht->name);
	    ht->name = NULL;
	}

    if (name != NULL)
	{
	    ht->name = (char*) malloc ((1 + strlen (name)) * sizeof (char));

	    if (ht->name == NULL)
		{
		    return NULL;
		}

	    strcpy (ht->name, name);
	}

    return ht;
}

extern gdsl_element_t
gdsl_hash_insert (gdsl_hash_t ht, void* value)
{
    ushort       indix;
    hash_element he;
    gdsl_list_t  l;

    he = (hash_element) malloc (sizeof (struct hash_element));
  
    if (he == NULL)
	{
	    return NULL;
	}
      
    he->content = ht->alloc_func (value);

    if (he->content == NULL)
	{
	    free (he);
	    return NULL;
	}

    he->key = ht->key_func (he->content);

    indix = ht->hash_func (he->key) % ht->lists_count;
    l = ht->lists [indix];

    if (ht->lists_max_size != 0 && gdsl_list_get_size (l) + 1 > ht->lists_max_size)
	{
	    /* We must re-organize the hashtable... */
	    if (gdsl_hash_modify (ht, ht->lists_count * 2 + 1, ht->lists_max_size * 2) != NULL)
		{
		    /* ... and then, insert the element classically */
		    indix = ht->hash_func (he->key) % ht->lists_count;
		    l = ht->lists [indix];
		}
	}

    if (gdsl_list_insert_head (l, he) == NULL)
	{
	    ht->free_func (he->content);
	    free (he);
	    return NULL;
	}
  
    return he->content;
}

extern gdsl_element_t
gdsl_hash_remove (gdsl_hash_t ht, const char* key)
{
    ushort         indix;
    hash_element   he;
    gdsl_element_t e;

    indix = ht->hash_func (key) % ht->lists_count;

    he = (hash_element) gdsl_list_remove (ht->lists [indix], 
					  search_element_by_key, 
					  (void *) key);

    if (he == NULL)
	{
	    return NULL;
	}

    e = he->content;
    free (he);

    return e;
}

extern gdsl_hash_t
gdsl_hash_delete (gdsl_hash_t ht, const char* key)
{
    gdsl_element_t e;

    e = gdsl_hash_remove (ht, key);

    if (e == NULL)
	{
	    return NULL;
	}

    ht->free_func (e);

    return ht;
}

extern gdsl_hash_t
gdsl_hash_modify (gdsl_hash_t ht, ushort new_size, ushort new_max_lists_size)
{
    ushort i;
    ushort j;
    gdsl_list_t* lists;

    assert (ht != NULL);

    /* First, we create a vector of new lists */
    lists = (gdsl_list_t*) malloc (new_size * sizeof (gdsl_list_t));

    if (lists == NULL)
	{
	    return NULL;
	}

    /* Second, we initialize vector elements with new lists */
    for (i = 0; i < new_size; i++)
	{
	    lists [i] = gdsl_list_alloc (NULL, NULL, NULL);

	    if (lists [i] == NULL)
		{
		    for (j = 0; j < i; j++)
			{
			    gdsl_list_free (lists [j]);
			}

		    free (lists);
		    return NULL;
		}
	}

    /* Now, we can insert in this new structure all elements of H */
    for (i = 0; i < ht->lists_count; i++)
	{
	    gdsl_list_t l = ht->lists [i];
	    gdsl_list_cursor_t c = gdsl_list_cursor_alloc (l);
	    hash_element he;

	    for (gdsl_list_cursor_move_to_head (c); (he = gdsl_list_cursor_get_content (c)); gdsl_list_cursor_step_forward (c))
		{
		    ushort indix = ht->hash_func (he->key) % new_size;
		    gdsl_list_t l2 = lists [indix];

		    if (gdsl_list_insert_head (l2, he) == NULL)
			{
			    return NULL;
			}
		}

	    gdsl_list_cursor_free (c);
	}

    /* Then, we replace the entries of H by new entries */
    for (i = 0; i < ht->lists_count; i++)
	{
	    gdsl_list_flush (ht->lists [i]);
	}
    free (ht->lists);

    ht->lists = lists;
    ht->lists_count = new_size;
    ht->lists_max_size = new_max_lists_size;

    return ht;
}

/******************************************************************************/
/* Search functions of hashtables                                             */
/******************************************************************************/

extern gdsl_element_t
gdsl_hash_search (const gdsl_hash_t ht, const char* key)
{
    ushort       indix;
    hash_element he;

    indix = ht->hash_func (key) % ht->lists_count;

    he = (hash_element) gdsl_list_search (ht->lists [indix], 
					  search_element_by_key, 
					  (void*) key);
    if (he == NULL)
	{
	    return NULL;
	}

    return he->content;
}

/******************************************************************************/
/* Parse functions of hashtables                                              */
/******************************************************************************/

extern gdsl_element_t
gdsl_hash_map (const gdsl_hash_t ht, gdsl_map_func_t f, void* user_data)
{
    ushort       i;
    struct infos infos;

    infos.f = (hash_fct_ptr_t) f;
    infos.d = user_data;
    infos.e = NULL;

    for (i = 0; i < ht->lists_count; i++)
	{
	    if (gdsl_list_get_size (ht->lists [i]) == 0)
		{
		    continue;
		}

	    if (gdsl_list_map_forward (ht->lists [i], local_map_f, 
				       (void*) &infos) != NULL)
		{
		    return infos.e;
		}
	}

    return NULL;
}

/******************************************************************************/
/* Input/output functions of hashtables                                       */
/******************************************************************************/

extern void
gdsl_hash_write (const gdsl_hash_t ht, gdsl_write_func_t f, FILE* file, 
		 void* user_data)
{
    ushort       i;
    struct infos infos;

    infos.f  = (hash_fct_ptr_t) f;
    infos.d  = (void*) file;
    infos.ud = user_data;

    for (i = 0; i < ht->lists_count; i++)
	{
	    if (gdsl_list_get_size (ht->lists [i]) != 0)
		{
		    gdsl_list_write (ht->lists [i], local_write_f, file, 
				     (void*) &infos);
		}
	}
}

extern void
gdsl_hash_write_xml (const gdsl_hash_t ht, gdsl_write_func_t f, FILE* file, 
		     void* user_data)
{
    ushort       i;
    struct infos infos;

    infos.f  = (hash_fct_ptr_t) f;
    infos.d  = (void *) file;
    infos.ud = user_data;

    fprintf (file, "<GDSL_HASH REF=\"%p\" NAME=\"%s\" SIZE=\"%ld\" ENTRIES_COUNT=\"%d\">\n", 
	     (void*) ht, ht->name == NULL ? "" : ht->name, 
	     gdsl_hash_get_size (ht), ht->lists_count);

    for (i = 0; i < ht->lists_count; i++)
	{
	    if (gdsl_list_get_size (ht->lists[i]) != 0)
		{
		    fprintf (file, "<GDSL_HASH_ENTRY VALUE=\"%d\">\n", i);
		    gdsl_list_write_xml (ht->lists [i], local_write_xml_f, file, 
					 (void*) &infos);
		    fprintf (file, "</GDSL_HASH_ENTRY>\n");
		}
	}

    fprintf (file, "</GDSL_HASH>\n");
}

extern void
gdsl_hash_dump (const gdsl_hash_t ht, gdsl_write_func_t f, FILE* file, 
		void* user_data)
{
    ushort       i;
    struct infos infos;

    infos.f  = (hash_fct_ptr_t) f;
    infos.d  = file;
    infos.ud = user_data;

    fprintf (file, "<GDSL_HASH REF=\"%p\" NAME=\"%s\" SIZE=\"%ld\" ENTRIES_COUNT=\"%d\" MAX_LISTS_SIZE=\"%d\">\n", 
	     (void*) ht, ht->name == NULL ? "" : ht->name,
	     gdsl_hash_get_size (ht), ht->lists_count, ht->lists_max_size);

    for (i = 0; i < ht->lists_count; i++)
	{
	    fprintf (file, "<GDSL_HASH_ENTRY VALUE=\"%d\">\n", i);
	    gdsl_list_dump (ht->lists [i], local_write_xml_f, file, (void*) &infos);
	    fprintf (file, "</GDSL_HASH_ENTRY>\n");
	}
  
    fprintf (file, "</GDSL_HASH>\n");
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

static const char* 
default_key (gdsl_element_t e)
{
    return (const char*) e;
}

static long int 
search_element_by_key (gdsl_element_t e, void* key)
{
    hash_element he = (hash_element) e;

    return strcmp (he->key, (const char*) key);
}

static int 
local_map_f (gdsl_element_t e, gdsl_location_t location, void* user_data)
{
    hash_element    he    = (hash_element) e;
    struct infos*   infos = (struct infos*) user_data;
    gdsl_map_func_t map   = (gdsl_map_func_t) (infos->f);

    infos->e = he->content;

    return map (he->content, GDSL_LOCATION_UNDEF, infos->d);
}

static void
local_write_f (gdsl_element_t e, FILE* file, gdsl_location_t location, void* user_data)
{
    hash_element  he        = (hash_element) e;
    struct infos* infos     = (struct infos*) user_data;
    gdsl_write_func_t write = (gdsl_write_func_t) (infos->f);

    write (he->content, file, GDSL_LOCATION_UNDEF, infos->ud);
}

static void
local_write_xml_f (gdsl_element_t e, FILE* file, gdsl_location_t location, void* user_data)
{
    hash_element  he        = (hash_element) e;
    struct infos* infos     = (struct infos*) user_data;
    gdsl_write_func_t write = (gdsl_write_func_t) (infos->f);

    fprintf (file, "\n<CONTENT KEY=\"%s\">", he->key);
    write (he->content, file, GDSL_LOCATION_UNDEF, infos->ud);
    fprintf (file, "</CONTENT>\n");
}

static int
destroy_element (gdsl_element_t e, gdsl_location_t location, void* user_infos)
{
    gdsl_hash_t  ht = (gdsl_hash_t) user_infos;
    hash_element he = (hash_element) e;

    (ht->free_func) (he->content);
    free (he);
    
    return GDSL_MAP_CONT;
}


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
