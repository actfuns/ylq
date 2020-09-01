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
 * $RCSfile: main_sort.c,v $
 * $Revision: 1.1 $
 * $Date: 2006/06/21 14:20:21 $
 */


#include <config.h>


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>


#include "gdsl_types.h"
#include "gdsl_sort.h"


#define N 100
#define M 26


static long int
comp_char (const gdsl_element_t i, void* j)
{
    return (long int) i - (long int) j;
}


int main (void)
{
    int i;
    long int numbers [N];
    struct timeval tv;

    gettimeofday (&tv, NULL);
    srand (tv.tv_usec);

    printf ("Array of %d elements not sorted:\n", N);
    for (i = 0; i < N; i++)
	{
	    numbers [i] = 'a' + (long int) ((double) M * rand() / (RAND_MAX + 1.0));
	    printf ("%c ", (char) numbers [i]);
	}
    printf ("\n");

    gdsl_sort ((gdsl_element_t*) numbers, N, comp_char);

    printf ("Array sorted:\n");
    for (i = 0; i < N; i++)
	{
	    printf ("%c ", (char) numbers [i]);
	}
    printf ("\n");

    exit (EXIT_SUCCESS);
}


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
