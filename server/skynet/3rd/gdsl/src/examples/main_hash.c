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
 * $RCSfile: main_hash.c,v $
 * $Revision: 1.24 $
 * $Date: 2006/03/04 16:49:25 $
 */


#include <config.h>


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <mcheck.h>


#include "gdsl_types.h"
#include "gdsl_hash.h"
#include "_strings.h"


#define SIZE 11 /* Should be prime number !! */


struct _my_struct
{
    int  integer;
    char*string;
};
typedef struct _my_struct* my_struct;

static gdsl_element_t 
my_struct_alloc (void* d)
{
    static int n = 0;

    my_struct e = (my_struct) malloc (sizeof (struct _my_struct));
    if (e == NULL)
	{
	    return NULL;
	}

    e->integer = n++;
    e->string = strdup ((char*) d);

    return (gdsl_element_t) e;
}

static void 
my_struct_free (gdsl_element_t e)
{
    my_struct s = (my_struct) e;
    free (s->string);
    free (s);
}

static void
my_struct_printf (gdsl_element_t e, FILE* file, gdsl_location_t location, void* d)
{
    my_struct s = (my_struct) e;
    fprintf (file, "%d:%s ", s->integer, s->string);
}     

const char* 
my_struct_key (gdsl_element_t e)
{
    my_struct s = (my_struct) e;
    return s->string;
}

int main (void)
{
    int         choice;
    gdsl_hash_t ht;
    
    mtrace ();

    ht = gdsl_hash_alloc ("MY HASH TABLE", my_struct_alloc, my_struct_free, my_struct_key, NULL, SIZE);
    if (ht == NULL)
	{
	    fprintf (stderr, "%s:%d: %s - gdsl_hash_alloc(): NULL", 
		     __FILE__, __LINE__, __FUNCTION__);
	    exit (EXIT_FAILURE);
	}

    do
	{
	    printf ("\t\tMENU - HASH\n\n");
	    printf ("\t1> Insert\n");
	    printf ("\t2> Search\n");
	    printf ("\t3> Remove\n");
	    printf ("\t4> Display\n");
	    printf ("\t5> Flush\n");
	    printf ("\t6> Fill factor\n");
	    printf ("\t7> Dump\n");
	    printf ("\t8> XML display\n");
	    printf ("\t0> Quit\n\n");
	    printf ("\t\tYour choice: ");
	    scanf ("%d", &choice);

	    switch (choice)
		{
		case 1:
		    {
			char nom[50];

			printf ("String: ");
			scanf ("%s", nom);

			if (gdsl_hash_insert (ht, (void*) nom) == NULL)
			    {
				printf ("ERROR: Insert failed!\n");
			    }
		    }
		    break;

		case 2:
		    {
			char nom[50];
			gdsl_element_t e;

			printf ("String: ");
			scanf ("%s", nom);

			e = gdsl_hash_search (ht, nom);
			if (e == NULL)
			    {
				printf ("String '%s' doesn't exist\n", nom);
			    }
			else
			    {
				printf ("String '%s' found\n", nom);
			    }
		    }
		    break;

		case 3:
		    {
			char nom[50];
			gdsl_element_t e;

			printf ("String: ");
			scanf ("%s", nom);

			e = gdsl_hash_remove (ht, nom);
			if (e == NULL)
			    {
				printf ("String '%s' doesn't exist\n", nom);
			    }
			else
			    {
				free_string (e);
			    }
		    }
		    break;

		case 4:
		    gdsl_hash_write (ht, my_struct_printf, stdout, " ");
		    printf ("\n");
		    break;

		case 5:
		    gdsl_hash_flush (ht);
		    break;

		case 6:
		    printf ("Fill factor: %g\n", gdsl_hash_get_fill_factor (ht));
		    break;

		case 7:
		    gdsl_hash_dump (ht, my_struct_printf, stdout, NULL);
		    break;

		case 8:
		    gdsl_hash_write_xml (ht, my_struct_printf, stdout, NULL);
		    break;
		}
	} 
    while (choice != 0);

    gdsl_hash_free (ht);

    exit (EXIT_SUCCESS);
}


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
