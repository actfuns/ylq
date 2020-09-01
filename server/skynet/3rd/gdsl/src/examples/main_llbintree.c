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
 * $RCSfile: main_llbintree.c,v $
 * $Revision: 1.13 $
 * $Date: 2006/03/04 16:32:05 $
 */


#include <config.h>


#include <stdio.h> 
#include <string.h>
#include <stdlib.h>


#include "_gdsl_bintree.h"
#include "_strings.h"


static void
my_write_string (const _gdsl_bintree_t tree, FILE* file, void* d)
{
    gdsl_element_t e = _gdsl_bintree_get_content (tree);

    if (d == NULL)
	{
	    fprintf (file, "%s", (char*) e);
	}
    else
	{
	    fprintf (file, "%s%s", (char*) e, (char*) d);
	}  
}

static int 
my_map_string (const _gdsl_bintree_t t, void* d)
{
    my_write_string (t, stdout, d);
    return GDSL_MAP_CONT;
}

int main (void)
{
    _gdsl_bintree_t g, d, t, t1, t2, copy;

    g  = _gdsl_bintree_alloc ((gdsl_element_t) "b", NULL, NULL);
    d  = _gdsl_bintree_alloc ((gdsl_element_t) "o", NULL, NULL);
    t1 = _gdsl_bintree_alloc ((gdsl_element_t) "n", g, d);
    g  = _gdsl_bintree_alloc ((gdsl_element_t) "j", NULL, NULL);
    d  = _gdsl_bintree_alloc ((gdsl_element_t) "o", NULL, NULL);
    t2 = _gdsl_bintree_alloc ((gdsl_element_t) "u", g, d);
    t  = _gdsl_bintree_alloc ((gdsl_element_t) "r", t1, t2);
  
    printf ("T:\n");
    _gdsl_bintree_write_xml (t, my_write_string, stdout, NULL);

    copy = _gdsl_bintree_copy (t, copy_string);
    printf ("COPY OF T: \n");
    _gdsl_bintree_dump (copy, my_write_string, stdout, NULL);

    _gdsl_bintree_rotate_left (&t);
    _gdsl_bintree_rotate_right (&t);
    _gdsl_bintree_rotate_right (&t);
    _gdsl_bintree_rotate_left (&t);

    printf ("\nT in prefixed order: ");
    _gdsl_bintree_map_prefix (t, my_map_string, (void*) " ");
    printf ("\nT in infixed order: ");
    _gdsl_bintree_map_infix (t, my_map_string, (void*) " ");
    printf ("\nT in postfixed order: ");
    _gdsl_bintree_map_postfix (t, my_map_string, (void*) " ");

    printf ("\n\nCOPY OF T in prefixed order: ");
    _gdsl_bintree_map_prefix (copy, my_map_string, (void*) " ");
    printf ("\nCOPY OF T in infixed order: ");
    _gdsl_bintree_map_infix (copy, my_map_string, (void*) " ");
    printf ("\nCOPY OF T in postfixed order: ");
    _gdsl_bintree_map_postfix (copy, my_map_string, (void*) " ");
    printf ("\n\n");

    _gdsl_bintree_free (copy, free_string);
    _gdsl_bintree_free (t, NULL);

    exit (EXIT_SUCCESS);
}


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
