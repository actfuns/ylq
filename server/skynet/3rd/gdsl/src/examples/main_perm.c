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
 * $RCSfile: main_perm.c,v $
 * $Revision: 1.18 $
 * $Date: 2006/03/04 16:32:05 $
 */


#include <config.h>


#include <stdio.h>
#include <stdlib.h>


#include "gdsl_types.h"
#include "gdsl_perm.h"
#include "_integers.h"


static void 
usage (void)
{
    printf ("Usage: perm <n>\n");
}

static void
write (const gdsl_element_t e, FILE* file, gdsl_location_t pos, void* user_data)
{
    ulong n = * (ulong*) e;

    if (pos & GDSL_LOCATION_FIRST)
	{
	    fprintf (file, "( ");

	    if (pos & GDSL_LOCATION_LAST)
		{
		    fprintf (file, "%ld )\n", n);
		}
	}

    if (pos & GDSL_LOCATION_LAST)
	{
	    fprintf (file, "%ld )\n", n);
	}
    else
	{
	    fprintf (file, "%ld, ", n);
	}
}

int main (int argc, char* argv [])
{
    ulong i, n;
    gdsl_perm_t l_alpha;
    gdsl_perm_t c_alpha;

    if (argc < 2)
	{
	    usage ();
	    return EXIT_FAILURE;
	}

    n = atoi (argv[1]);

    c_alpha = gdsl_perm_alloc ("c_alpha", n);

    l_alpha = gdsl_perm_alloc ("l_alpha", n);
    gdsl_perm_randomize (l_alpha);

    printf ("alpha         = ");
    gdsl_perm_write (l_alpha, write, stdout, NULL);
    printf ("                %ld cycles, %ld inversions\n\n",
	    gdsl_perm_linear_cycles_count (l_alpha),
	    gdsl_perm_linear_inversions_count (l_alpha));

    gdsl_perm_reverse (l_alpha);

    printf ("~alpha        = ");
    gdsl_perm_write (l_alpha, write, stdout, NULL);
    printf ("                %ld cycles, %ld inversions\n\n",
	    gdsl_perm_linear_cycles_count (l_alpha),
	    gdsl_perm_linear_inversions_count (l_alpha));

    gdsl_perm_reverse (l_alpha);
    gdsl_perm_inverse (l_alpha);

    printf ("alpha^-1      = ");
    gdsl_perm_write (l_alpha, write, stdout, NULL);
    printf ("                %ld cycles, %ld inversions\n\n",
	    gdsl_perm_linear_cycles_count (l_alpha),
	    gdsl_perm_linear_inversions_count (l_alpha));

    gdsl_perm_inverse (l_alpha);

    printf ("alpha         = ");
    gdsl_perm_write (l_alpha, write, stdout, NULL);
    printf ("                %ld cycles, %ld inversions\n\n",
	    gdsl_perm_linear_cycles_count (l_alpha),
	    gdsl_perm_linear_inversions_count (l_alpha));
  
    gdsl_perm_linear_to_canonical (c_alpha, l_alpha);
    printf ("cycles(alpha) = ");
    gdsl_perm_write (c_alpha, write, stdout, NULL);
    printf ("                %ld cycles\n\n",
	    gdsl_perm_canonical_cycles_count (c_alpha));

    gdsl_perm_canonical_to_linear (l_alpha, c_alpha);

    printf ("alpha         = ");
    gdsl_perm_write (l_alpha, write, stdout, NULL);
    printf ("                %ld cycles, %ld inversions\n\n",
	    gdsl_perm_linear_cycles_count (l_alpha),
	    gdsl_perm_linear_inversions_count (l_alpha));

    gdsl_perm_free (l_alpha);
    gdsl_perm_free (c_alpha);

    {
	ulong v [] = {0, 2, 3, 1, 4, 5, 6, 7, 8};
	ulong n = sizeof (v) / sizeof (v [0]);
	gdsl_perm_t a = gdsl_perm_alloc ("a", n);

	printf ("initial array: ");
	for (i = 0; i < n; i++)
	    {
		printf ("%ld ", v [i]);
	    }
	printf ("\n");

	gdsl_perm_randomize (a);
	printf ("applying permutation: ");
	gdsl_perm_write (a, write, stdout, NULL);
	gdsl_perm_apply_on_array ((gdsl_element_t*) v, a);
	gdsl_perm_free (a);

	printf ("modified array: ");
	for (i = 0; i < n; i++)
	    {
		printf ("%ld ", v [i]);
	    }
	printf ("\n");
    }

    exit (EXIT_SUCCESS);
}


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
