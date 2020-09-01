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
 * $RCSfile: main_lllist.c,v $
 * $Revision: 1.12 $
 * $Date: 2006/03/04 16:32:05 $
 */


#include <config.h>


#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#include "_gdsl_list.h"
#include "_strings.h"


static void
my_node_write (const _gdsl_node_t n, FILE* file, void* data)
{
    gdsl_element_t e = _gdsl_node_get_content (n);

    if (data == NULL)
	{
	    fprintf (file, "%s", (char*) e);
	}
    else
	{
	    fprintf (file, "%s%s", (char*) e, (char*) data);
	}
}
 
static int 
my_node_map (const _gdsl_node_t n, void* data)
{
    my_node_write (n, stdout, data);
    return GDSL_MAP_CONT;
}

int main (void)
{
    _gdsl_list_t a = _gdsl_list_alloc (alloc_string ("a"));
    _gdsl_list_t b = _gdsl_list_alloc (alloc_string ("b"));
    _gdsl_list_t c = _gdsl_list_alloc (alloc_string ("c"));

    _gdsl_list_link (a, b);
    _gdsl_list_link (b, c);

    printf ("WRITE (%ld elements):\n", _gdsl_list_get_size (a));
    _gdsl_list_write (a, my_node_write, stdout, NULL);

    printf ("\n\nDUMP:\n");
    _gdsl_list_dump (a, my_node_write, stdout, NULL);

    printf ("\nWRITE XML:\n");
    _gdsl_list_write_xml (a, my_node_write, stdout, NULL);

    printf ("\nMAP FORWARD:\n");
    _gdsl_list_map_forward (a, my_node_map, NULL);
    printf ("\n");

    printf ("\nMAP BACKWARD:\n");
    _gdsl_list_map_backward (a, my_node_map, NULL);
    printf ("\n");

    _gdsl_list_free (a, free_string);

    exit (EXIT_SUCCESS);
}


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
