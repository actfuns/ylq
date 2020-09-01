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
 * $RCSfile: _strings.c,v $
 * $Revision: 1.12 $
 * $Date: 2006/03/04 16:32:05 $
 */


#include <stdlib.h>
#include <string.h>


#include "gdsl_types.h"


#include "_strings.h"


extern gdsl_element_t
alloc_string (void* string)
{
    return (gdsl_element_t) strdup ((char*) string);
}

extern void
free_string (gdsl_element_t e)
{
    free (e);
}

extern gdsl_element_t
copy_string (gdsl_element_t e)
{
    return (gdsl_element_t) strdup ((char*) e);
}

extern void
print_string (gdsl_element_t e, FILE* file, gdsl_location_t location, void* d)
{
    char loc [256] = "";

    if (location & GDSL_LOCATION_ROOT)
	{
	    strcat (loc, "ROOT ");
	}

    if (location & GDSL_LOCATION_LEAF)
	{
	    strcat (loc, "LEAF ");
	}

    if (d == NULL)
	{
	    fprintf (file, "%s%s", (char*) e, loc);
	}
    else
	{
	    fprintf (file, "%s%s%s", (char*) e, loc, (char*) d);
	}
}

extern long int
compare_strings (gdsl_element_t s1, void* s2)
{
    return strcmp ((char*) s1, (char*) s2);
}


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
