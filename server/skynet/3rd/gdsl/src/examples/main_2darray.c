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
 * $RCSfile: main_2darray.c,v $
 * $Revision: 1.11 $
 * $Date: 2006/03/04 16:32:05 $
 */


#include <config.h>


#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#include "gdsl_2darray.h"
#include "_integers.h"


#define ROWS_NB 4UL
#define COLS_NB 3UL


static void 
my_display_integer (const gdsl_element_t e, FILE* file, gdsl_location_t position, void* user_data)
{
    int* n = (int*) e;

    if (position & GDSL_LOCATION_FIRST_COL)
	{
	    if (position & GDSL_LOCATION_FIRST_ROW)
		{
		    fprintf (file, "{\n");
		}

	    fprintf (file, "\t( ");
	}
    else
	{
	    fprintf (file, " ");
	}

    fprintf (file, "%02d", *n);

    if (position & GDSL_LOCATION_LAST_COL)
	{
	    fprintf (file, " )\n");

	    if (position & GDSL_LOCATION_LAST_ROW)
		{
		    fprintf (file, "\t}\n");
		}
	}
}

int main (void)
{
    int i, j, k = 0;
    gdsl_2darray_t m = gdsl_2darray_alloc ("MY ARRAY", ROWS_NB, COLS_NB, alloc_integer, free_integer);

    for (i = 0; i < ROWS_NB; i++)
	{
	    for (j = 0; j < COLS_NB; j++)
		{
		    int n = ++k;
		    gdsl_2darray_set_content (m, i, j, (void*) &n);
		}
	}

    printf ("%s (%ld x %ld) = ", gdsl_2darray_get_name (m),
	    gdsl_2darray_get_rows_number (m), 
	    gdsl_2darray_get_columns_number (m));

    gdsl_2darray_write (m, my_display_integer, stdout, NULL);
    gdsl_2darray_write_xml (m, my_display_integer, stdout, NULL);
    gdsl_2darray_dump (m, my_display_integer, stdout, NULL);

    gdsl_2darray_free (m);

    exit (EXIT_SUCCESS);
}


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
