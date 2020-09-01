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
 * $RCSfile: gdsl_rbtree.h,v $
 * $Revision: 1.20 $
 * $Date: 2006/03/04 16:32:05 $
 */


#ifndef _GDSL_RBTREE_H_
#define _GDSL_RBTREE_H_


#include "gdsl_types.h"
#include "_gdsl_bintree.h"
#include "gdsl_macros.h"


#ifdef __cplusplus
extern "C" 
{
#endif /* __cplusplus */


/**
 * @defgroup gdsl_rbtree Red-black tree manipulation module
 * @{
 */

/**
 * GDSL red-black tree type.
 *
 * This type is voluntary opaque. Variables of this kind could'nt be directly
 * used, but by the functions of this module.
 */
typedef struct gdsl_rbtree* gdsl_rbtree_t;

/******************************************************************************/
/* Management functions of red-black trees                                    */
/******************************************************************************/

/**
 * @brief Create a new red-black tree.
 *
 * Allocate a new red-black tree data structure which name is set to a copy of
 * NAME.
 * The function pointers ALLOC_F, FREE_F and COMP_F could be used to
 * respectively, alloc, free and compares elements in the tree. These pointers
 * could be set to NULL to use the default ones:
 * - the default ALLOC_F simply returns its argument
 * - the default FREE_F does nothing
 * - the default COMP_F always returns 0
 *
 * @note Complexity: O( 1 )
 * @pre nothing
 * @param NAME The name of the new red-black tree to create
 * @param ALLOC_F Function to alloc element when inserting it in a r-b tree
 * @param FREE_F Function to free element when removing it from a r-b tree
 * @param COMP_F Function to compare elements into the r-b tree
 * @return the newly allocated red-black tree in case of success.
 * @return NULL in case of failure.
 * @see gdsl_rbtree_free()
 * @see gdsl_rbtree_flush()
 */
extern gdsl_rbtree_t
gdsl_rbtree_alloc (const char* NAME,
		   gdsl_alloc_func_t ALLOC_F,
		   gdsl_free_func_t FREE_F,
		   gdsl_compare_func_t COMP_F
		   );
  
/**
 * @brief Destroy a red-black tree.
 *
 * Deallocate all the elements of the red-black tree T by calling T's FREE_F
 * function passed to gdsl_rbtree_alloc(). The name of T is deallocated and T is
 * deallocated itself too.
 *
 * @note Complexity: O( |T| )
 * @pre T must be a valid gdsl_rbtree_t
 * @param T The red-black tree to deallocate
 * @see gdsl_rbtree_alloc()
 * @see gdsl_rbtree_flush()
 */
extern void 
gdsl_rbtree_free (gdsl_rbtree_t T
		  );

/**
 * @brief Flush a red-black tree.
 *
 * Deallocate all the elements of the red-black tree T by calling T's FREE_F 
 * function passed to gdsl_rbtree_alloc(). The red-black tree T is not 
 * deallocated itself and its name is not modified.
 *
 * @note Complexity: O( |T| )
 * @pre T must be a valid gdsl_rbtree_t
 * @see gdsl_rbtree_alloc()
 * @see gdsl_rbtree_free()
 */
extern void 
gdsl_rbtree_flush (gdsl_rbtree_t T
		   );

/******************************************************************************/
/* Consultation functions of red-black trees                                  */
/******************************************************************************/

/**
 * @brief Get the name of a red-black tree.
 * @note Complexity: O( 1 )
 * @pre T must be a valid gdsl_rbtree_t
 * @post The returned string MUST NOT be freed.
 * @param T The red-black tree to get the name from
 * @return the name of the red-black tree T.
 * @see gdsl_rbtree_set_name()
 */
extern char*
gdsl_rbtree_get_name (const gdsl_rbtree_t T
		      );

/**
 * @brief Check if a red-black tree is empty.
 * @note Complexity: O( 1 )
 * @pre T must be a valid gdsl_rbtree_t
 * @param T The red-black tree to check
 * @return TRUE if the red-black tree T is empty.
 * @return FALSE if the red-black tree T is not empty.
 */
extern bool
gdsl_rbtree_is_empty (const gdsl_rbtree_t T
		      );

/**
 * @brief Get the root of a red-black tree.
 * @note Complexity: O( 1 )
 * @pre T must be a valid gdsl_rbtree_t
 * @param T The red-black tree to get the root element from
 * @return the element at the root of the red-black tree T.
 */
extern gdsl_element_t
gdsl_rbtree_get_root (const gdsl_rbtree_t T
		      );

/**
 * @brief Get the size of a red-black tree.
 * @note Complexity: O( 1 )
 * @pre T must be a valid gdsl_rbtree_t
 * @param T The red-black tree to get the size from
 * @return the size of the red-black tree T (noted |T|).
 * @see gdsl_rbtree_get_height()
 */
extern ulong
gdsl_rbtree_get_size (const gdsl_rbtree_t T
		      );

/**
 * @brief Get the height of a red-black tree.
 * @note Complexity: O( |T| )
 * @pre T must be a valid gdsl_rbtree_t
 * @param T The red-black tree to compute the height from
 * @return the height of the red-black tree T (noted h(T)).
 * @see gdsl_rbtree_get_size()
 */
extern ulong
gdsl_rbtree_height (const gdsl_rbtree_t T
		    );

/******************************************************************************/
/* Modification functions of red-black trees                                  */
/******************************************************************************/

/**
 * @brief Set the name of a red-black tree.
 *
 * Change the previous name of the red-black tree T to a copy of NEW_NAME.
 *
 * @note Complexity: O( 1 )
 * @pre T must be a valid gdsl_rbtree_t
 * @param T The red-black tree to change the name
 * @param NEW_NAME The new name of T
 * @return the modified red-black tree in case of success.
 * @return NULL in case of insufficient memory.
 * @see gdsl_rbtree_get_name()
 */
extern gdsl_rbtree_t
gdsl_rbtree_set_name (gdsl_rbtree_t T,
		      const char* NEW_NAME
		      );

/**
 * @brief Insert an element into a red-black tree if it's not found or
 * return it.
 * 
 * Search for the first element E equal to VALUE into the red-black tree T, 
 * by using T's COMP_F function passed to gdsl_rbtree_alloc to find it. If E is
 * found, then it's returned. If E isn't found, then a new element E is 
 * allocated using T's ALLOC_F function passed to gdsl_rbtree_alloc and is 
 * inserted and then returned.
 *
 * @note Complexity: O( log( |T| ) )
 * @pre T must be a valid gdsl_rbtree_t & RESULT != NULL
 * @param T The red-black tree to modify
 * @param VALUE The value used to make the new element to insert into T
 * @param RESULT The address where the result code will be stored. 
 * @return the element E and RESULT = GDSL_OK if E is inserted into T.
 * @return the element E and RESULT = GDSL_ERR_DUPLICATE_ENTRY if E is already 
 * present in T.
 * @return NULL and RESULT = GDSL_ERR_MEM_ALLOC in case of insufficient memory.
 * @see gdsl_rbtree_remove()
 * @see gdsl_rbtree_delete()
 */
extern gdsl_element_t
gdsl_rbtree_insert (gdsl_rbtree_t T,
		    void* VALUE,
		    int* RESULT
		    );

/**
 * @brief Remove an element from a red-black tree.
 *
 * Remove from the red-black tree T the first founded element E equal to 
 * VALUE, by using T's COMP_F function passed to gdsl_rbtree_alloc(). If E is
 * found, it is removed from T and then returned.
 *
 * @note Complexity: O( log ( |T| ) )
 * @pre T must be a valid gdsl_rbtree_t
 * @param T The red-black tree to modify
 * @param VALUE The value used to find the element to remove
 * @return the first founded element equal to VALUE in T in case is found.
 * @return NULL in case no element equal to VALUE is found in T.
 * @see gdsl_rbtree_insert()
 * @see gdsl_rbtree_delete()
 */
extern gdsl_element_t
gdsl_rbtree_remove (gdsl_rbtree_t T,
		    void* VALUE
		    );

/**
 * @brief Delete an element from a red-black tree.
 *
 * Remove from the red-black tree the first founded element E equal to 
 * VALUE, by using T's COMP_F function passed to gdsl_rbtree_alloc(). If E is 
 * found, it is removed from T and E is deallocated using T's FREE_F function 
 * passed to gdsl_rbtree_alloc(), then T is returned.
 *
 * @note Complexity: O( log( |T| ) )
 * @pre T must be a valid gdsl_rbtree_t
 * @param T The red-black tree to remove an element from
 * @param VALUE The value used to find the element to remove
 * @return the modified red-black tree after removal of E if E was found.
 * @return NULL if no element equal to VALUE was found.
 * @see gdsl_rbtree_insert()
 * @see gdsl_rbtree_remove()
 */
extern gdsl_rbtree_t
gdsl_rbtree_delete (gdsl_rbtree_t T,
		    void* VALUE
		    );

/******************************************************************************/
/* Search functions of red-black trees                                        */
/******************************************************************************/

/**
 * @brief Search for a particular element into a red-black tree.
 *
 * Search the first element E equal to VALUE in the red-black tree T, by 
 * using COMP_F function to find it. If COMP_F == NULL, then the COMP_F function
 * passed to gdsl_rbtree_alloc() is used.
 *
 * @note Complexity: O( log( |T| ) )
 * @pre T must be a valid gdsl_rbtree_t
 * @param T The red-black tree to use.
 * @param COMP_F The comparison function to use to compare T's element with
 * VALUE to find the element E (or NULL to use the default T's COMP_F)
 * @param VALUE The value that must be used by COMP_F to find the element E
 * @return the first founded element E equal to VALUE.
 * @return NULL if VALUE is not found in T.
 * @see gdsl_rbtree_insert()
 * @see gdsl_rbtree_remove()
 * @see gdsl_rbtree_delete()
 */
extern gdsl_element_t
gdsl_rbtree_search (const gdsl_rbtree_t T,
		    gdsl_compare_func_t COMP_F,
		    void* VALUE
		    );

/******************************************************************************/
/* Parse functions of red-black trees                                         */
/******************************************************************************/

/**
 * @brief Parse a red-black tree in prefixed order.
 *
 * Parse all nodes of the red-black tree T in prefixed order. The MAP_F 
 * function is called on the element contained in each node with the USER_DATA
 * argument. If MAP_F returns GDSL_MAP_STOP, then gdsl_rbtree_map_prefix() stops
 * and returns its last examinated element.
 *
 * @note Complexity: O( |T| )
 * @pre T must be a valid gdsl_rbtree_t & MAP_F != NULL
 * @param T The red-black tree to map.
 * @param MAP_F The map function.
 * @param USER_DATA User's datas passed to MAP_F
 * @return the first element for which MAP_F returns GDSL_MAP_STOP.
 * @return NULL when the parsing is done.
 * @see gdsl_rbtree_map_infix()
 * @see gdsl_rbtree_map_postfix()
 */
extern gdsl_element_t
gdsl_rbtree_map_prefix (const gdsl_rbtree_t T,
			gdsl_map_func_t MAP_F,
			void* USER_DATA
			);

/**
 * @brief Parse a red-black tree in infixed order.
 *
 * Parse all nodes of the red-black tree T in infixed order. The MAP_F 
 * function is called on the element contained in each node with the USER_DATA
 * argument. If MAP_F returns GDSL_MAP_STOP, then gdsl_rbtree_map_infix() stops
 * and returns its last examinated element.
 *
 * @note Complexity: O( |T| )
 * @pre T must be a valid gdsl_rbtree_t & MAP_F != NULL
 * @param T The red-black tree to map.
 * @param MAP_F The map function.
 * @param USER_DATA User's datas passed to MAP_F
 * @return the first element for which MAP_F returns GDSL_MAP_STOP.
 * @return NULL when the parsing is done.
 * @see gdsl_rbtree_map_prefix()
 * @see gdsl_rbtree_map_postfix()
 */
extern gdsl_element_t
gdsl_rbtree_map_infix (const gdsl_rbtree_t T,
		       gdsl_map_func_t MAP_F,
		       void* USER_DATA
		       );

/**
 * @brief Parse a red-black tree in postfixed order.
 *
 * Parse all nodes of the red-black tree T in postfixed order. The MAP_F 
 * function is called on the element contained in each node with the USER_DATA
 * argument. If MAP_F returns GDSL_MAP_STOP, then gdsl_rbtree_map_postfix() 
 * stops and returns its last examinated element.
 *
 * @note Complexity: O( |T| )
 * @pre T must be a valid gdsl_rbtree_t & MAP_F != NULL
 * @param T The red-black tree to map.
 * @param MAP_F The map function.
 * @param USER_DATA User's datas passed to MAP_F
 * @return the first element for which MAP_F returns GDSL_MAP_STOP.
 * @return NULL when the parsing is done.
 * @see gdsl_rbtree_map_prefix()
 * @see gdsl_rbtree_map_infix()
 */
extern gdsl_element_t
gdsl_rbtree_map_postfix (const gdsl_rbtree_t T,
			 gdsl_map_func_t MAP_F,
			 void* USER_DATA
			 );

/******************************************************************************/
/* Input/output functions of red-black trees                                  */
/******************************************************************************/

/**
 * @brief Write the element of each node of a red-black tree to a file.
 *
 * Write the nodes elements of the red-black tree T to OUTPUT_FILE, using
 * WRITE_F function.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |T| )
 * @pre T must be a valid gdsl_rbtree_t & WRITE_F != NULL & OUTPUT_FILE != NULL
 * @param T The red-black tree to write.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write T's elements.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see gdsl_rbtree_write_xml()
 * @see gdsl_rbtree_dump()
 */
extern void
gdsl_rbtree_write (const gdsl_rbtree_t T,
		   gdsl_write_func_t WRITE_F,
		   FILE* OUTPUT_FILE,
		   void* USER_DATA
		   );

/**
 * @brief Write the content of a red-black tree to a file into XML.
 *
 * Write the nodes elements of the red-black tree T to OUTPUT_FILE, into
 * XML language.
 * If WRITE_F != NULL, then use WRITE_F to write T's nodes elements to 
 * OUTPUT_FILE.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |T| )
 * @pre T must be a valid gdsl_rbtree_t & OUTPUT_FILE != NULL
 * @param T The red-black tree to write.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write T's elements.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see gdsl_rbtree_write()
 * @see gdsl_rbtree_dump()
 */
extern void
gdsl_rbtree_write_xml (const gdsl_rbtree_t T,
		       gdsl_write_func_t WRITE_F,
		       FILE* OUTPUT_FILE,
		       void* USER_DATA
		       );

/**
 * @brief Dump the internal structure of a red-black tree to a file.
 *
 * Dump the structure of the red-black tree T to OUTPUT_FILE. If 
 * WRITE_F != NULL, then use WRITE_F to write T's nodes elements to 
 * OUTPUT_FILE.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |T| )
 * @pre T must be a valid gdsl_rbtree_t & OUTPUT_FILE != NULL
 * @param T The red-black tree to write.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write T's elements.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see gdsl_rbtree_write()
 * @see gdsl_rbtree_write_xml()
 */
extern void
gdsl_rbtree_dump (const gdsl_rbtree_t T,
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


#endif /* _GDSL_RBTREE_H_ */


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
