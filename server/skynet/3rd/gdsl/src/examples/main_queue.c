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
 * $RCSfile: main_queue.c,v $
 * $Revision: 1.12 $
 * $Date: 2006/03/04 16:32:05 $
 */


#include <config.h>


#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#include "gdsl_types.h"
#include "gdsl_queue.h"


#include "_integers.h"


static void
my_write_integer (gdsl_element_t e, FILE* file, gdsl_location_t location, void* d)
{
    int value = * (int*) e;

    if (location & GDSL_LOCATION_HEAD)
	{
	    fprintf (file, "( %d", value);
	}
    else
	{
	    fprintf (file, " %d", value);
	}

    if (location & GDSL_LOCATION_TAIL)
	{
	    fprintf (file, " )\n");
	}
}

static int 
my_display_integer (gdsl_element_t e, gdsl_location_t location, void* d)
{
    my_write_integer (e, stdout, location, d);
    return GDSL_MAP_CONT;
}

int main (void)
{
    int choice = 0;
    gdsl_queue_t q = gdsl_queue_alloc ("Q", alloc_integer, free_integer);
  
    do
	{
	    printf ("\t\tMENU - QUEUE\n\n");
	    printf ("\t1> Put\n");
	    printf ("\t2> Pop\n");
	    printf ("\t3> Get Head\n");
	    printf ("\t4> Get Tail\n");
	    printf ("\t5> Flush\n");
	    printf ("\t6> Search\n");
	    printf ("\t7> Display\n");
	    printf ("\t8> Dump\n");
	    printf ("\t9> XML display\n");
	    printf ("\t0> Quit\n\n" );
	    printf ("\t\tYour choice: " );
	    scanf ("%d", &choice );

	    switch (choice)
		{
		case 1:
		    {
			int value;
			printf ("Enter an integer value: ");
			scanf ("%d", &value);
			gdsl_queue_insert (q, (void*) &value);
		    }
		    break;

		case 2:
		    if (!gdsl_queue_is_empty (q))
			{
			    int* value = (int*) gdsl_queue_remove (q);
			    printf ("Value: %d\n", *value);
			    free_integer (value);
			}
		    else
			{
			    printf ("The queue '%s' is empty\n", gdsl_queue_get_name (q));
			}
		    break;
	  
		case 3:
		    {
			if (!gdsl_queue_is_empty (q)) 
			    {
				int head = *(int*) gdsl_queue_get_head (q);
				printf ("Head = %d\n", head);
			    }
			else
			    {
				printf ("The queue '%s' is empty\n", gdsl_queue_get_name (q));
			    }
		    }
		    break;

		case 4:
		    {
			if (!gdsl_queue_is_empty (q)) 
			    {
				int tail = *(int*) gdsl_queue_get_tail (q);
				printf ("Tail = %d\n", tail);
			    }
			else
			    {
				printf ("The queue '%s' is empty\n", gdsl_queue_get_name (q));
			    }
		    }
		    break;

		case 5:
		    if (gdsl_queue_is_empty (q))
			{
			    printf ("The queue '%s' is empty\n", gdsl_queue_get_name (q));
			}
		    else
			{
			    gdsl_queue_flush (q);
			}
		    break;

		case 6:
		    {
			int pos;
			int* value;
			printf ("Enter an integer value to search an element by its position: ");
			scanf ("%d", &pos);

			value = (int*) gdsl_queue_search_by_position (q, pos);
			if (value != NULL)
			    {
				printf ("Value found at position %d = %d\n", pos, *value);
			    }
		    }
		    break;

		case 7:
		    if (gdsl_queue_is_empty (q))
			{
			    printf ("The queue '%s' is empty\n", gdsl_queue_get_name (q));
			}
		    else
			{
			    printf ("%s = ", gdsl_queue_get_name (q));
			    gdsl_queue_map_forward (q, my_display_integer, NULL);
			}
		    break;

		case 8:
		    gdsl_queue_dump (q, my_write_integer, stdout, NULL);
		    break;

		case 9:
		    gdsl_queue_write_xml (q, my_write_integer, stdout, NULL);
		    break;
		}
	} 
    while (choice != 0);

    gdsl_queue_free (q);

    exit (EXIT_SUCCESS);
}


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
