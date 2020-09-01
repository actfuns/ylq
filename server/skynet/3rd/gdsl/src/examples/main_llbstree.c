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
 * $RCSfile: main_llbstree.c,v $
 * $Revision: 1.12 $
 * $Date: 2006/03/04 16:32:05 $
 */


#include <config.h>


#include <stdio.h> 
#include <string.h>
#include <stdlib.h>


#include "gdsl_perm.h"
#include "_gdsl_bstree.h"
#include "_integers.h"
#include "_strings.h"


#define N 100

static void
my_write_string (const _gdsl_bstree_t tree, FILE* file, void* d)
{
    gdsl_element_t e = _gdsl_bstree_get_content (tree);

    if (d == NULL)
	{
	    fprintf (file, "%s", (char*) e);
	}
    else
	{
	    fprintf (file, "%s%s", (char*) e, (char*) d);
	}  
}

static void
my_write_integer (const _gdsl_bstree_t tree, FILE* file, void* d)
{
    gdsl_element_t e = _gdsl_bstree_get_content (tree);
    long int** n = (long int**) e;

    if (d == NULL)
	{
	    fprintf (file, "%ld", (long int) *n);
	}
    else
	{
	    fprintf (file, "%ld%s", (long int) *n, (char*) d);
	}
}

int main (void)
{
    int rc;
    _gdsl_bstree_t t;

    printf ("Inserting 'a' in T... ");
    t  = _gdsl_bstree_alloc ((gdsl_element_t) "a");
    if (t != NULL)
	{
	    printf ("OK\n");
	}

    printf ("Inserting 'b' in T... ");
    _gdsl_bstree_insert (&t, compare_strings, "b", &rc);
    if (rc == 0)
	{
	    printf ("OK\n");
	}

    /* Volountary insertion of an existing element: */
    printf ("Inserting ALREADY EXISTING 'a' in T... ");
    _gdsl_bstree_insert (&t, compare_strings, "a", &rc);
    if (rc == GDSL_FOUND)
	{
	    printf ("KO: a already exists in T\n");
	}

    printf ("Inserting 'c' in T... ");
    _gdsl_bstree_insert (&t, compare_strings, "c", &rc);
    if (rc == 0)
	{
	    printf ("OK\n");
	}

    printf ("Inserting 'd' in T... ");
    _gdsl_bstree_insert (&t, compare_strings, "d", &rc);
    if (rc == 0)
	{
	    printf ("OK\n");
	}

    printf ("Inserting 'e' in T... ");
    _gdsl_bstree_insert (&t, compare_strings, "e", &rc);
    if (rc == 0)
	{
	    printf ("OK\n");
	}

    printf ("Inserting 'f' in T... ");
    _gdsl_bstree_insert (&t, compare_strings, "f", &rc);
    if (rc == 0)
	{
	    printf ("OK\n");
	}

    printf ("T:\n");

    _gdsl_bstree_write_xml (t, my_write_string, stdout, NULL);
    _gdsl_bstree_free (t, NULL);

    {
	int i;
	gdsl_perm_t p = gdsl_perm_alloc ("p", N);
	_gdsl_bstree_t t = NULL;

	gdsl_perm_randomize (p);

	for (i = 0; i < N; i++)
	    {
		int n = gdsl_perm_get_element (p, i);

		_gdsl_bstree_insert (&t, compare_integers, alloc_integer (&n), &rc);
	    }

	_gdsl_bstree_write_xml (t, my_write_integer, stdout, "");
	_gdsl_bstree_free (t, free_integer);
	gdsl_perm_free (p);
    }

    exit (EXIT_SUCCESS);
}


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
