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
 * $RCSfile: _integers.c,v $
 * $Revision: 1.13 $
 * $Date: 2006/03/04 16:32:05 $
 */


#include <config.h>


#include <stdlib.h>
#include <string.h>
#include <assert.h>


#include "gdsl_types.h"


#include "_integers.h"


extern gdsl_element_t 
alloc_integer (void *integer)
{
    long int* n = (long int*) integer;
    long int* value = (long int*) malloc (sizeof (long int));

    assert (value != NULL);

    memcpy (value, n, sizeof (long int));

    return (gdsl_element_t) value;
}

extern void 
free_integer (gdsl_element_t e)
{
    free (e);
}

extern void
print_integer (gdsl_element_t e, FILE* file, gdsl_location_t location, void* d)
{
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

extern long int
compare_integers (gdsl_element_t e1, void* e2)
{
    return *(long int*) e1 - *(long int*) e2;
}


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
