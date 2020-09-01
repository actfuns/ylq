/*
 * This file is part of the Generic Data Structures Library (GDSL).
 * Copyright (C) 1998-2006 Nicolas Darnis <ndarnis@free.fr>.
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
 * 59 Temple Place, Suite 330, Boston, MA  02111-1307, USA.
 *
 * $RCSfile: gdsl_sort.c,v $
 * $Revision: 1.6 $
 * $Date: 2006/03/04 16:32:05 $
 */


#include <config.h>


#include "gdsl_types.h"


static void
taslactite (gdsl_element_t* t, ulong n, ulong k, gdsl_compare_func_t comp_f);

/******************************************************************************/
/* Public functions                                                           */
/******************************************************************************/

extern void
gdsl_sort (gdsl_element_t* t, ulong n, const gdsl_compare_func_t comp_f)
{
    ulong i;

    /*
     * Sort in place the array t, using a heap.
     */
    for (i = n / 2; i >= 1; i--)
	{
	    taslactite (t, n, i, comp_f);
	}

    i = n;
    while (i > 1)
	{
	    gdsl_element_t v = t [0];

	    t [0] = t [i-1];
	    t [i-1] = v;

	    taslactite (t, --i, 1, comp_f);
	}
}

/******************************************************************************/
/* Private functions                                                          */
/******************************************************************************/

static void
taslactite (gdsl_element_t* t, ulong n, ulong k, gdsl_compare_func_t comp_f)
{
    ulong          j;
    gdsl_element_t v;

    v = t [k-1];

    while (k <= n / 2)
	{
	    j = k + k;

	    if (j < n && comp_f (t [j-1], t [j]) < 0)
		{
		    j++;
		}

	    if (comp_f (t [j-1], v) <= 0)
		{
		    break;
		}

	    t [k-1] = t [j-1];
	    k = j;
	}

    t [k-1] = v;
}


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
