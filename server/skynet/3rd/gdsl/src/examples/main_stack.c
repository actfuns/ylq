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
 * $RCSfile: main_stack.c,v $
 * $Revision: 1.13 $
 * $Date: 2006/03/04 16:49:25 $
 */


#include <config.h>


#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#include "gdsl_types.h"
#include "gdsl_stack.h"


#include "_integers.h"


static int 
my_display_integer (gdsl_element_t e, gdsl_location_t location, void *user_infos)
{
    int* f = (int*) e;
    printf ("%d ", *f);
    return GDSL_MAP_CONT;
}

int main (void)
{
    int choix = 0;
    gdsl_stack_t s = gdsl_stack_alloc ("S", alloc_integer, free_integer);

    do
	{
	    printf ("\t\tMENU - STACK\n\n");
	    printf ("\t1> Push\n");
	    printf ("\t2> Pop\n");
	    printf ("\t3> Get\n");
	    printf ("\t4> Flush\n");
	    printf ("\t5> Search\n");
	    printf ("\t6> Display\n");
	    printf ("\t7> Dump\n");
	    printf ("\t8> XML display\n");
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
			gdsl_stack_insert (s, (void*) &value);
		    }
		    break;

		case 2:
		    if (!gdsl_stack_is_empty (s))
			{
			    free_integer (gdsl_stack_remove (s));
			}
		    else
			{
			    printf ("The stack '%s' is empty\n", gdsl_stack_get_name (s));
			}
		    break;
	  
		case 3:
		    {
			int* top;

			if (!gdsl_stack_is_empty (s)) 
			    {
				top = (int*) gdsl_stack_get_top (s);
				printf ("Value = %d\n", *top);
			    }
			else
			    {
				printf ("The stack '%s' is empty\n", gdsl_stack_get_name (s));
			    }
		    }
		    break;

		case 4:
		    if (gdsl_stack_is_empty (s))
			{
			    printf ("The stack '%s' is empty\n", gdsl_stack_get_name (s));
			}
		    else
			{
			    gdsl_stack_flush (s);
			}
		    break;

		case 5:
		    {
			int pos;
			int* value;
			printf ("Enter an integer value to search an element by its position: ");
			scanf ("%d", &pos);

			value = (int*) gdsl_stack_search_by_position (s, pos);
			if (value != NULL)
			    {
				printf ("Value found at position %d = %d\n", pos, *value);
			    }
		    }
		    break;

		case 6:
		    if (gdsl_stack_is_empty (s))
			{
			    printf ("The stack '%s' is empty\n", gdsl_stack_get_name (s));
			}
		    else
			{
			    printf ("%s = ( ", gdsl_stack_get_name (s));
			    gdsl_stack_map_forward (s, my_display_integer, NULL);
			    printf (")\n");
			}
		    break;


		case 7:
		    gdsl_stack_dump (s, print_integer, stdout, NULL);
		    break;

		case 8:
		    gdsl_stack_write_xml (s, print_integer, stdout, NULL);
		    break;
		}
	} 
    while (choix != 0);

    gdsl_stack_free (s);

    exit (EXIT_SUCCESS);
}


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
