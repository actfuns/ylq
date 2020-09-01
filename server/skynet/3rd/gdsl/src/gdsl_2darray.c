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
 * $RCSfile: gdsl_2darray.c,v $
 * $Revision: 1.18 $
 * $Date: 2006/03/04 16:32:05 $
 */


#include <config.h>


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>


#include "gdsl_2darray.h"
#include "gdsl_types.h"


struct gdsl_2darray
{
    char*             name;
    ulong             rows;
    ulong             cols;
    gdsl_element_t**  elements;

    gdsl_alloc_func_t alloc_f;
    gdsl_free_func_t  free_f;
};

static gdsl_element_t 
default_alloc (void* e);

static void 
default_free (gdsl_element_t e);

/******************************************************************************/
/* Management functions of 2D-arrays                                          */
/******************************************************************************/

extern gdsl_2darray_t
gdsl_2darray_alloc (const char* name, const ulong l, const ulong c,
		    const gdsl_alloc_func_t alloc_f, 
		    const gdsl_free_func_t free_f)
{
    register ulong i;
    gdsl_2darray_t m;

    m = (gdsl_2darray_t) malloc (sizeof (struct gdsl_2darray));

    if (m == NULL)
	{
	    return NULL;
	}

    m->name = NULL;

    if (gdsl_2darray_set_name (m, name) == NULL)
	{
	    free (m);
	    return NULL;
	}

    m->rows = l;
    m->cols = c;

    m->elements = (gdsl_element_t**) calloc (l, sizeof (gdsl_element_t*));

    if (m->elements == NULL)
	{
	    free (m->name);
	    free (m);
	    return NULL;
	}

    (m->elements) [0] = (gdsl_element_t*) calloc (l * c, sizeof (gdsl_element_t));

    if ((m->elements) [0] == NULL)
	{
	    free (m->name);
	    free (m->elements);
	    free (m);
	    return NULL;
	}

    for (i = 1; i < l; i++)
	{
	    (m->elements)[i] = (m->elements) [i-1] + c;
	}
  
    m->alloc_f = alloc_f ? alloc_f : default_alloc;
    m->free_f  = free_f  ? free_f  : default_free;

    return m;
}

extern void 
gdsl_2darray_free (gdsl_2darray_t m)
{
    register ulong i;

    assert (m != NULL);

    for (i = 0; i < m->rows * m->cols; i++)
	{
	    (m->free_f) ((m->elements) [0][i]);
	}

    free ((m->elements)[0]);
    free (m->elements);
    free (m->name);
    free (m);
}

/******************************************************************************/
/* Consultation functions of 2D-arrays                                        */
/******************************************************************************/

extern const char*
gdsl_2darray_get_name (const gdsl_2darray_t m)
{
    assert (m != NULL);

    return m->name;
}

extern ulong
gdsl_2darray_get_rows_number (const gdsl_2darray_t a)
{
    assert (a != NULL);

    return a->rows;
}

extern ulong
gdsl_2darray_get_columns_number (const gdsl_2darray_t a)
{
    assert (a != NULL);

    return a->cols;
}

extern ulong
gdsl_2darray_get_size (const gdsl_2darray_t a)
{
    assert (a != NULL);

    return a->rows * a->cols;
}

extern gdsl_element_t
gdsl_2darray_get_content (const gdsl_2darray_t a, const ulong l, const ulong c)
{
    assert (a != NULL);
    assert (l <= a->rows);
    assert (c <= a->cols);

    return (a->elements) [l][c];
}

/******************************************************************************/
/* Modification functions of 2D-arrays                                        */
/******************************************************************************/

extern gdsl_2darray_t
gdsl_2darray_set_name (gdsl_2darray_t m, const char* name)
{
    assert (m != NULL);

    if (m->name != NULL)
	{
	    free (m->name);
	    m->name = NULL;
	}

    if (name != NULL)
	{
	    m->name = (char*) malloc ((1 + strlen (name)) * sizeof (char));

	    if (m->name == NULL)
		{
		    return NULL;
		}

	    strcpy (m->name, name);
	}

    return m;
}

extern gdsl_element_t
gdsl_2darray_set_content (gdsl_2darray_t a, const ulong l, const ulong c, 
			  void* value)
{
    assert (a != NULL);
    assert (l <= a->rows);
    assert (c <= a->cols);

    (a->elements) [l][c] = (a->alloc_f) (value);

    return (a->elements) [l][c];
}

/******************************************************************************/
/* Input/output functions of 2D-arrays                                        */
/******************************************************************************/

extern void
gdsl_2darray_write (const gdsl_2darray_t a, 
		    const gdsl_write_func_t write_f, FILE* file, 
		    void* user_data)
{
    ulong i;
    ulong j;
    gdsl_location_t pos;

    assert (a != NULL);
    assert (write_f != NULL);
    assert (file != NULL);

    /* 1. First row */

    /* 1.1 First column */
    pos = GDSL_LOCATION_FIRST_ROW | GDSL_LOCATION_FIRST_COL;
    write_f ((a->elements) [0][0], file, pos, user_data);

    /* 1.2 Other columns but last */
    pos &= ~GDSL_LOCATION_FIRST_COL;
    for (j = 1; j < a->cols - 1; j++)
	{
	    write_f ((a->elements) [0][j], file, pos, user_data);
	}

    /* 1.3 Last column */
    pos |= GDSL_LOCATION_LAST_COL;
    write_f ((a->elements) [0][j], file, pos, user_data);
    pos &= ~GDSL_LOCATION_LAST_COL;

    /* 2. Other rows but last */
    pos &= ~GDSL_LOCATION_FIRST_ROW;
    for (i = 1; i < a->rows - 1; i++)
	{
	    /* 2.1 First column */
	    pos |= GDSL_LOCATION_FIRST_COL;
	    write_f ((a->elements) [i][0], file, pos, user_data);

	    /* 2.2 Other columns but last */
	    pos &= ~GDSL_LOCATION_FIRST_COL;
 	    for (j = 1; j < a->cols - 1; j++)
		{
		    write_f ((a->elements) [i][j], file, pos, user_data);
		}

	    /* 2.3 Last column */
	    pos |= GDSL_LOCATION_LAST_COL;
	    write_f ((a->elements) [i][j], file, pos, user_data);
	    pos &= ~GDSL_LOCATION_LAST_COL;
	}
    
    /* 3. Last row */

    /* 3.1 First column */
    pos = GDSL_LOCATION_LAST_ROW | GDSL_LOCATION_FIRST_COL;
    write_f ((a->elements) [i][0], file, pos, user_data);

    /* 3.2 Other columns but last */
    pos &= ~GDSL_LOCATION_FIRST_COL;
    for (j = 1; j < a->cols - 1; j++)
	{
	    write_f ((a->elements) [i][j], file, pos, user_data);
	}

    /* 3.3 Last column */
    pos |= GDSL_LOCATION_LAST_COL;
    write_f ((a->elements) [i][j], file, pos, user_data);
}

extern void
gdsl_2darray_write_xml (const gdsl_2darray_t a, 
			const gdsl_write_func_t write_f, FILE* file, 
			void* user_data)
{
    ulong i;
    ulong j;
    gdsl_location_t pos;

    assert (a != NULL);
    assert (file != NULL);

    fprintf (file, "<GDSL_2DARRAY REF=\"%p\" NAME=", (void*) a);

    if (a->name == NULL)
	{
	    fprintf (file, "\"\"");
	}
    else
	{
	    fprintf (file, "\"%s\"", a->name);
	}

    fprintf (file, " ROWS=\"%ld\" COLS=\"%ld\">\n", a->rows, a->cols);

    /* 1. First row */

    /* 1.1 First column */
    pos = GDSL_LOCATION_FIRST_ROW | GDSL_LOCATION_FIRST_COL;
    fprintf (file, "<GDSL_2DARRAY_ROW VALUE=\"0\">\n");
    fprintf (file, "<GDSL_2DARRAY_COL VALUE=\"0\">");
    if (write_f != NULL)
	{
	    write_f ((a->elements) [0][0], file, pos, user_data);
	}
    fprintf (file, "</GDSL_2DARRAY_COL>\n");

    /* 1.2 Other columns but last */
    pos &= ~GDSL_LOCATION_FIRST_COL;
    for (j = 1; j < a->cols - 1; j++)
	{
	    fprintf (file, "<GDSL_2DARRAY_COL VALUE=\"%ld\">", j);
	    if (write_f != NULL)
		{
		    write_f ((a->elements) [0][j], file, pos, user_data);
		}
	    fprintf (file, "</GDSL_2DARRAY_COL>\n");
	}

    /* 1.3 Last column */
    pos |= GDSL_LOCATION_LAST_COL;
    fprintf (file, "<GDSL_2DARRAY_COL VALUE=\"%ld\">", j);
    if (write_f != NULL)
	{
	    write_f ((a->elements) [0][j], file, pos, user_data);
	}
    fprintf (file, "</GDSL_2DARRAY_COL>\n");
    fprintf (file, "</GDSL_2DARRAY_ROW>\n");
    pos &= ~GDSL_LOCATION_LAST_COL;

    /* 2. Other rows but last */
    pos &= ~GDSL_LOCATION_FIRST_ROW;
    for (i = 1; i < a->rows - 1; i++)
	{
	    /* 2.1 First column */
	    pos |= GDSL_LOCATION_FIRST_COL;
	    fprintf (file, "<GDSL_2DARRAY_ROW VALUE=\"%ld\">\n", i);
	    fprintf (file, "<GDSL_2DARRAY_COL VALUE=\"0\">");
	    if (write_f != NULL)
		{
		    write_f ((a->elements) [i][0], file, pos, user_data);
		}
	    fprintf (file, "</GDSL_2DARRAY_COL>\n");

	    /* 2.2 Other columns but last */
	    pos &= ~GDSL_LOCATION_FIRST_COL;
	    for (j = 1; j < a->cols - 1; j++)
		{
		    fprintf (file, "<GDSL_2DARRAY_COL VALUE=\"%ld\">", j);
		    if (write_f != NULL)
			{
			    write_f ((a->elements) [i][j], file, pos, user_data);
			}
		    fprintf (file, "</GDSL_2DARRAY_COL>\n");
		}

	    /* 2.3 Last column */
	    pos |= GDSL_LOCATION_LAST_COL;
	    fprintf (file, "<GDSL_2DARRAY_COL VALUE=\"%ld\">", j);
	    if (write_f != NULL)
		{
		    write_f ((a->elements) [i][j], file, pos, user_data);
		}
	    fprintf (file, "</GDSL_2DARRAY_COL>\n");
	    fprintf (file, "</GDSL_2DARRAY_ROW>\n");
	    pos &= ~GDSL_LOCATION_LAST_COL;
	}

    /* 3. Last row */

    /* 3.1 First column */
    pos = GDSL_LOCATION_LAST_ROW | GDSL_LOCATION_FIRST_COL;
    fprintf (file, "<GDSL_2DARRAY_ROW VALUE=\"%ld\">\n", i);
    fprintf (file, "<GDSL_2DARRAY_COL VALUE=\"0\">");
    if (write_f != NULL)
	{
	    write_f ((a->elements) [i][0], file, pos, user_data);
	}
    fprintf (file, "</GDSL_2DARRAY_COL>\n");

    /* 3.2 Other columns but last */
    pos &= ~GDSL_LOCATION_FIRST_COL;
    for (j = 1; j < a->cols - 1; j++)
	{
	    fprintf (file, "<GDSL_2DARRAY_COL VALUE=\"%ld\">", j);
	    if (write_f != NULL)
		{
		    write_f ((a->elements) [i][j], file, pos, user_data);
		}
	    fprintf (file, "</GDSL_2DARRAY_COL>\n");

	}

    /* 3.3 Last column */
    pos |= GDSL_LOCATION_LAST_COL;
    fprintf (file, "<GDSL_2DARRAY_COL VALUE=\"%ld\">", j);
    if (write_f != NULL)
	{
	    write_f ((a->elements) [i][j], file, pos, user_data);
	}
    fprintf (file, "</GDSL_2DARRAY_COL>\n");
    fprintf (file, "</GDSL_2DARRAY_ROW>\n");

    fprintf (file, "</GDSL_2DARRAY>\n");
}

extern void
gdsl_2darray_dump (const gdsl_2darray_t a, const gdsl_write_func_t write_f, 
		   FILE* file, void* user_data)
{
    ulong i;
    ulong j;
    gdsl_location_t pos;

    assert (a != NULL);
    assert (file != NULL);

    fprintf (file, "<GDSL_2DARRAY REF=\"%p\" NAME=", (void*) a);

    if (a->name == NULL)
	{
	    fprintf (file, "\"\"");
	}
    else
	{
	    fprintf (file, "\"%s\"", a->name);
	}

    fprintf (file, " ROWS=\"%ld\" COLS=\"%ld\">\n", a->rows, a->cols);

    /* 1. First row */

    /* 1.1 First column */
    pos = GDSL_LOCATION_FIRST_ROW | GDSL_LOCATION_FIRST_COL;
    fprintf (file, "<GDSL_2DARRAY_ROW VALUE=\"0\">\n");
    fprintf (file, "<GDSL_2DARRAY_COL VALUE=\"0\" CONTENT=\"%p\">", (a->elements) [0][0]);
    if (write_f != NULL)
	{
	    write_f ((a->elements) [0][0], file, pos, user_data);
	}
    fprintf (file, "</GDSL_2DARRAY_COL>\n");

    /* 1.2 Other columns but last */
    pos &= ~GDSL_LOCATION_FIRST_COL;
    for (j = 1; j < a->cols - 1; j++)
	{
	    fprintf (file, "<GDSL_2DARRAY_COL VALUE=\"%ld\" CONTENT=\"%p\">", j, (a->elements) [0][j]);
	    if (write_f != NULL)
		{
		    write_f ((a->elements) [0][j], file, pos, user_data);
		}
	    fprintf (file, "</GDSL_2DARRAY_COL>\n");
	}

    /* 1.3 Last column */
    pos |= GDSL_LOCATION_LAST_COL;
    fprintf (file, "<GDSL_2DARRAY_COL VALUE=\"%ld\" CONTENT=\"%p\">", j, (a->elements) [0][j]);
    if (write_f != NULL)
	{
	    write_f ((a->elements) [0][j], file, pos, user_data);
	}
    fprintf (file, "</GDSL_2DARRAY_COL>\n");
    fprintf (file, "</GDSL_2DARRAY_ROW>\n");
    pos &= ~GDSL_LOCATION_LAST_COL;

    /* 2. Other rows but last */
    pos &= ~GDSL_LOCATION_FIRST_ROW;
    for (i = 1; i < a->rows - 1; i++)
	{
	    /* 2.1 First column */
	    pos |= GDSL_LOCATION_FIRST_COL;
	    fprintf (file, "<GDSL_2DARRAY_ROW VALUE=\"%ld\">\n", i);
	    fprintf (file, "<GDSL_2DARRAY_COL VALUE=\"0\" CONTENT=\"%p\">", (a->elements) [i][0]);
	    if (write_f != NULL)
		{
		    write_f ((a->elements) [i][0], file, pos, user_data);
		}
	    fprintf (file, "</GDSL_2DARRAY_COL>\n");

	    /* 2.2 Other columns but last */
	    pos &= ~GDSL_LOCATION_FIRST_COL;
	    for (j = 1; j < a->cols - 1; j++)
		{
		    fprintf (file, "<GDSL_2DARRAY_COL VALUE=\"%ld\" CONTENT=\"%p\">", j, (a->elements) [i][j]);
		    if (write_f != NULL)
			{
			    write_f ((a->elements) [i][j], file, pos, user_data);
			}
		    fprintf (file, "</GDSL_2DARRAY_COL>\n");
		}

	    /* 2.3 Last column */
	    pos |= GDSL_LOCATION_LAST_COL;
	    fprintf (file, "<GDSL_2DARRAY_COL VALUE=\"%ld\" CONTENT=\"%p\">", j, (a->elements) [i][j]);
	    if (write_f != NULL)
		{
		    write_f ((a->elements) [i][j], file, pos, user_data);
		}
	    fprintf (file, "</GDSL_2DARRAY_COL>\n");
	    fprintf (file, "</GDSL_2DARRAY_ROW>\n");
	    pos &= ~GDSL_LOCATION_LAST_COL;
	}

    /* 3. Last row */

    /* 3.1 First column */
    pos = GDSL_LOCATION_LAST_ROW | GDSL_LOCATION_FIRST_COL;
    fprintf (file, "<GDSL_2DARRAY_ROW VALUE=\"%ld\">\n", i);
    fprintf (file, "<GDSL_2DARRAY_COL VALUE=\"0\" CONTENT=\"%p\">", (a->elements) [i][0]);
    if (write_f != NULL)
	{
	    write_f ((a->elements) [i][0], file, pos, user_data);
	}
    fprintf (file, "</GDSL_2DARRAY_COL>\n");

    /* 3.2 Other columns but last */
    pos &= ~GDSL_LOCATION_FIRST_COL;
    for (j = 1; j < a->cols - 1; j++)
	{
	    fprintf (file, "<GDSL_2DARRAY_COL VALUE=\"%ld\" CONTENT=\"%p\">", j, (a->elements) [i][j]);
	    if (write_f != NULL)
		{
		    write_f ((a->elements) [i][j], file, pos, user_data);
		}
	    fprintf (file, "</GDSL_2DARRAY_COL>\n");

	}

    /* 3.3 Last column */
    pos |= GDSL_LOCATION_LAST_COL;
    fprintf (file, "<GDSL_2DARRAY_COL VALUE=\"%ld\" CONTENT=\"%p\">", j, (a->elements) [i][j]);
    if (write_f != NULL)
	{
	    write_f ((a->elements) [i][j], file, pos, user_data);
	}
    fprintf (file, "</GDSL_2DARRAY_COL>\n");
    fprintf (file, "</GDSL_2DARRAY_ROW>\n");

    fprintf (file, "</GDSL_2DARRAY>\n");
}

/******************************************************************************/
/* Private functions                                                          */
/******************************************************************************/

static gdsl_element_t 
default_alloc (void* e)
{
    return e;
}

static void 
default_free (gdsl_element_t e)
{
    ;
}


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
