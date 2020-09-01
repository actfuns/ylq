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
 * $RCSfile: main_interval_heap.c,v $
 * $Revision: 1.2 $
 * $Date: 2013/06/12 16:36:13 $
 */


#include <config.h>

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#include "gdsl_types.h"
#include "gdsl_interval_heap.h"


#include "_integers.h"


static int 
my_display_integer (const gdsl_element_t e, gdsl_location_t location, 
		    void* user_infos)
{
    //printf ("user_info: %d\n", *(int *)user_infos);
    printf ("%s%s%ld ", 
	    (location & GDSL_LOCATION_ROOT) ? "[root]: " : "",
	    (location & GDSL_LOCATION_LEAF) ? "[leaf]: " : "",
	    *(long int*) e);
    return GDSL_MAP_CONT;
}

void insert_value(gdsl_interval_heap_t h, long int a) {
        //int value = rand() % 20;
        long int *value = malloc(sizeof(int));
        //*value = rand() % 20;
        *value = a;
        //printf("inserting value: %d\n", *value);
        gdsl_interval_heap_insert(h, (void *) value);
        //gdsl_raw_heap_dump(h);
        //gdsl_check_interval_heap_integrity(h);
}

long *remove_max(gdsl_interval_heap_t h) {
    long *value;
    //printf("removing max\n");
    //gdsl_raw_heap_dump(h);
    value = gdsl_interval_heap_remove_max(h);
    //printf("removed value: %x %d\n", value, *value);
    //gdsl_raw_heap_dump(h);
    //gdsl_check_interval_heap_integrity(h);

    return value;
}

long *remove_min(gdsl_interval_heap_t h) {
    long *value;
    //printf("removing min\n");
    //gdsl_raw_heap_dump(h);
    value = gdsl_interval_heap_remove_min(h);
    //printf("removed value: %x %d\n", value, *value);
    //gdsl_raw_heap_dump(h);
    //gdsl_check_interval_heap_integrity(h);

    return value;
}

void test1() {
    gdsl_interval_heap_t h = gdsl_interval_heap_alloc ("H", alloc_integer, free_integer, compare_integers);

    insert_value(h, 2);
    insert_value(h, 30);
    insert_value(h, 3);
    insert_value(h, 20);
    insert_value(h, 4);
    insert_value(h, 25);
    insert_value(h, 8);
    insert_value(h, 16);
    insert_value(h, 4);
    //exit(0);
    insert_value(h, 10);
    insert_value(h, 10);
    insert_value(h, 15);
    insert_value(h, 5);
    insert_value(h, 12);
    insert_value(h, 8);
    insert_value(h, 16);
    insert_value(h, 9);
    insert_value(h, 15);
    insert_value(h, 5);

    /** Documented tests **/
    insert_value(h, 1);
    insert_value(h, 25);

    remove_min(h);

    remove_max(h);

    remove_min(h);
    remove_min(h);
    remove_min(h);
    remove_min(h);

    gdsl_interval_heap_flush(h);

    assert(gdsl_interval_heap_get_size(h) == 0);

    gdsl_interval_heap_free (h);

}

void test2() {
    gdsl_interval_heap_t h = gdsl_interval_heap_alloc ("H", alloc_integer, free_integer, compare_integers);

    gdsl_interval_heap_flush(h);

    insert_value(h, 2);
    insert_value(h, 2);
    insert_value(h, 2);

    //remove_min(h);
    remove_max(h);
    remove_max(h);
    remove_max(h);
    //remove_min(h);
    //remove_min(h);

    assert(gdsl_interval_heap_get_size(h) == 0);

    gdsl_interval_heap_free (h);
}

void check_removed(long **removed, int len) {
    int i, j;
    for (i = 0; i < len; i++) {
        for (j = i+1; j < len; j++) {
            assert(removed[i] != removed[j]);
        }
    }

    //printf("checked removed\n");
}

void test3() {
    int i, len=2000;
    long *e;
    gdsl_interval_heap_t h = gdsl_interval_heap_alloc ("H", alloc_integer, free_integer, compare_integers);
    gdsl_interval_heap_flush(h);
    long **removed = malloc(len * sizeof(long *));

    for (i = 0; i < len; i++) {
        insert_value(h, rand() % 20);
    }

    for (i = 0; i < len/2; i++) {
        if (i % 2 == 0)
            e = remove_min(h);
        else
            e = remove_max(h);

        removed[i] = e;
    }

    check_removed(removed, len/2);

    for (i = 0; i < len/2; i++) {
        insert_value(h, rand() % 20);
    }

    for (i = 0; i < len; i++) {
        if (i % 2 == 0)
            e = remove_min(h);
        else
            e = remove_max(h);

        removed[i] = e;
    }

    check_removed(removed, len/2);

    assert(gdsl_interval_heap_get_size(h) == 0);
    gdsl_interval_heap_free (h);
}

int test4() {
    int i = 0, len = 20000; 

    gdsl_interval_heap_t h = gdsl_interval_heap_alloc ("H", alloc_integer, free_integer, compare_integers);
    gdsl_interval_heap_flush(h);

    for (i = 0; i < len; i++) {
        if (rand() % 2 == 0) {
            insert_value(h, rand() % 40);
        } else {
            if (gdsl_interval_heap_get_size(h) > 1) {
                if (rand() % 2 == 0)
                    remove_min(h);
                else
                    remove_max(h);
            }

        }

    }

    //assert(gdsl_interval_heap_get_size(h) == 0);
    gdsl_interval_heap_free (h);
}

int main (void)
{
    //test2();
    //test3();
    test4();
    exit (EXIT_SUCCESS);
}


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
