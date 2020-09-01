/*
 * This file is part of Generic Data Structures Library (GDSL).
 * Copyright (C) 1998-2006 Nicolas Darnis <ndarnis@free.fr>
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
 * 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA.
 *
 * $RCSfile: main_rbtree.c,v $
 * $Revision: 1.18 $
 * $Date: 2006/03/04 16:32:05 $
 */


#include <config.h>


#include <stdio.h> 
#include <string.h>
#include <stdlib.h>


#include "gdsl_perm.h"
#include "gdsl_types.h"
#include "gdsl_rbtree.h"
#include "_strings.h"
#include "_integers.h"


#define N 100

static int
infix_map_f (const gdsl_element_t e,
	     gdsl_location_t location,
	     void* user_data)
{
    printf ("%s ", (char*) e);
    if (strcmp ((char*) e, "STOP") == 0) return GDSL_MAP_STOP;
    return GDSL_MAP_CONT;
}

int main (void)
{
    int choice;
    char name[50];
    gdsl_rbtree_t t = gdsl_rbtree_alloc ("STRINGS", alloc_string, free_string, compare_strings);

    do
	{
	    printf ("\t\tMENU - RBTREE\n\n");
	    printf ("\t 1> Insert\n"); 
	    printf ("\t 2> Remove\n");
	    printf ("\t 3> Flush\n");
	    printf ("\t 4> Root's content\n");
	    printf ("\t 5> Size\n");
	    printf ("\t 6> Height\n");
	    printf ("\t 7> Search\n");
	    printf ("\t 8> Display\n");
	    printf ("\t 9> XML display\n");
	    printf ("\t10> Dump\n");
	    printf ("\t11> Insertion of a random permutation\n");
	    printf ("\t12> Prefix parse (stop if 'STOP' is found as a value)\n");
	    printf ("\t13> Infix parse (stop if 'STOP' is found as a value)\n");
	    printf ("\t14> Postfix parse (stop if 'STOP' is found as a value)\n");
	    printf ("\t 0> Quit\n\n");
	    printf ("\t\tYour choice: ");
	    scanf ("%d", &choice);
      
	    switch (choice)
		{
		case 1:
		    {
			int rc;

			printf ("Enter a string: ");
			scanf ("%s", name);
	    
			gdsl_rbtree_insert (t, (void *) name, &rc);
	    
			if (rc == GDSL_FOUND)
			    {
				printf ("'%s' is already into the tree\n", name);
			    }

			if (rc == GDSL_ERR_MEM_ALLOC)
			    {
				printf ("memory allocation error\n");
			    }
		    }
		    break;

		case 2:
		    if (gdsl_rbtree_is_empty (t))
			{
			    printf ("The tree is empty\n");
			}
		    else
			{
			    printf ("Enter a string: ");
			    scanf ("%s", name);

			    if (gdsl_rbtree_delete (t, (void*) name)) 
				{
				    printf ("String '%s' removed from the tree\n", name);
				}
			    else
				{
				    printf ("String '%s' not found\n", name);
				}
			}
		    break;

		case 3:
		    gdsl_rbtree_flush (t);
		    break;

		case 4:
		    if (gdsl_rbtree_is_empty (t))
			{
			    printf ("The tree is empty\n");
			}
		    else
			{
			    print_string ((char*) gdsl_rbtree_get_root (t), stdout, GDSL_LOCATION_ROOT, (void*) "\n");
			}
		    break;

		case 5:
		    printf ("Tree's size: %lu\n", gdsl_rbtree_get_size (t));
		    break;

		case 6:
		    printf ("Tree's height: %lu\n", gdsl_rbtree_height (t));
		    break;

		case 7: 
		    printf( "Enter a string: " );
		    scanf( "%s", name );
	  
		    if (gdsl_rbtree_search (t, NULL, (void*) name))
			{
			    printf ("String '%s' found\n", name);
			}
		    else
			{
			    printf ("String '%s' not found\n", name);
			}
		    break;
	  
		case 8:
		    if (gdsl_rbtree_is_empty (t))
			{
			    printf ("The tree is empty\n");
			}
		    else
			{
			    printf ("Tree's content: ");
			    gdsl_rbtree_write (t, print_string, stdout, (void*) " ");
			    printf ("\n");
			}
		    break;

		case 9:
		    gdsl_rbtree_write_xml (t, print_string, stdout, NULL);
		    break;

		case 10:
		    gdsl_rbtree_dump (t, print_string, stdout, NULL);
		    break;

		case 11:
		    {
			int i;
			int rc;
			gdsl_perm_t   p = gdsl_perm_alloc ("p", N);
			gdsl_rbtree_t nt = gdsl_rbtree_alloc ("INTEGERS", alloc_integer, free_integer, compare_integers);

			gdsl_perm_randomize (p);

			for (i = 0; i < N; i++)
			    {
				int n = gdsl_perm_get_element (p, i);
				gdsl_rbtree_insert (nt, &n, &rc);
			    }

			printf ("Tree's height: %lu\n", gdsl_rbtree_height (nt));
			gdsl_rbtree_dump (nt, print_integer, stdout, "");

			gdsl_rbtree_free (nt);
			gdsl_perm_free (p);
		    }
		    break;

		case 12:
		    gdsl_rbtree_map_prefix (t, infix_map_f, NULL);
		    break;

		case 13:
		    gdsl_rbtree_map_infix (t, infix_map_f, NULL);
		    break;

		case 14:
		    gdsl_rbtree_map_postfix (t, infix_map_f, NULL);
		    break;
		}   
	} 
    while (choice != 0);

    gdsl_rbtree_free (t);
 
    exit (EXIT_SUCCESS);
}


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
