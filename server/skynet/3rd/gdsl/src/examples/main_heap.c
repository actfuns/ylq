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
 * $RCSfile: main_heap.c,v $
 * $Revision: 1.12 $
 * $Date: 2006/06/21 14:47:24 $
 */


#include <config.h>


#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#include "gdsl_types.h"
#include "gdsl_heap.h"


#include "_integers.h"


static int 
my_display_integer (const gdsl_element_t e, gdsl_location_t location, 
		    void* user_infos)
{
    printf ("%s%s%ld ", 
	    (location & GDSL_LOCATION_ROOT) ? "[root]: " : "",
	    (location & GDSL_LOCATION_LEAF) ? "[leaf]: " : "",
	    *(long int*) e);
    return GDSL_MAP_CONT;
}

int main (void)
{
    int choix = 0;
    gdsl_heap_t h = gdsl_heap_alloc ("H", alloc_integer, free_integer, compare_integers);

    do
	{
	    printf ("\t\tMENU - HEAP\n\n");
	    printf ("\t1> Push: insert an element\n");
	    printf ("\t2> Pop: remove max element\n");
	    printf ("\t3> Get: peek max element\n");
	    printf ("\t4> Set: substitute max element\n");
	    printf ("\t5> Flush\n");
	    printf ("\t6> Remove: *** NOT YET IMPLEMENTED ***\n");
	    printf ("\t7> Display\n");
	    printf ("\t8> Dump\n");
	    printf ("\t9> XML display\n");
	    printf ("\t0> Quit\n\n");
	    printf ("\t\tYour choice: ");
	    scanf ("%d", &choix);

	    switch (choix)
		{
		case 1:
		    {
			int value;

			printf ("Enter integer value: ");
			scanf ("%d", &value);
			gdsl_heap_insert (h, (void*) &value);
		    }
		    break;

		case 2:
		    if (!gdsl_heap_is_empty (h))
			{
			    gdsl_heap_delete_top (h);
			}
		    else
			{
			    printf ("The heap '%s' is empty\n", gdsl_heap_get_name (h));
			}
		    break;

		case 3:
		    {
			long int* top;

			if (!gdsl_heap_is_empty (h)) 
			    {
				top = (long int*) gdsl_heap_get_top (h);
				printf ("Value = %ld\n", *top);
			    }
			else
			    {
				printf ("The heap '%s' is empty\n", gdsl_heap_get_name (h));
			    }
		    }
		    break;

		case 4:
		    {
			int value;
			long int* v;

			printf ("Enter integer value: ");
			scanf ("%d", &value);
			v = (long int*) gdsl_heap_set_top (h, (void*) &value);
			if (v == NULL)
			    {
				printf ("value is greather than all other heap ones\n");
			    }
			else
			    {
				printf ("old value was: %ld\n", *v);
				free_integer (v);
			    }
		    }
		    break;

		case 5:
		    if (gdsl_heap_is_empty (h))
			{
			    printf ("The heap '%s' is empty\n", gdsl_heap_get_name (h));
			}
		    else
			{
			    gdsl_heap_flush (h);
			}
		    break;
		    /*
		case 6:
		    {
			int pos;
			long int* value;
			printf ("Enter an integer value to search: ");
			scanf ("%d", &pos);

			value = (long int*) gdsl_heap_remove (h, &pos);
			if (value == NULL)
			    {
				printf ("Not found\n");
			    }
			else
			    {
				printf ("Value removed %ld\n", *value);
				free_integer (value);
			    }
		    }
		    break;
		    */
		case 7:
		    if (gdsl_heap_is_empty (h))
			{
			    printf ("The heap '%s' is empty\n", gdsl_heap_get_name (h));
			}
		    else
			{
			    printf ("%s = ( ", gdsl_heap_get_name (h));
			    gdsl_heap_map_forward (h, my_display_integer, NULL);
			    printf (")\n");
			}
		    break;

		case 8:
		    gdsl_heap_dump (h, print_integer, stdout, NULL);
		    break;

		case 9:
		    gdsl_heap_write_xml (h, print_integer, stdout, NULL);
		    break;
		}
	} 
    while (choix != 0);

    gdsl_heap_free (h);

    exit (EXIT_SUCCESS);
}


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
