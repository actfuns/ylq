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
 * $RCSfile: gdsl_list.h,v $
 * $Revision: 1.25 $
 * $Date: 2006/03/04 16:32:05 $
 */


#ifndef _GDSL_LIST_H_
#define _GDSL_LIST_H_

#include <stdio.h>

#include "gdsl_types.h"

#ifdef __cplusplus
extern "C" 
{
#endif


/**
 * @defgroup gdsl_list Doubly-linked list manipulation module
 * @{
 */


/**
 * @brief GDSL doubly-linked list type.
 *
 * This type is voluntary opaque. Variables of this kind could'nt be directly
 * used, but by the functions of this module.
 */
typedef struct _gdsl_list* gdsl_list_t;

/**
 * @brief GDSL doubly-linked list cursor type.
 *
 * This type is voluntary opaque. Variables of this kind could'nt be directly
 * used, but by the functions of this module.
 */
typedef struct _gdsl_list_cursor* gdsl_list_cursor_t;

/******************************************************************************/
/* Management functions of doubly-linked lists                                */
/******************************************************************************/

/**
 * @brief Create a new list.
 *
 * Allocate a new list data structure which name is set to a copy of NAME.
 * The function pointers ALLOC_F and FREE_F could be used to respectively, alloc
 * and free elements in the list. These pointers could be set to NULL to use the
 * default ones:
 * - the default ALLOC_F simply returns its argument
 * - the default FREE_F does nothing
 *
 * @note Complexity: O( 1 )
 * @pre nothing
 * @param NAME The name of the new list to create
 * @param ALLOC_F Function to alloc element when inserting it in the list
 * @param FREE_F Function to free element when removing it from the list
 * @return the newly allocated list in case of success.
 * @return NULL in case of insufficient memory.
 * @see gdsl_list_free()
 * @see gdsl_list_flush()
 */
extern gdsl_list_t
gdsl_list_alloc (const char* NAME,
		 gdsl_alloc_func_t ALLOC_F,
		 gdsl_free_func_t FREE_F
		 );

/**
 * @brief Destroy a list.
 *
 * Flush and destroy the list L. All the elements of L are freed using L's 
 * FREE_F function passed to gdsl_list_alloc(). 
 *
 * @note Complexity: O( |L| )
 * @pre L must be a valid gdsl_list_t
 * @param L The list to destroy
 * @see gdsl_list_alloc()
 * @see gdsl_list_flush()
 */
extern void 
gdsl_list_free (gdsl_list_t L
		);

/**
 * @brief Flush a list.
 *
 * Destroy all the elements of the list L by calling L's FREE_F function passed
 * to gdsl_list_alloc(). L is not deallocated itself and L's name is not 
 * modified.
 *
 * @note Complexity: O( |L| )
 * @pre L must be a valid gdsl_list_t
 * @param L The list to flush
 * @see gdsl_list_alloc()
 * @see gdsl_list_free()
 */
extern void
gdsl_list_flush (gdsl_list_t L
		 );

/******************************************************************************/
/* Consultation functions of doubly-linked lists                              */
/******************************************************************************/

/** 
 * @brief Get the name of a list.
 * @note Complexity: O( 1 )
 * @pre L must be a valid gdsl_list_t
 * @post The returned string MUST NOT be freed.
 * @param L The list to get the name from
 * @return the name of the list L.
 * @see gdsl_list_set_name()
 */
extern const char*
gdsl_list_get_name (const gdsl_list_t L
		    );

/** 
 * @brief Get the size of a list.
 * @note Complexity: O( 1 )
 * @pre L must be a valid gdsl_list_t
 * @param L The list to get the size from
 * @return the number of elements of the list L (noted |L|).
 */
extern ulong
gdsl_list_get_size (const gdsl_list_t L
		    );

/** 
 * @brief Check if a list is empty.
 * @note Complexity: O( 1 )
 * @pre L must be a valid gdsl_list_t
 * @param L The list to check
 * @return TRUE if the list L is empty.
 * @return FALSE if the list L is not empty.
 */
extern bool
gdsl_list_is_empty (const gdsl_list_t L
		    );

/**
 * @brief Get the head of a list.
 * @note Complexity: O( 1 )
 * @pre L must be a valid gdsl_list_t
 * @param L The list to get the head from
 * @return the element at L's head position if L is not empty. The returned 
 * element is not removed from L.
 * @return NULL if the list L is empty.
 * @see gdsl_list_get_tail()
 */
extern gdsl_element_t
gdsl_list_get_head (const gdsl_list_t L
		    );

/** 
 * @brief Get the tail of a list.
 * @note Complexity: O( 1 )
 * @pre L must be a valid gdsl_list_t
 * @param L The list to get the tail from
 * @return the element at L's tail position if L is not empty. The returned 
 * element is not removed from L.
 * @return NULL if L is empty.
 * @see gdsl_list_get_head()
 */
extern gdsl_element_t
gdsl_list_get_tail (const gdsl_list_t L
		    );

/******************************************************************************/
/* Modification functions of doubly-linked lists                              */
/******************************************************************************/

/** 
 * @brief Set the name of a list.
 *
 * Changes the previous name of the list L to a copy of NEW_NAME.
 *
 * @note Complexity: O( 1 )
 * @pre L must be a valid gdsl_list_t
 * @param L The list to change the name
 * @param NEW_NAME The new name of L
 * @return the modified list in case of success.
 * @return NULL in case of failure.
 * @see gdsl_list_get_name()
 */
extern gdsl_list_t
gdsl_list_set_name (gdsl_list_t L,
		    const char* NEW_NAME
		    );

/**
 * @brief Insert an element at the head of a list.
 *
 * Allocate a new element E by calling L's ALLOC_F function on VALUE. ALLOC_F
 * is the function pointer passed to gdsl_list_alloc(). The new element E is
 * then inserted at the header position of the list L.
 *
 * @note Complexity: O( 1 )
 * @pre L must be a valid gdsl_list_t
 * @param L The list to insert into
 * @param VALUE The value used to make the new element to insert into L
 * @return the inserted element E in case of success.
 * @return NULL in case of failure.
 * @see gdsl_list_insert_tail()
 * @see gdsl_list_remove_head()
 * @see gdsl_list_remove_tail()
 * @see gdsl_list_remove()
 */
extern gdsl_element_t
gdsl_list_insert_head (gdsl_list_t L,
		       void* VALUE
		       );

/** 
 * @brief Insert an element at the tail of a list.
 *
 * Allocate a new element E by calling L's ALLOC_F function on VALUE. ALLOC_F
 * is the function pointer passed to gdsl_list_alloc(). The new element E is
 * then inserted at the footer position of the list L.
 *
 * @note Complexity: O( 1 )
 * @pre L must be a valid gdsl_list_t
 * @param L The list to insert into
 * @param VALUE The value used to make the new element to insert into L
 * @return the inserted element E in case of success.
 * @return NULL in case of failure.
 * @see gdsl_list_insert_head()
 * @see gdsl_list_remove_head()
 * @see gdsl_list_remove_tail()
 * @see gdsl_list_remove()
 */
extern gdsl_element_t
gdsl_list_insert_tail (gdsl_list_t L,
		       void* VALUE
		       );

/**
 * @brief Remove the head of a list.
 *
 * Remove the element at the head of the list L.
 *
 * @note Complexity: O( 1 )
 * @pre L must be a valid gdsl_list_t
 * @param L The list to remove the head from
 * @return the removed element in case of success.
 * @return NULL in case of L is empty.
 * @see gdsl_list_insert_head()
 * @see gdsl_list_insert_tail()
 * @see gdsl_list_remove_tail()
 * @see gdsl_list_remove()
 */
extern gdsl_element_t
gdsl_list_remove_head (gdsl_list_t L
		       );

/**
 * @brief Remove the tail of a list.
 *
 * Remove the element at the tail of the list L.
 *
 * @note Complexity: O( 1 )
 * @pre L must be a valid gdsl_list_t
 * @param L The list to remove the tail from
 * @return the removed element in case of success.
 * @return NULL in case of L is empty.
 * @see gdsl_list_insert_head()
 * @see gdsl_list_insert_tail()
 * @see gdsl_list_remove_head()
 * @see gdsl_list_remove()
 */
extern gdsl_element_t
gdsl_list_remove_tail (gdsl_list_t L
		       );

/**
 * @brief Remove a particular element from a list.
 *
 * Search into the list L for the first element E equal to VALUE by using 
 * COMP_F. If E is found, it is removed from L and then returned.
 *
 * @note Complexity: O( |L| / 2 )
 * @pre L must be a valid gdsl_list_t & COMP_F != NULL
 * @param L The list to remove the element from
 * @param COMP_F The comparison function used to find the element to remove
 * @param VALUE The value used to compare the element to remove with
 * @return the founded element E if it was found.
 * @return NULL in case the searched element E was not found.
 * @see gdsl_list_insert_head()
 * @see gdsl_list_insert_tail()
 * @see gdsl_list_remove_head()
 * @see gdsl_list_remove_tail()
 */
extern gdsl_element_t
gdsl_list_remove (gdsl_list_t L,
		  gdsl_compare_func_t COMP_F,
		  const void* VALUE
		  );

/** 
 * @brief Delete the head of a list.
 *
 * Remove the header element from the list L and deallocates it using the 
 * FREE_F function passed to gdsl_list_alloc().
 *
 * @note Complexity: O( 1 )
 * @pre L must be a valid gdsl_list_t
 * @param L The list to destroy the head from
 * @return the modified list L in case of success.
 * @return NULL if L is empty.
 * @see gdsl_list_alloc()
 * @see gdsl_list_destroy_tail()
 * @see gdsl_list_destroy()
 */
extern gdsl_list_t
gdsl_list_delete_head (gdsl_list_t L
		       );

/** 
 * @brief Delete the tail of a list.
 *
 * Remove the footer element from the list L and deallocates it using the 
 * FREE_F function passed to gdsl_list_alloc().
 *
 * @note Complexity: O( 1 )
 * @pre L must be a valid gdsl_list_t
 * @param L The list to destroy the tail from
 * @return the modified list L in case of success.
 * @return NULL if L is empty.
 * @see gdsl_list_alloc()
 * @see gdsl_list_destroy_head()
 * @see gdsl_list_destroy()
 */
extern gdsl_list_t
gdsl_list_delete_tail (gdsl_list_t L
		       );

/**
 * @brief Delete a particular element from a list.
 *
 * Search into the list L for the first element E equal to VALUE by using 
 * COMP_F. If E is found, it is removed from L and deallocated using the 
 * FREE_F function passed to gdsl_list_alloc().
 *
 * @note Complexity: O( |L| / 2 )
 * @pre L must be a valid gdsl_list_t & COMP_F != NULL
 * @param L The list to destroy the element from
 * @param COMP_F The comparison function used to find the element to destroy
 * @param VALUE The value used to compare the element to destroy with
 * @return the modified list L if the element is found.
 * @return NULL if the element to destroy is not found.
 * @see gdsl_list_alloc()
 * @see gdsl_list_destroy_head()
 * @see gdsl_list_destroy_tail()
 */
extern gdsl_list_t
gdsl_list_delete (gdsl_list_t L,
		  gdsl_compare_func_t COMP_F,
		  const void* VALUE
		  );

/******************************************************************************/
/* Search functions of doubly-linked lists                                    */
/******************************************************************************/

/**
 * @brief Search for a particular element into a list.
 *
 * Search the first element E equal to VALUE in the list L, by using COMP_F to
 * compare all L's element with.
 *
 * @note Complexity: O( |L| / 2 )
 * @pre L must be a valid gdsl_list_t & COMP_F != NULL
 * @param L The list to search the element in
 * @param COMP_F The comparison function used to compare L's element with VALUE
 * @param VALUE The value to compare L's elemenst with
 * @return the first founded element E in case of success.
 * @return NULL in case the searched element E was not found.
 * @see gdsl_list_search_by_position()
 * @see gdsl_list_search_max()
 * @see gdsl_list_search_min()
 */ 
extern gdsl_element_t
gdsl_list_search (const gdsl_list_t L,
		  gdsl_compare_func_t COMP_F,
		  const void* VALUE
		  );

/**
 * @brief Search for an element by its position in a list.
 * @note Complexity: O( |L| / 2 )
 * @pre L must be a valid gdsl_list_t & POS > 0 & POS <= |L|
 * @param L The list to search the element in
 * @param POS The position where is the element to search
 * @return the element at the POS-th position in the list L.
 * @return NULL if POS > |L| or POS <= 0.
 * @see gdsl_list_search()
 * @see gdsl_list_search_max()
 * @see gdsl_list_search_min()
 */
extern gdsl_element_t
gdsl_list_search_by_position (const gdsl_list_t L,
			      ulong POS
			      );

/**
 * @brief Search for the greatest element of a list.
 *
 * Search the greatest element of the list L, by using COMP_F to compare L's
 * elements with.
 *
 * @note Complexity: O( |L| )
 * @pre L must be a valid gdsl_list_t & COMP_F != NULL
 * @param L The list to search the element in
 * @param COMP_F The comparison function to use to compare L's element with
 * @return the highest element of L, by using COMP_F function.
 * @return NULL if L is empty.
 * @see gdsl_list_search()
 * @see gdsl_list_search_by_position()
 * @see gdsl_list_search_min()
 */
extern gdsl_element_t
gdsl_list_search_max (const gdsl_list_t L,
		      gdsl_compare_func_t COMP_F
		      );

/**
 * @brief Search for the lowest element of a list.
 *
 * Search the lowest element of the list L, by using COMP_F to compare L's
 * elements with.
 *
 * @note Complexity: O( |L| )
 * @pre L must be a valid gdsl_list_t & COMP_F != NULL
 * @param L The list to search the element in
 * @param COMP_F The comparison function to use to compare L's element with
 * @return the lowest element of L, by using COMP_F function.
 * @return NULL if L is empty.
 * @see gdsl_list_search()
 * @see gdsl_list_search_by_position()
 * @see gdsl_list_search_max()
 */
extern gdsl_element_t
gdsl_list_search_min (const gdsl_list_t L,
		      gdsl_compare_func_t COMP_F
		      );

/******************************************************************************/
/* Sort functions of doubly-linked lists                                      */
/******************************************************************************/

/**
 * @brief Sort a list.
 *
 * Sort the list L using COMP_F to order L's elements. 
 *
 * @note Complexity: O( |L| * log( |L| ) )
 * @pre L must be a valid gdsl_list_t & COMP_F != NULL 
 *      & L must not contains elements that are equals
 * @param L The list to sort
 * @param COMP_F The comparison function used to order L's elements
 * @return the sorted list L.
 */
extern gdsl_list_t
gdsl_list_sort (gdsl_list_t L,
		gdsl_compare_func_t COMP_F
		);

/******************************************************************************/
/* Parse functions of doubly-linked lists                                     */
/******************************************************************************/

/**
 * @brief Parse a list from head to tail.
 *
 * Parse all elements of the list L from head to tail. The MAP_F function is
 * called on each L's element with USER_DATA argument. If MAP_F returns 
 * GDSL_MAP_STOP, then gdsl_list_map_forward() stops and returns its last 
 * examinated element.
 *
 * @note Complexity: O( |L| )
 * @pre L must be a valid gdsl_list_t & MAP_F != NULL
 * @param L The list to parse
 * @param MAP_F The map function to apply on each L's element
 * @param USER_DATA User's datas passed to MAP_F
 * @return the first element for which MAP_F returns GDSL_MAP_STOP.
 * @return NULL when the parsing is done.
 * @see gdsl_list_map_backward()
 */
extern gdsl_element_t
gdsl_list_map_forward (const gdsl_list_t L,
		       gdsl_map_func_t MAP_F,
		       void* USER_DATA
		       );

/**
 * @brief Parse a list from tail to head.
 *
 * Parse all elements of the list L from tail to head. The MAP_F function is
 * called on each L's element with USER_DATA argument. If MAP_F returns 
 * GDSL_MAP_STOP then gdsl_list_map_backward() stops and returns its last
 * examinated element.
 *
 * @note Complexity: O( |L| )
 * @pre L must be a valid gdsl_list_t & MAP_F != NULL
 * @param L The list to parse
 * @param MAP_F The map function to apply on each L's element
 * @param USER_DATA User's datas passed to MAP_F
 * @return the first element for which MAP_F returns GDSL_MAP_STOP.
 * @return NULL when the parsing is done.
 * @see gdsl_list_map_forward()
 */
extern gdsl_element_t
gdsl_list_map_backward (const gdsl_list_t L,
			gdsl_map_func_t MAP_F,
			void* USER_DATA
			);

/******************************************************************************/
/* Input/output functions of doubly-linked lists                              */
/******************************************************************************/

/**
 * @brief Write all the elements of a list to a file.
 *
 * Write the elements of the list L to OUTPUT_FILE, using WRITE_F function.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |L| )
 * @pre L must be a valid gdsl_list_t & OUTPUT_FILE != NULL & WRITE_F != NULL
 * @param L The list to write.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write L's elements.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see gdsl_list_write_xml()
 * @see gdsl_list_dump()
 */
extern void
gdsl_list_write (const gdsl_list_t L,
		 gdsl_write_func_t WRITE_F,
		 FILE* OUTPUT_FILE,
		 void* USER_DATA
		 );

/**
 * @brief Write the content of a list to a file into XML.
 *
 * Write the elements of the list L to OUTPUT_FILE, into XML language. 
 * If WRITE_F != NULL, then uses WRITE_F to write L's elements to OUTPUT_FILE.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |L| )
 * @pre L must be a valid gdsl_list_t & OUTPUT_FILE != NULL
 * @param L The list to write.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write L's elements.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see gdsl_list_write()
 * @see gdsl_list_dump()
 */
extern void
gdsl_list_write_xml (const gdsl_list_t L,
		     gdsl_write_func_t WRITE_F,
		     FILE* OUTPUT_FILE,
		     void* USER_DATA
		     );

/**
 * @brief Dump the internal structure of a list to a file.
 *
 * Dump the structure of the list L to OUTPUT_FILE. If WRITE_F != NULL, then 
 * uses WRITE_F to write L's elements to OUTPUT_FILE.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |L| )
 * @pre L must be a valid gdsl_list_t & OUTPUT_FILE != NULL
 * @param L The list to write.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write L's elements.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see gdsl_list_write()
 * @see gdsl_list_write_xml()
 */
extern void
gdsl_list_dump (const gdsl_list_t L,
		gdsl_write_func_t WRITE_F,
		FILE* OUTPUT_FILE,
		void* USER_DATA
		);

/******************************************************************************/
/* Cursor specific functions of doubly-linked lists                           */
/******************************************************************************/

/**
 * @brief Create a new list cursor.
 * @note Complexity: O( 1 )
 * @pre L must be a valid gdsl_list_t
 * @param L The list on wich the cursor is positionned.
 * @return the newly allocated list cursor in case of success.
 * @return NULL in case of insufficient memory.
 * @see gdsl_list_cursor_free()
 */
gdsl_list_cursor_t
gdsl_list_cursor_alloc (const gdsl_list_t L
			);
/**
 * @brief Destroy a list cursor.
 * @note Complexity: O( 1 )
 * @pre C must be a valid gdsl_list_cursor_t.
 * @param C The list cursor to destroy.
 * @see gdsl_list_cursor_alloc()
 */
void
gdsl_list_cursor_free (gdsl_list_cursor_t C
		       );

/**
 * @brief Put a cursor on the head of its list.
 *
 * Put the cursor C on the head of C's list. Does nothing if C's list is empty.
 *
 * @note Complexity: O( 1 )
 * @pre C must be a valid gdsl_list_cursor_t
 * @param C The cursor to use
 * @see gdsl_list_cursor_move_to_tail()
 */
extern void
gdsl_list_cursor_move_to_head (gdsl_list_cursor_t C
			       );

/**
 * @brief Put a cursor on the tail of its list.
 *
 * Put the cursor C on the tail of C's list. Does nothing if C's list is empty.
 *
 * @note Complexity: O( 1 )
 * @pre C must be a valid gdsl_list_cursor_t
 * @param C The cursor to use
 * @see gdsl_list_cursor_move_to_head()
 */
extern void
gdsl_list_cursor_move_to_tail (gdsl_list_cursor_t C
			       );

/**
 * @brief Place a cursor on a particular element.
 *
 * Search a particular element E in the cursor's list L by comparing all list's 
 * elements to VALUE, by using COMP_F. If E is found, C is positionned on it.
 *
 * @note Complexity: O( |L| / 2 )
 * @pre C must be a valid gdsl_list_cursor_t & COMP_F != NULL
 * @param C The cursor to put on the element E
 * @param COMP_F The comparison function to search for E
 * @param VALUE The value used to compare list's elements with
 * @return the first founded element E in case it exists.
 * @return NULL in case of element E is not found.
 * @see gdsl_list_cursor_move_to_position()
 */ 
extern gdsl_element_t
gdsl_list_cursor_move_to_value (gdsl_list_cursor_t C,
				gdsl_compare_func_t COMP_F,
				void* VALUE
				);

/**
 * @brief Place a cursor on a element given by its position.
 *
 * Search for the POS-th element in the cursor's list L. In case this element
 * exists, the cursor C is positionned on it.
 *
 * @note Complexity: O( |L| / 2 )
 * @pre C must be a valid gdsl_list_cursor_t & POS > 0 & POS <= |L|
 * @param C The cursor to put on the POS-th element
 * @param POS The position of the element to move on
 * @return the element at the POS-th position
 * @return NULL if POS <= 0 or POS > |L|
 * @see gdsl_list_cursor_move_to_value()
 */
extern gdsl_element_t
gdsl_list_cursor_move_to_position (gdsl_list_cursor_t C,
				   ulong POS
				   );

/**
 * @brief Move a cursor one step forward of its list.
 *
 * Move the cursor C one node forward (from head to tail). Does nothing if C is 
 * already on its list's tail.
 *
 * @note Complexity: O( 1 )
 * @pre C must be a valid gdsl_list_cursor_t
 * @param C The cursor to use
 * @see gdsl_list_cursor_step_backward()
 */
extern void
gdsl_list_cursor_step_forward (gdsl_list_cursor_t C
			       );

/**
 * @brief Move a cursor one step backward of its list.
 *
 * Move the cursor C one node backward (from tail to head.) Does nothing if C is
 * already on its list's head.
 *
 * @note Complexity: O( 1 )
 * @pre C must be a valid gdsl_list_cursor_t
 * @param C The cursor to use
 * @see gdsl_list_cursor_step_forward()
 */
extern void
gdsl_list_cursor_step_backward (gdsl_list_cursor_t C
				);

/**
 * @brief Check if a cursor is on the head of its list.
 * @note Complexity: O( 1 )
 * @pre C must be a valid gdsl_list_cursor_t
 * @param C The cursor to check
 * @return TRUE if C is on its list's head.
 * @return FALSE if C is not on its lits's head.
 * @see gdsl_list_cursor_is_on_tail()
 */
extern bool
gdsl_list_cursor_is_on_head (const gdsl_list_cursor_t C
			     );

/**
 * @brief Check if a cursor is on the tail of its list.
 * @note Complexity: O( 1 )
 * @pre C must be a valid gdsl_list_cursor_t
 * @param C The cursor to check
 * @return TRUE if C is on its lists's tail.
 * @return FALSE if C is not on its list's tail.
 * @see gdsl_list_cursor_is_on_head()
 */
extern bool
gdsl_list_cursor_is_on_tail (const gdsl_list_cursor_t C
			     );

/** 
 * @brief Check if a cursor has a successor.
 * @note Complexity: O( 1 )
 * @pre C must be a valid gdsl_list_cursor_t
 * @param C The cursor to check
 * @return TRUE if there exists an element after the cursor C.
 * @return FALSE if there is no element after the cursor C.
 * @see gdsl_list_cursor_has_pred()
 */
extern bool 
gdsl_list_cursor_has_succ (const gdsl_list_cursor_t C
			   );

/**
 * @brief Check if a cursor has a predecessor.
 * @note Complexity: O( 1 )
 * @pre C must be a valid gdsl_list_cursor_t
 * @param C The cursor to check
 * @return TRUE if there exists an element before the cursor C.
 * @return FALSE if there is no element before the cursor C.
 * @see gdsl_list_cursor_has_succ()
 */
extern bool 
gdsl_list_cursor_has_pred (const gdsl_list_cursor_t C
			   );

/**
 * @brief Set the content of the cursor.
 *
 * Set C's element to E. The previous element is *NOT* deallocated. If it must 
 * be deallocated, gdsl_list_cursor_get_content() could be used to get it in 
 * order to free it before.
 *
 * @note Complexity: O( 1 )
 * @pre C must be a valid gdsl_list_cursor_t
 * @param C The cursor in which the content must be modified.
 * @param E The value used to modify C's content.
 * @see gdsl_list_cursor_get_content()
 */
extern void
 gdsl_list_cursor_set_content (gdsl_list_cursor_t C,
			       gdsl_element_t E
			       );
/**
 * @brief Get the content of a cursor.
 * @note Complexity: O( 1 )
 * @pre C must be a valid gdsl_list_cursor_t
 * @param C The cursor to get the content from.
 * @return the element contained in the cursor C.
 * @see gdsl_list_cursor_set_content()
 */
extern gdsl_element_t
gdsl_list_cursor_get_content (const gdsl_list_cursor_t C
			      );

/** 
 * @brief Insert a new element after a cursor.
 *
 * A new element is created using ALLOC_F called on VALUE. ALLOC_F is the
 * pointer passed to gdsl_list_alloc(). If the returned value is not NULL, then
 * the new element is placed after the cursor C. If C's list is empty, the 
 * element is inserted at the head position of C's list.
 *
 * @note Complexity: O( 1 )
 * @pre C must be a valid gdsl_list_cursor_t
 * @param C The cursor after which the new element must be inserted
 * @param VALUE The value used to allocate the new element to insert
 * @return the newly inserted element in case of success.
 * @return NULL in case of failure.
 * @see gdsl_list_cursor_insert_before()
 * @see gdsl_list_cursor_remove_after()
 * @see gdsl_list_cursor_remove_before()
 */
extern gdsl_element_t
gdsl_list_cursor_insert_after (gdsl_list_cursor_t C,
			       void* VALUE
			       );
/** 
 * @brief Insert a new element before a cursor.
 *
 * A new element is created using ALLOC_F called on VALUE. ALLOC_F is the 
 * pointer passed to gdsl_list_alloc(). If the returned value is not NULL, then
 * the new element is placed before the cursor C. If C's list is empty, the
 * element is inserted at the head position of C's list.
 *
 * @note Complexity: O( 1 )
 * @pre C must be a valid gdsl_list_cursor_t
 * @param C The cursor before which the new element must be inserted
 * @param VALUE The value used to allocate the new element to insert
 * @return the newly inserted element in case of success.
 * @return NULL in case of failure.
 * @see gdsl_list_cursor_insert_after()
 * @see gdsl_list_cursor_remove_after()
 * @see gdsl_list_cursor_remove_before()
 */
extern gdsl_element_t
gdsl_list_cursor_insert_before (gdsl_list_cursor_t C,
				void* VALUE
				);

/**
 * @brief Removec the element under a cursor.
 * @note Complexity: O( 1 )
 * @pre C must be a valid gdsl_list_cursor_t
 * @post After this operation, the cursor is positionned on to its successor.
 * @param C The cursor to remove the content from.
 * @return the removed element if it exists.
 * @return NULL if there is not element to remove.
 * @see gdsl_list_cursor_insert_after()
 * @see gdsl_list_cursor_insert_before()
 * @see gdsl_list_cursor_remove()
 * @see gdsl_list_cursor_remove_before()
 */
extern gdsl_element_t
gdsl_list_cursor_remove (gdsl_list_cursor_t C
			 );

/**
 * @brief Removec the element after a cursor.
 * @note Complexity: O( 1 )
 * @pre C must be a valid gdsl_list_cursor_t
 * @param C The cursor to remove the successor from.
 * @return the removed element if it exists.
 * @return NULL if there is not element to remove.
 * @see gdsl_list_cursor_insert_after()
 * @see gdsl_list_cursor_insert_before()
 * @see gdsl_list_cursor_remove()
 * @see gdsl_list_cursor_remove_before()
 */
extern gdsl_element_t
gdsl_list_cursor_remove_after (gdsl_list_cursor_t C
			       );

/**
 * @brief Remove the element before a cursor.
 * @note Complexity: O( 1 )
 * @pre C must be a valid gdsl_list_cursor_t
 * @param C The cursor to remove the predecessor from.
 * @return the removed element if it exists.
 * @return NULL if there is not element to remove.
 * @see gdsl_list_cursor_insert_after()
 * @see gdsl_list_cursor_insert_before()
 * @see gdsl_list_cursor_remove()
 * @see gdsl_list_cursor_remove_after()
 */
extern gdsl_element_t
gdsl_list_cursor_remove_before (gdsl_list_cursor_t C
				);

/**
 * @brief Delete the element under a cursor.
 *
 * Remove the element under the cursor C. The removed element is also 
 * deallocated using FREE_F passed to gdsl_list_alloc().
 *
 * Complexity: O( 1 )
 *
 * @pre C must be a valid gdsl_list_cursor_t
 * @param C The cursor to delete the content.
 * @returns the cursor C if the element was removed.
 * @returns NULL if there is not element to remove.
 * @see gdsl_list_cursor_delete_before()
 * @see gdsl_list_cursor_delete_after()
 */
extern gdsl_list_cursor_t
gdsl_list_cursor_delete (gdsl_list_cursor_t C
			 );

/**
 * @brief Delete the element after a cursor.
 *
 * Remove the element after the cursor C. The removed element is also 
 * deallocated using FREE_F passed to gdsl_list_alloc().
 *
 * Complexity: O( 1 )
 *
 * @pre C must be a valid gdsl_list_cursor_t
 * @param C The cursor to delete the successor from.
 * @returns the cursor C if the element was removed.
 * @returns NULL if there is not element to remove.
 * @see gdsl_list_cursor_delete()
 * @see gdsl_list_cursor_delete_before()
 */
extern gdsl_list_cursor_t
gdsl_list_cursor_delete_after (gdsl_list_cursor_t C
			       );

/**
 * @brief Delete the element before the cursor of a list.
 *
 * Remove the element before the cursor C. The removed element is also
 * deallocated using FREE_F passed to gdsl_list_alloc().
 *
 * @note Complexity: O( 1 )
 * @pre C must be a valid gdsl_list_cursor_t
 * @param C The cursor to delete the predecessor from.
 * @return the cursor C if the element was removed.
 * @return NULL if there is not element to remove.
 * @see gdsl_list_cursor_delete()
 * @see gdsl_list_cursor_delete_after()
 */
extern gdsl_list_cursor_t
gdsl_list_cursor_delete_before (gdsl_list_cursor_t C
				);


/*
 * @}
 */


#ifdef __cplusplus
}
#endif /* __cplusplus */


#endif /* GDSL_LIST_H_ */


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
