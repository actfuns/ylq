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
 * $RCSfile: gdsl_perm.c,v $
 * $Revision: 1.27 $
 * $Date: 2007/01/08 13:59:23 $
 */


#include <config.h>


#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/time.h>
#include <assert.h>


#include "gdsl_types.h"
#include "gdsl_list.h"
#include "gdsl_perm.h"


struct gdsl_perm
{
    ulong  n;    /* cardinality */
    ulong* e;    /* elements */
    char*  name; /* name */
};

static bool
_array_is_valid (const ulong* v, ulong n);

/******************************************************************************/
/* Management functions of low-level permutations                             */
/******************************************************************************/

extern gdsl_perm_t
gdsl_perm_alloc (const char* name, const ulong n)
{
    ulong        i;
    gdsl_perm_t p;

    assert (n > 0);
  
    p = (gdsl_perm_t) malloc (sizeof (struct gdsl_perm));

    if (p == NULL)
	{
	    return NULL;
	}

    p->n = n;

    p->e = (ulong*) malloc (p->n * sizeof (ulong));

    if (p->e == NULL)
	{
	    free (p);
	    return NULL;
	}

    p->name = NULL;

    if (gdsl_perm_set_name (p, name) == NULL)
	{
	    free (p->e);
	    free (p);
	    return NULL;
	}

    for (i = 0; i < p->n; i++)
	{
	    p->e[i] = i;
	}

    return p;
}

extern void
gdsl_perm_free (gdsl_perm_t p)
{
    assert (p != NULL);

    if (p->name != NULL)
	{
	    free (p->name);
	}

    free (p->e);
    free (p);
}

extern gdsl_perm_t
gdsl_perm_copy (const gdsl_perm_t p)
{
    ulong        i;
    gdsl_perm_t copy;

    assert (p != NULL);

    copy = gdsl_perm_alloc (p->name, p->n);

    if (copy == NULL)
	{
	    return NULL;
	}

    for (i = 0; i < p->n; i++)
	{
	    copy->e[i] = p->e[i];
	}

    return copy;
}

/******************************************************************************/
/* Consultation functions of low-level permutations                           */
/******************************************************************************/

extern const char*
gdsl_perm_get_name (const gdsl_perm_t p)
{
    assert (p != NULL);

    return p->name;
}

extern ulong
gdsl_perm_get_size (const gdsl_perm_t p)
{
    assert (p != NULL);

    return p->n;
}

extern ulong
gdsl_perm_get_element (const gdsl_perm_t p, const ulong i)
{
    assert (p != NULL);
    assert (i >= 0 && i < p->n);

    return p->e [i];
}

extern ulong*
gdsl_perm_get_elements_array (const gdsl_perm_t p)
{
    assert (p != NULL);

    return p->e;
}

extern ulong
gdsl_perm_linear_inversions_count (const gdsl_perm_t p)
{
    ulong i;
    ulong j;
    ulong count = 0;

    assert (p != NULL);

    for (i = 0; i < p->n - 1; i++)
	{
	    for (j = i + 1; j < p->n; j++)
		{
		    if (p->e[i] > p->e[j])
			{
			    count++;
			}
		}
	}

    return count;
}

extern ulong
gdsl_perm_linear_cycles_count (const gdsl_perm_t p)
{
    ulong i;
    ulong j;
    ulong count = 0;

    assert (p != NULL);

    for (i = 0; i < p->n; i++)
	{
	    j = p->e[i];

	    while (j > i)
		{
		    j = p->e[j];
		}

	    if (j < i)
		{
		    continue;
		}

	    count++;
	}

    return count;
}

extern ulong
gdsl_perm_canonical_cycles_count (const gdsl_perm_t p)
{
    ulong i;
    ulong min;
    ulong count = 1;

    assert (p != NULL);

    min = p->e[0];
 
    for (i = 1; i < p->n; i++)
	{
	    if (p->e[i] < min)
		{
		    min = p->e[i];
		    count++;
		}
	}

    return count;
}

/******************************************************************************/
/* Modification functions of low-level permutations                           */
/******************************************************************************/

extern gdsl_perm_t
gdsl_perm_set_name (gdsl_perm_t p, const char* name)
{
    assert (p != NULL);

    if (p->name != NULL)
	{
	    free (p->name);
	    p->name = NULL;
	}

    if (name != NULL)
	{
	    p->name = (char*) malloc ((1 + strlen (name)) * sizeof (char));

	    if (p->name == NULL)
		{
		    return NULL;
		}

	    strcpy (p->name, name);
	}
  
    return p;
}

extern gdsl_perm_t
gdsl_perm_linear_next (gdsl_perm_t p)
{
    /* 
     * Replaces p with the next permutation (in the standard lexicographical
     * ordering).  Returns NULL if there is no next permutation.
     */

    long i, j, k;

    assert (p != NULL);
    assert (p->n > 1);

    i = p->n - 2;

    while ((p->e[i] > p->e[i+1]) && (i != 0))
	{
	    i--;
	}

    if ((i == 0) && (p->e[0] > p->e[1]))
	{
	    return NULL;
	}

    k = i + 1;

    for (j = i + 2; j < p->n; j++ )
	{
	    if ((p->e[j] > p->e[i]) && (p->e[j] < p->e[k]))
		{
		    k = j;
		}
	}

    /* swap i and k */

    {
	ulong tmp = p->e[i];
	p->e[i] = p->e[k];
	p->e[k] = tmp;
    }

    for (j = i + 1; j <= ((p->n + i) / 2); j++)
	{
	    ulong tmp = p->e[j];
	    p->e[j] = p->e[p->n + i - j];
	    p->e[p->n + i - j] = tmp;
	}

    return p;
}

extern gdsl_perm_t
gdsl_perm_linear_prev (gdsl_perm_t p)
{
    /* 
     * Replaces p with the previous permutation (in the standard lexicographical
     * ordering).  Returns NULL if there is no previous permutation.
     */

    long i, j, k;

    assert (p != NULL);
    assert (p->n >= 2);

    i = p->n - 2;

    while ((p->e[i] < p->e[i+1]) && (i != 0))
	{
	    i--;
	}

    if ((i == 0) && (p->e[0] < p->e[1]))
	{
	    return NULL;
	}

    k = i + 1;

    for (j = i + 2; j < p->n; j++ )
	{
	    if ((p->e[j] < p->e[i]) && (p->e[j] > p->e[k]))
		{
		    k = j;
		}
	}

    /* swap i and k */

    {
	ulong tmp = p->e[i];
	p->e[i] = p->e[k];
	p->e[k] = tmp;
    }

    for (j = i + 1; j <= ((p->n + i) / 2); j++)
	{
	    ulong tmp = p->e[j];
	    p->e[j] = p->e[p->n + i - j];
	    p->e[p->n + i - j] = tmp;
	}

    return p;
}

extern gdsl_perm_t
gdsl_perm_set_elements_array (gdsl_perm_t p,  const ulong* v)
{
    ulong i;

    assert (p != NULL);
    assert (v != NULL);

    if (!_array_is_valid (v, p->n))
	{
	    return NULL;
	}

    for (i = 0; i < p->n; i++)
	{
	    p->e[i] = v[i];
	}

    return p;
}

/******************************************************************************/
/* Operations functions of low-level permutations                             */
/******************************************************************************/

extern gdsl_perm_t
gdsl_perm_multiply (gdsl_perm_t r, const gdsl_perm_t a, const gdsl_perm_t b)
{
    ulong i;

    assert (r != NULL);
    assert (a != NULL);
    assert (b != NULL);
    assert (r->n == a->n);
    assert (r->n == b->n);

    for (i = 0; i < r->n; i++)
	{
	    r->e[i] = b->e[a->e[i]];
	}

    return r;
}

extern gdsl_perm_t
gdsl_perm_linear_to_canonical (gdsl_perm_t q, const gdsl_perm_t p)
{
    assert (q != NULL);
    assert (p != NULL);
    assert (q->n == p->n);
    assert (q != p);

    {
	ulong i;
	ulong k;
	ulong s;
	ulong t = p->n;
	const ulong* const pp = p->e;
	ulong* const qq = q->e;

	for (i = 0; i < p->n; i++)
	    {
      
		k = pp[i];
		s = 1;
      
		while (k > i)
		    {
			k = pp[k];
			s++;
		    }
      
		if (k < i)
		    {
			continue;
		    }
      
		/* On a ici k == i, i.e le dernier dans ce cycle, et s == longueur du cycle */
      
		t -= s;
      
		qq[t] = i;
      
		k = pp[i];
		s = 1;
      
		while (k > i)
		    {
			qq[t + s] = k;
			k = pp[k];
			s++;
		    }
      
		if (t == 0)
		    {
			break;
		    }
	    }
    }

    return q;
}

extern gdsl_perm_t
gdsl_perm_canonical_to_linear (gdsl_perm_t q, const gdsl_perm_t p)
{
    assert (q != NULL);
    assert (p != NULL);
    assert (q->n == p->n);
    assert (q != p);

    {
	ulong i;
	ulong k;
	ulong kk;
	ulong first;
	const ulong* const pp = p->e;
	ulong* const qq = q->e;

	for (i = 0; i < p->n; i++)
	    {
		qq[i] = i;
	    }
  
	k = pp[0];
	first = qq[k];
  
	for (i = 1; i < p->n; i++)
	    {
		kk = pp[i];
      
		if (kk > first)
		    {
			qq[k] = qq[kk];
			k = kk;
		    }
		else
		    {
			qq[k] = first;
			k = kk;
			first = qq[kk];
		    }
	    }
  
	qq[k] = first;
    }

    return q;
}

extern gdsl_perm_t
gdsl_perm_inverse (gdsl_perm_t p)
{
    ulong  i;
    ulong* t;

    assert (p != NULL);

    t = (ulong*) alloca (p->n * sizeof (ulong));

    if (t == NULL)
	{
	    return NULL;
	}

    for (i = 0; i < p->n; i++)
	{
	    t [i] = p->e [i];
	}

    for (i = 0; i < p->n; i++)
	{
	    p->e [t [i]] = i;
	}

    return p;
}

extern gdsl_perm_t
gdsl_perm_reverse (gdsl_perm_t p)
{
    ulong i;
  
    assert (p != NULL);

    for (i = 0; i < (p->n / 2); i++) 
	{
	    ulong j = p->n - i - 1;

	    ulong tmp = p->e [i];
	    p->e [i]   = p->e [j];
	    p->e [j]   = tmp;
	}

    return p;
}

extern gdsl_perm_t
gdsl_perm_randomize (gdsl_perm_t p)
{
    ulong          i;
    long           j;
    long           k;
    ulong*         t;
    struct timeval tv;

    assert (p != NULL);

    /* random inversions array (t) creation */
    gettimeofday (&tv, NULL);
    srand (tv.tv_usec);

    t = (ulong*) alloca (p->n * sizeof (ulong));

    if (t == NULL)
	{
	    return NULL;
	}

    for (i = 0; i < p->n - 1; i++)
	{
	    /* for all i in [0; N-1], 0 <= t[i] <= N-i-1
	       following code is equiv to rand () % (p->n - i) 
	    */
	    t [i] = (int) ((double) (p->n - i) * rand() / (RAND_MAX + 1.0));
	}

    t [i] = 0;

    /* converting t to a permutation */
    for (k = p->n - 1; k >= 0; k--)
	{
	    for (j = p->n - k - 1; j > t [k]; j--)
		{
		    p->e [j] = p->e [j-1];
		}

	    p->e [j] = k;
	}

    return p;
}

extern gdsl_element_t*
gdsl_perm_apply_on_array (gdsl_element_t* t, const gdsl_perm_t p)
{
    ulong           i;
    gdsl_element_t* b;

    assert (t != NULL);
    assert (p != NULL);

    b = (gdsl_element_t*) alloca (p->n * sizeof (gdsl_element_t));

    if (b == NULL)
	{
	    return NULL;

	}

    for (i = 0; i < p->n; i++)
	{
	    b [i] = t [p->e [i]];
	}

    memcpy (t, b, p->n * sizeof (gdsl_element_t));

    return t;
}

/******************************************************************************/
/* Input/output functions of low-level permutations                           */
/******************************************************************************/

extern void
gdsl_perm_write (const gdsl_perm_t p, const gdsl_write_func_t write_f,
		 FILE* file, void* user_data)
{
    ulong i;
    gdsl_location_t pos = GDSL_LOCATION_UNDEF;

    assert (p != NULL);
    assert (file != NULL);
    assert (write_f != NULL);

    pos |= GDSL_LOCATION_FIRST;
    write_f ((gdsl_element_t) &(p->e [0]), file, pos, user_data);

    pos &= ~GDSL_LOCATION_FIRST;
    for (i = 1; i < p->n - 1; i++)
	{
	    write_f ((gdsl_element_t) &(p->e [i]), file, pos, user_data);
	}

    pos |= GDSL_LOCATION_LAST;
    write_f ((gdsl_element_t) &(p->e [i]), file, pos, user_data);
}

extern void
gdsl_perm_write_xml (const gdsl_perm_t p, const gdsl_write_func_t write_f,
		     FILE* file, void* user_data)
{
    ulong i;
    gdsl_location_t pos = GDSL_LOCATION_UNDEF;

    assert (p != NULL);
    assert (file != NULL);

    fprintf (file, "<GDSL_PERM REF=\"%p\" NAME=\"%s\" CARD=\"%ld\">\n", 
	     (void*) p, p->name, p->n); 

    for (i = 0; i < p->n; i++)
	{
	    fprintf (file, "<GDSL_PERM_ELEMENT INDIX=\"%ld\" VALUE=\"%ld\">", i, p->e[i]);

	    if (write_f != NULL)
		{
		    fprintf (file, "\n");
		    if (i == 0)
			{
			    pos |= GDSL_LOCATION_FIRST;
			}

		    if (i == 1)
			{
			    pos &= ~GDSL_LOCATION_FIRST;
			}

		    if (i == p->n)
			{
			    pos |= GDSL_LOCATION_LAST;
			}

		    write_f ((gdsl_element_t) &(p->e[i]), file, pos, user_data);
		    fprintf (file, "\n");
		}

	    fprintf (file, "</GDSL_PERM_ELEMENT>\n");
	}

    fprintf (file, "</GDSL_PERM>\n");
}

extern void
gdsl_perm_dump (const gdsl_perm_t p, const gdsl_write_func_t write_f,
		FILE* file, void* user_data)
{
    assert (p != NULL);
    assert (file != NULL);

    gdsl_perm_write_xml (p, write_f, file, user_data);
}

/******************************************************************************/
/* Private functions                                                          */
/******************************************************************************/

static bool
_array_is_valid (const ulong* v, ulong n)
{
    ulong i;
    ulong j;

    assert (v != NULL);

    for (i = 0; i < n; i++) 
	{
	    if (v[i] >= n)
		{
		    return FALSE;
		}

	    for (j = 0; j < i; j++)
		{
		    if (v[i] == v[j])
			{
			    return FALSE;
			}
		}
	}

    return TRUE;
}


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
