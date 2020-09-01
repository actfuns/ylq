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
 * $RCSfile: main_list.c,v $
 * $Revision: 1.18 $
 * $Date: 2006/03/04 16:32:05 $
 */


#include <config.h>


#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#include "gdsl_perm.h"
#include "gdsl_types.h"
#include "gdsl_list.h"
#include "_strings.h"
#include "_integers.h"


#define PERMUTATION_NB 26


static void 
affiche_liste_chaines_fwd (gdsl_list_t l)
{
    gdsl_element_t e;
    gdsl_list_cursor_t c = gdsl_list_cursor_alloc (l);

    printf ("%s (->) = ( ", gdsl_list_get_name (l));

    for (gdsl_list_cursor_move_to_head (c); (e = gdsl_list_cursor_get_content (c)); gdsl_list_cursor_step_forward (c))
	{
	    print_string (e, stdout, GDSL_LOCATION_UNDEF, (void*) " ");
	}

    printf (")\n");

    gdsl_list_cursor_free (c);
}

static int 
my_display_string (gdsl_element_t e, gdsl_location_t location, void* d)
{
    print_string (e, stdout, location, d);
    return GDSL_MAP_CONT;
}

static void 
affiche_liste_chaines_bwd (gdsl_list_t l)
{
    printf ("%s (<-) = ( ", gdsl_list_get_name (l));

    gdsl_list_map_backward (l, my_display_string, (void*) " ");

    printf (")\n");
}

int main (void)
{
    int choix = 0;

    gdsl_list_t l = gdsl_list_alloc ("MY LIST", alloc_string, free_string);

    do
	{
	    printf ("\t\tMENU - LIST\n\n");
	    printf ("\t 1> Create a cell\n");
	    printf ("\t 2> Remove the first cell\n");
	    printf ("\t 3> Remove the last cell\n");
	    printf ("\t 4> Remove a cell\n");
	    printf ("\t 5> Display list in forward order\n");
	    printf ("\t 6> Display list in backward order\n");
	    printf ("\t 7> Flush list\n");
	    printf ("\t 8> Size of list\n");
	    printf ("\t 9> Dump list\n");
	    printf ("\t10> XML dump of list\n");
	    printf ("\t11> Search for a place\n");
	    printf ("\t12> Search for an element\n");
	    printf ("\t13> Sort of list\n");
	    printf ("\t14> Greatest element of list\n");
	    printf ("\t 0> Quit\n\n");
	    printf ("\t\tYour choice: ");
	    scanf ("%d", &choix);

	    switch (choix)
		{
		case 1:
		    {
			char nom[100];
			int done = 0;

			printf ("Nom: ");
			scanf ("%s", nom);

			do
			    {
				int choix;

				printf ("\t\tMENU - CELL INSERTION\n\n");
				printf ("\t1> Insert cell at the beginning of the list\n");
				printf ("\t2> Insert cell at end of list\n");
				printf ("\t3> Insert cell after another cell\n");
				printf ("\t4> Insert cell before another cell\n");
				printf ("\t5> Display the list\n");
				printf ("\t0> RETURN TO MAIN MENU\n\n");
				printf ("\t\tYour choice: ");
				scanf ("%d", &choix );

				switch (choix)
				    {
				    case 1:
					{
					    gdsl_list_insert_head (l, nom);
					    done = 1;
					}
					break;

				    case 2:
					{
					    gdsl_list_insert_tail (l, nom);
					    done = 1;
					}
					break;

				    case 3:
					if (gdsl_list_is_empty (l))
					    {
						printf ("The list is empty.\n");
					    }
					else
					    {
						char Nom[100];
						gdsl_list_cursor_t c = gdsl_list_cursor_alloc (l);

						printf ("Name of cell after which you want to insert: ");
						scanf ("%s", Nom);
			
						if (!gdsl_list_cursor_move_to_value (c, compare_strings, Nom))
						    {
							printf ("The cell '%s' doesn't exist\n", Nom);
						    }
						else
						    {
							gdsl_list_cursor_insert_after (c, nom);
							done = 1;
						    }
						gdsl_list_cursor_free (c);
					    }
					break;

				    case 4:
					if (gdsl_list_is_empty (l))
					    {
						printf ("The list is empty.\n");
					    }
					else
					    {
						char Nom[100];
						gdsl_list_cursor_t c = gdsl_list_cursor_alloc (l);

						printf ("Name of cell before which you want to insert: ");
						scanf ("%s", Nom);
			
						if (!gdsl_list_cursor_move_to_value (c, compare_strings, Nom))
						    {
							printf ("The cell '%s' doesn't exist\n", Nom);
						    }
						else
						    {
							gdsl_list_cursor_insert_before (c, nom);
							done = 1;
						    }
						gdsl_list_cursor_free (c);
					    }
					break;

				    case 5:
					if (gdsl_list_is_empty (l))
					    {
						printf ("The list is empty.\n");
					    }
					else
					    {
						affiche_liste_chaines_fwd (l);
					    }
					break;

				    case 0:
					done = 1;
					break;
				    }
			    } 
			while (!done);
		    }
		    break;

		case 2:
		    if (gdsl_list_is_empty (l))
			{
			    printf ("The list is empty.\n");
			}
		    else
			{
			    gdsl_list_delete_head (l);
			}
		    break;

		case 3:
		    if (gdsl_list_is_empty (l))
			{
			    printf ("The list is empty.\n");
			}
		    else
			{
			    gdsl_list_delete_tail (l);
			}
		    break;

		case 4:
		    {
			char nom[100];

			if (gdsl_list_is_empty (l))
			    {
				printf ("The list is empty.\n");
			    }
			else
			    {
				printf ("Name of cell to remove: ");
				scanf ("%s", nom);

				if (!gdsl_list_delete (l, compare_strings, nom))
				    {
					printf ("The cell '%s' doesn't exist\n", nom);
				    }
				else
				    {
					printf ("The cell '%s' is removed from list\n", nom);
				    }
			    }
		    }
		    break;

		case 5:
		    if (gdsl_list_is_empty (l))
			{
			    printf ("The list is empty.\n");
			}
		    else
			{
			    affiche_liste_chaines_fwd (l);
			}
		    break;

		case 6:
		    if (gdsl_list_is_empty (l))
			{
			    printf ("The list is empty.\n");
			}
		    else
			{
			    affiche_liste_chaines_bwd (l);
			}
		    break;
	  
		case 7:
		    if (gdsl_list_is_empty (l))
			{
			    printf ("The list is empty.\n");
			}
		    else
			{
			    gdsl_list_flush (l);
			}
		    break;

		case 8:
		    printf ("Card( %s ) = %ld\n", gdsl_list_get_name (l), gdsl_list_get_size (l));
		    break;

		case 9:
		    if (gdsl_list_is_empty (l))
			{
			    printf ("The list is empty.\n");
			}
		    else
			{
			    gdsl_list_dump (l, print_string, stdout, NULL);
			}
		    break;

		case 10:
		    if (gdsl_list_is_empty (l))
			{
			    printf ("The list is empty.\n");
			}
		    else
			{
			    gdsl_list_write_xml (l, print_string, stdout, NULL);
			}
		    break;

		case 11:
		    {
			int pos;
			gdsl_element_t e;

			printf ("Enter the position of the place to search for: ");
			scanf ("%d", & pos);

			e = gdsl_list_search_by_position (l, (ulong) pos);
			if (e != NULL)
			    {
				print_string (e, stdout, GDSL_LOCATION_UNDEF, NULL);
			    }
		    }
		    break;
	  
		case 12:
		    {
			char nom [100];
			gdsl_element_t e;

			printf ("Name of cell to search for: ");
			scanf ("%s", nom);
	    
			e = gdsl_list_search (l, compare_strings, nom);
			if (e == NULL)
			    {
				printf ("The cell '%s' doesn't exist\n", nom);
			    }
			else
			    {
				printf ("The cell '%s' was found: ", nom);
				print_string (e, stdout, GDSL_LOCATION_UNDEF, NULL);
				printf ("\n");
			    }
		    }
		    break;

		case 13:
		    gdsl_list_sort (l, compare_strings);
		    break;
	  
		case 14:
		    if (gdsl_list_is_empty (l))
			{
			    printf ("The list is empty.\n");
			}
		    else
			{
			    printf ("Max Element: %s\n", (char*) gdsl_list_search_max (l, compare_strings));
			}
		    break;

		case 15: /* case for my own tests... */
		    {
			int i;
			gdsl_perm_t p = gdsl_perm_alloc ("p", PERMUTATION_NB);
			gdsl_list_t g = gdsl_list_alloc ("MY LIST 2", alloc_string, free_string);

			gdsl_perm_randomize (p);

			for (i = 0; i < PERMUTATION_NB; i++)
			    {
				char c[2];
				c[0] = 65 + gdsl_perm_get_element (p, i);
				c[1] = '\0';
				gdsl_list_insert_tail (g, c);
			    }

			gdsl_perm_free (p);
			affiche_liste_chaines_fwd (g);
			affiche_liste_chaines_bwd (g);
			printf ("SORT\n");
			gdsl_list_sort (g, compare_strings);
			affiche_liste_chaines_fwd (g);
			affiche_liste_chaines_bwd (g);
			gdsl_list_free (g);
		    }

		    {
			int i = 0;
			gdsl_list_cursor_t c = gdsl_list_cursor_alloc (l);

			for (gdsl_list_cursor_move_to_head (c); gdsl_list_cursor_get_content (c); gdsl_list_cursor_step_forward (c))
			    {
				char toto[50];
				sprintf (toto, "%d", i++);

				gdsl_list_cursor_insert_before (c, toto);

				gdsl_list_cursor_step_backward (c);
				gdsl_list_cursor_delete_after (c);
			    }
			
			gdsl_list_cursor_free (c);
		    }
		    break;
		}
	} 
    while (choix != 0);

    gdsl_list_free (l);

    exit (EXIT_SUCCESS);
}


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
