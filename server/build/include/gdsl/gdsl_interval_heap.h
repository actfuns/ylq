/*
 * This file is part of the Generic Data Structures Library (GDSL).
 * Copyright (C) 1998-2013 Nicolas Darnis <ndarnis@free.fr>.
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
 * $RCSfile: gdsl_interval_heap.h,v $
 * $Revision: 1.2 $
 * $Date: 2013/06/12 16:36:13 $
 */


#ifndef _GDSL_INTERVAL_HEAP_H_
#define _GDSL_INTERVAL_HEAP_H_


#include <stdio.h>


#include "gdsl_types.h"

#ifdef __cplusplus
extern "C" 
{
#endif /* __cplusplus */


/**
 * @defgroup gdsl_interval_heap Interval Heap manipulation module
 * @{
 */


/**
 * @brief GDSL interval heap type.
 *
 * This type is voluntary opaque. Variables of this kind couldn't be directly
 * used, but by the functions of this module.
 */
typedef struct heap* gdsl_interval_heap_t;

/******************************************************************************/
/* Management functions of heaps                                              */
/******************************************************************************/

/**
 * @brief Create a new interval heap.
 *
 * Allocate a new interval heap data structure which name is set to a copy of NAME.
 * The function pointers ALLOC_F, FREE_F and COMP_F could be used to 
 * respectively, alloc, free and compares elements in the interval heap. These pointers 
 * could be set to NULL to use the default ones:
 * - the default ALLOC_F simply returns its argument
 * - the default FREE_F does nothing
 * - the default COMP_F always returns 0
 *
 * @note Complexity: O( 1 )
 * @pre nothing
 * @param NAME The name of the new interval heap to create
 * @param ALLOC_F Function to alloc element when inserting it in the interval heap
 * @param FREE_F Function to free element when removing it from the interval heap
 * @param COMP_F Function to compare elements into the interval heap
 * @return the newly allocated interval heap in case of success.
 * @return NULL in case of insufficient memory.
 * @see gdsl_interval_heap_free()
 * @see gdsl_interval_heap_flush()
 */
extern gdsl_interval_heap_t
gdsl_interval_heap_alloc (const char* NAME,
			  gdsl_alloc_func_t ALLOC_F,
			  gdsl_free_func_t FREE_F,
			  gdsl_compare_func_t COMP_F
			  );

/**
 * @brief Destroy an interval heap.
 * 
 * Deallocate all the elements of the interval heap H by calling H's FREE_F function
 * passed to gdsl_interval_heap_alloc(). The name of H is deallocated and H is 
 * deallocated itself too.
 *
 * @note Complexity: O( |H| )
 * @pre H must be a valid gdsl_interval_heap_t
 * @param H The interval heap to destroy
 * @see gdsl_interval_heap_alloc()
 * @see gdsl_interval_heap_flush()
 */
extern void
gdsl_interval_heap_free (gdsl_interval_heap_t H
			 );

/**
 * @brief Flush an interval heap.
 *
 * Deallocate all the elements of the interval heap H by calling H's FREE_F function
 * passed to gdsl_interval_heap_alloc(). H is not deallocated itself and H's name is not
 * modified.
 *
 * @note Complexity: O( |H| )
 * @pre H must be a valid gdsl_interval_heap_t
 * @param H The heap to flush
 * @see gdsl_interval_heap_alloc()
 * @see gdsl_interval_heap_free()
 */
extern void
gdsl_interval_heap_flush (gdsl_interval_heap_t H
			  );

/******************************************************************************/
/* Consultation functions of interval heaps                                   */
/******************************************************************************/

/**
 * @brief Get the name of an interval heap.
 * @note Complexity: O( 1 )
 * @pre H must be a valid gdsl_interval_heap_t
 * @post The returned string MUST NOT be freed.
 * @param H The interval heap to get the name from
 * @return the name of the interval heap H.
 * @see gdsl_interval_heap_set_name()
 */
extern const char*
gdsl_interval_heap_get_name (const gdsl_interval_heap_t H
			     );

/**
 * @brief Get the size of a interval heap.
 * @note Complexity: O( 1 )
 * @pre H must be a valid gdsl_interval_heap_t
 * @param H The interval heap to get the size from
 * @return the number of elements of H (noted |H|).
 */
extern ulong
gdsl_interval_heap_get_size (const gdsl_interval_heap_t H
			     );

/**
 * @brief Set the maximum size of the interval heap.
 * @note Complexity: O( 1 )
 * @pre H must be a valid gdsl_interval_heap_t
 * @param H The interval heap to get the size from
 * @param size The new maximum size
 * @return the number of elements of H (noted |H|).
 */
extern  void
gdsl_interval_heap_set_max_size (const gdsl_interval_heap_t H,
				 ulong size);

/**
 *
 * @brief Check if an interval heap is empty.
 * @note Complexity: O( 1 )
 * @pre H must be a valid gdsl_interval_heap_t
 * @param H The interval heap to check
 * @return TRUE if the interval heap H is empty.
 * @return FALSE if the interval heap H is not empty.
 */
extern bool 
gdsl_interval_heap_is_empty (const gdsl_interval_heap_t H
			     );

/******************************************************************************/
/* Modification functions of interval heaps                                   */
/******************************************************************************/
  
/**
 * @brief Set the name of an interval heap.
 *
 * Change the previous name of the interval heap H to a copy of NEW_NAME.
 * 
 * @note Complexity: O( 1 )
 * @pre H must be a valid gdsl_interval_heap_t
 * @param H The interval heap to change the name
 * @param NEW_NAME The new name of H
 * @return the modified interval heap in case of success.
 * @return NULL in case of insufficient memory.
 * @see gdsl_interval_heap_get_name()
 */
extern gdsl_interval_heap_t
gdsl_interval_heap_set_name (gdsl_interval_heap_t H,
			     const char* NEW_NAME
			     );


/**
 * @brief Insert an element into an interval heap (PUSH).
 * 
 * Allocate a new element E by calling H's ALLOC_F function on VALUE.
 * The element E is then inserted into H at the good position to ensure H is
 * always an interval heap.
 *
 * @note Complexity: O( log ( |H| ) )
 * @pre H must be a valid gdsl_interval_heap_t
 * @param H The interval heap to modify
 * @param VALUE The value used to make the new element to insert into H
 * @return the inserted element E in case of success.
 * @return NULL in case of insufficient memory.
 * @see gdsl_interval_heap_alloc()
 * @see gdsl_interval_heap_remove()
 * @see gdsl_interval_heap_delete()
 * @see gdsl_interval_heap_get_size()
 */
extern gdsl_element_t
gdsl_interval_heap_insert (gdsl_interval_heap_t H,
			   void* VALUE
			   );

/**
 * @brief Remove the maximum element from an interval heap (POP).
 *
 * Remove the maximum element from the interval heap H. The element is removed from H and
 * is also returned.
 *
 * @note Complexity: O( log ( |H| ) )
 * @pre H must be a valid gdsl_interval_heap_t
 * @param H The interval heap to modify
 * @return the removed top element.
 * @return NULL if the interval heap is empty.
 * @see gdsl_interval_heap_insert()
 * @see gdsl_interval_heap_delete_max()
 */
extern gdsl_element_t
gdsl_interval_heap_remove_max (gdsl_interval_heap_t H
			       );

/**
 * @brief Remove the minimum element from an interval heap (POP).
 *
 * Remove the minimum element from the interval heap H. The element is removed from H and
 * is also returned.
 *
 * @note Complexity: O( log ( |H| ) )
 * @pre H must be a valid gdsl_interval_heap_t
 * @param H The interval heap to modify
 * @return the removed top element.
 * @return NULL if the interval heap is empty.
 * @see gdsl_interval_heap_insert()
 * @see gdsl_interval_heap_delete_max()
 */
extern gdsl_element_t
gdsl_interval_heap_remove_min (gdsl_interval_heap_t H
			       );

/**
 * @brief Get the minimum element.
 * @note Complexity: O( 1 )
 * @pre H must be a valid gdsl_interval_heap_t
 * @param H The interval heap to get the size from
 * @return The smallest element in H
 */
extern gdsl_element_t
gdsl_interval_heap_get_min (const gdsl_interval_heap_t H
			    );

/**
 * @brief Get the maximum element.
 * @note Complexity: O( 1 )
 * @pre H must be a valid gdsl_interval_heap_t
 * @param H The interval heap to get the size from
 * @return The largest element in H
 */
extern gdsl_element_t
gdsl_interval_heap_get_max (const gdsl_interval_heap_t H
			    );

/**
 * @brief Delete the minimum element from an interval heap.
 *
 * Remove the minimum element from the interval heap H. The element is removed from H and
 * is also deallocated using H's FREE_F function passed to gdsl_interval_heap_alloc(),
 * then H is returned.
 *
 * @note Complexity: O( log ( |H| ) )
 * @pre H must be a valid gdsl_interval_heap_t
 * @param H The interval heap to modify
 * @return the modified interval heap after removal of top element.
 * @return NULL if interval heap is empty.
 * @see gdsl_interval_heap_insert()
 * @see gdsl_interval_heap_remove_top()
 */
extern gdsl_interval_heap_t
gdsl_interval_heap_delete_min (gdsl_interval_heap_t H
			       );

/**
 * @brief Delete the maximum element from an interval heap.
 *
 * Remove the maximum element from the interval heap H. The element is removed from H and
 * is also deallocated using H's FREE_F function passed to gdsl_interval_heap_alloc(),
 * then H is returned.
 *
 * @note Complexity: O( log ( |H| ) )
 * @pre H must be a valid gdsl_interval_heap_t
 * @param H The interval heap to modify
 * @return the modified interval heap after removal of top element.
 * @return NULL if interval heap is empty.
 * @see gdsl_interval_heap_insert()
 * @see gdsl_interval_heap_remove_top()
 */
extern gdsl_interval_heap_t
gdsl_interval_heap_delete_max (gdsl_interval_heap_t H
			       );

/******************************************************************************/
/* Parse functions of interval heaps                                          */
/******************************************************************************/

/**
 * @brief Parse a interval heap.
 *
 * Parse all elements of the interval heap H. The MAP_F function is called on each 
 * H's element with USER_DATA argument. If MAP_F returns GDSL_MAP_STOP then
 * gdsl_interval_heap_map() stops and returns its last examinated element.
 *
 * @note Complexity: O( |H| )
 * @pre H must be a valid gdsl_interval_heap_t & MAP_F != NULL
 * @param H The interval heap to map
 * @param MAP_F The map function.
 * @param USER_DATA User's datas passed to MAP_F
 * @return the first element for which MAP_F returns GDSL_MAP_STOP.
 * @return NULL when the parsing is done.
 */
extern gdsl_element_t
gdsl_interval_heap_map_forward (const gdsl_interval_heap_t H,
				gdsl_map_func_t MAP_F,
				void* USER_DATA
				);

/******************************************************************************/
/* Input/output functions of interval heaps                                   */
/******************************************************************************/

/**
 * @brief Write all the elements of an interval heap to a file.
 *
 * Write the elements of the interval heap H to OUTPUT_FILE, using WRITE_F function.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |H| )
 * @pre H must be a valid gdsl_interval_heap_t & OUTPUT_FILE != NULL & WRITE_F != NULL
 * @param H The interval heap to write.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write H's elements.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see gdsl_interval_heap_write_xml()
 * @see gdsl_interval_heap_dump()
 */
extern void
gdsl_interval_heap_write (const gdsl_interval_heap_t H,
			  gdsl_write_func_t WRITE_F,
			  FILE* OUTPUT_FILE,
			  void* USER_DATA
			  );

/**
 * @brief Write the content of an interval heap to a file into XML.
 *
 * Write the elements of the interval heap H to OUTPUT_FILE, into XML language.
 * If WRITE_F != NULL, then uses WRITE_F to write H's elements to OUTPUT_FILE.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |H| )
 * @pre H must be a valid gdsl_interval_heap_t & OUTPUT_FILE != NULL
 * @param H The interval heap to write.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write H's elements.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see gdsl_interval_heap_write()
 * @see gdsl_interval_heap_dump()
 */
extern void
gdsl_interval_heap_write_xml (const gdsl_interval_heap_t H,
			      gdsl_write_func_t WRITE_F,
			      FILE* OUTPUT_FILE,
			      void* USER_DATA
			      );

/**
 * @brief Dump the internal structure of an interval heap to a file.
 *
 * Dump the structure of the interval heap H to OUTPUT_FILE. If WRITE_F != NULL,
 * then uses WRITE_F to write H's elements to OUTPUT_FILE.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |H| )
 * @pre H must be a valid gdsl_interval_heap_t & OUTPUT_FILE != NULL
 * @param H The interval heap to write
 * @param WRITE_F The write function
 * @param OUTPUT_FILE The file where to write H's elements
 * @param USER_DATA User's datas passed to WRITE_F
 * @see gdsl_interval_heap_write()
 * @see gdsl_interval_heap_write_xml()
 */
extern void
gdsl_interval_heap_dump (const gdsl_interval_heap_t H,
			 gdsl_write_func_t WRITE_F,
			 FILE* OUTPUT_FILE,
			 void* USER_DATA
			 );

/*
 * @}
 */


#ifdef __cplusplus
}
#endif /* __cplusplus */


#endif /* _GDSL_INTERVAL_HEAP_H_ */


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */

