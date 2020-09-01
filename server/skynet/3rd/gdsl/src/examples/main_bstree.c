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
 * $RCSfile: main_bstree.c,v $
 * $Revision: 1.18 $
 * $Date: 2006/03/04 16:32:05 $
 */


#include <config.h>


#include <stdio.h> 
#include <string.h>
#include <stdlib.h>


#include "gdsl_perm.h"
#include "gdsl_bstree.h"
#include "_strings.h"
#include "_integers.h"


#define N 100


int main (int argc, char *argv[])
{
    int choice;
    char name[50];
    gdsl_bstree_t t = gdsl_bstree_alloc ("MY BSTREE", alloc_string, free_string, compare_strings);

    do
	{
	    printf ("\t\tMENU - BSTREE\n\n");
	    printf ("\t 1> Insert\n"); 
	    printf ("\t 2> Remove\n");
	    printf ("\t 3> Flush\n");
	    printf ("\t 4> Root content\n");
	    printf ("\t 5> Size\n");
	    printf ("\t 6> Height\n");
	    printf ("\t 7> Search\n");
	    printf ("\t 8> Display\n");
	    printf ("\t 9> XML display\n");
	    printf ("\t10> Dump\n");
	    printf ("\t11> Insertion of a random permutation\n");
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
	   
			gdsl_bstree_insert (t, (void*) name, &rc);

			if (rc == GDSL_FOUND)
			    {
				printf ("'%s' is already into the tree\n", name);
			    }
			else if (rc == GDSL_ERR_MEM_ALLOC)
			    {
				printf ("memory allocation error\n");
			    }
		    }
		    break;

		case 2:
		    if (gdsl_bstree_is_empty (t))
			{
			    printf ("The tree is empty.\n");
			}
		    else
			{
			    printf ("Enter a string: ");
			    scanf ("%s", name);
	      
			    if (gdsl_bstree_delete (t, (void *) name))
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
		    gdsl_bstree_flush (t);
		    break;

		case 4:
		    if (gdsl_bstree_is_empty (t))
			{
			    printf ("The tree is empty.\n");
			}
		    else
			{
			    print_string (gdsl_bstree_get_root (t), stdout, GDSL_LOCATION_UNDEF, " \n");
			}
		    break;
	  
		case 5:
		    printf ("Tree's size: %lu\n", gdsl_bstree_get_size (t));
		    break;

		case 6:
		    printf ("Tree's height: %lu\n", gdsl_bstree_get_height (t));
		    break;

		case 7: 
		    printf ("Enter a string: ");
		    scanf ("%s", name);
	  
		    if (gdsl_bstree_search (t, NULL, (void *) name))
			{
			    printf ("String '%s' found\n", name);
			}
		    else
			{
			    printf ("String '%s' not found\n", name);
			}
		    break;
	  
		case 8:
		    if (gdsl_bstree_is_empty (t))
			{
			    printf ("The tree is empty.\n");
			}
		    else
			{
			    printf ("Tree's content: ");
			    gdsl_bstree_write (t, print_string, stdout, NULL);
			    printf ("\n");
			}
		    break;

		case 9:
		    gdsl_bstree_write_xml (t, print_string, stdout, NULL);
		    break;

		case 10:
		    gdsl_bstree_dump (t, print_string, stdout, NULL);
		    break;
	  
		case 11:
		    {
			int i;
			int rc;
			gdsl_perm_t   p = gdsl_perm_alloc ("p", N);
			gdsl_bstree_t nt = gdsl_bstree_alloc ("INTEGERS", alloc_integer, free_integer, compare_integers);

			gdsl_perm_randomize (p);

			for (i = 0; i < N; i++)
			    {
				int n = gdsl_perm_get_element (p, i);
				gdsl_bstree_insert (nt, &n, &rc);
			    }

			printf ("Tree's height: %lu\n", gdsl_bstree_get_height (nt));
			gdsl_bstree_dump (nt, print_integer, stdout, (void*) "");

			gdsl_bstree_free (nt);
			gdsl_perm_free (p);
		    }
		    break;
		}   
	} 
    while (choice != 0);

    gdsl_bstree_free (t);

    exit (EXIT_SUCCESS);
}


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
