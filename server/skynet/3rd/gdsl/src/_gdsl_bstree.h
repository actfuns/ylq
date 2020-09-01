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
 * $RCSfile: _gdsl_bstree.h,v $
 * $Revision: 1.29 $
 * $Date: 2006/03/04 16:32:05 $
 */


#ifndef __GDSL_BSTREE_H_
#define __GDSL_BSTREE_H_


#include "_gdsl_bintree.h"
#include "gdsl_macros.h"
#include "gdsl_types.h"


#ifdef __cplusplus
extern "C" 
{
#endif /* __cplusplus */


/**
 * @defgroup _gdsl_bstree Low-level binary search tree manipulation module
 * @{
 */

/**
 * @brief GDSL low-level binary search tree type.
 *
 * This type is voluntary opaque. Variables of this kind could'nt be directly
 * used, but by the functions of this module.
 */
typedef _gdsl_bintree_t _gdsl_bstree_t;

/**
 * @brief GDSL low-level binary search tree map function type.
 * @param TREE The low-level binary search tree to map.
 * @param USER_DATA The user datas to pass to this function.
 * @return GDSL_MAP_STOP if the mapping must be stopped.
 * @return GDSL_MAP_CONT if the mapping must be continued.
 */
typedef int (* _gdsl_bstree_map_func_t) (_gdsl_bstree_t TREE,
					 void* USER_DATA
					 );

/**
 * @brief GDSL low-level binary search tree write function type.
 * @param TREE The low-level binary search tree to write.
 * @param OUTPUT_FILE The file where to write TREE.
 * @param USER_DATA The user datas to pass to this function.
 */
typedef void (* _gdsl_bstree_write_func_t) (_gdsl_bstree_t TREE,
					    FILE* OUTPUT_FILE,
					    void* USER_DATA
					    );

/******************************************************************************/
/* Management functions of low-level binary search trees                      */
/******************************************************************************/

/**
 * @brief Create a new low-level binary search tree.
 *
 * Allocate a new low-level binary search tree data structure. Its root 
 * content is sets to E and its left and right sons are set to NULL.
 *
 * @note Complexity: O( 1 )
 * @pre nothing.
 * @param E The root content of the new low-level binary search tree to create.
 * @return the newly allocated low-level binary search tree in case of success.
 * @return NULL in case of insufficient memory.
 * @see _gdsl_bstree_free()
 */
extern _gdsl_bstree_t
_gdsl_bstree_alloc (const gdsl_element_t E
		    );

/**
 * @brief Destroy a low-level binary search tree.
 *
 * Flush and destroy the low-level binary search tree T. If FREE_F != NULL, 
 * FREE_F function is used to deallocate each T's element. Otherwise nothing is 
 * done with T's elements.
 *
 * @note Complexity: O( |T| )
 * @pre nothing.
 * @param T The low-level binary search tree to destroy.
 * @param FREE_F The function used to deallocate T's nodes contents.
 * @see _gdsl_bstree_alloc()
 */
extern void 
_gdsl_bstree_free (_gdsl_bstree_t T,
		   const gdsl_free_func_t FREE_F
		   );

/**
 * @brief Copy a low-level binary search tree.
 *
 * Create and return a copy of the low-level binary search tree T using COPY_F
 * on each T's element to copy them.
 *
 * @note Complexity: O( |T| )
 * @pre COPY_F != NULL.
 * @param T The low-level binary search tree to copy.
 * @param COPY_F The function used to copy T's nodes contents.
 * @return a copy of T in case of success.
 * @return NULL if _gdsl_bstree_is_empty (T) == TRUE or in case of insufficient
 * memory.
 * @see _gdsl_bstree_alloc()
 * @see _gdsl_bstree_free()
 * @see _gdsl_bstree_is_empty()
 */
extern _gdsl_bstree_t
_gdsl_bstree_copy (const _gdsl_bstree_t T,
		   const gdsl_copy_func_t COPY_F
		   );

/******************************************************************************/
/* Consultation functions of low-level binary search trees                    */
/******************************************************************************/

/** 
 * @brief Check if a low-level binary search tree is empty.
 * @note Complexity: O( 1 )
 * @pre nothing.
 * @param T The low-level binary search tree to check.
 * @return TRUE if the low-level binary search tree T is empty.
 * @return FALSE if the low-level binary search tree T is not empty.
 * @see _gdsl_bstree_is_leaf()
 * @see _gdsl_bstree_is_root()
 */
extern bool
_gdsl_bstree_is_empty (const _gdsl_bstree_t T
		       );

/**
 * @brief Check if a low-level binary search tree is reduced to a leaf.
 * @note Complexity: O( 1 )
 * @pre T must be a non-empty _gdsl_bstree_t.
 * @param T The low-level binary search tree to check.
 * @return TRUE if the low-level binary search tree T is a leaf.
 * @return FALSE if the low-level binary search tree T is not a leaf.
 * @see _gdsl_bstree_is_empty()
 * @see _gdsl_bstree_is_root()
 */
extern bool
_gdsl_bstree_is_leaf (const _gdsl_bstree_t T
		      );

/**
 * @brief Get the root content of a low-level binary search tree.
 * @note Complexity: O( 1 )
 * @pre T must be a non-empty _gdsl_bstree_t.
 * @param T The low-level binary search tree to use.
 * @return the root's content of the low-level binary search tree T.
 */
extern gdsl_element_t
_gdsl_bstree_get_content (const _gdsl_bstree_t T
			  );

/**
 * @brief Check if a low-level binary search tree is a root.
 * @note Complexity: O( 1 )
 * @pre T must be a non-empty _gdsl_bstree_t.
 * @param T The low-level binary search tree to check.
 * @return TRUE if the low-level binary search tree T is a root.
 * @return FALSE if the low-level binary search tree T is not a root.
 * @see _gdsl_bstree_is_empty()
 * @see _gdsl_bstree_is_leaf()
 */
extern bool
_gdsl_bstree_is_root (const _gdsl_bstree_t T
		      );

/**
 * @brief Get the parent tree of a low-level binary search tree.
 * @note Complexity: O( 1 )
 * @pre T must be a non-empty _gdsl_bstree_t.
 * @param T The low-level binary search tree to use.
 * @return the parent of the low-level binary search tree T if T isn't a root.
 * @return NULL if the low-level binary search tree T is a root (ie. T has no 
 * parent).
 * @see _gdsl_bstree_is_root()
 */
extern _gdsl_bstree_t
_gdsl_bstree_get_parent (const _gdsl_bstree_t T
			 );

/**
 * @brief Get the left sub-tree of a low-level binary search tree.
 * @note Complexity: O( 1 )
 * @pre T must be a non-empty _gdsl_bstree_t.
 * @param T The low-level binary search tree to use.
 * @return the left sub-tree of the low-level binary search tree T if T has a 
 * left sub-tree.
 * @return NULL if the low-level binary search tree T has no left sub-tree.
 * @see _gdsl_bstree_get_right()
 */
extern _gdsl_bstree_t
_gdsl_bstree_get_left (const _gdsl_bstree_t T
		       );

/**
 * @brief Get the right sub-tree of a low-level binary search tree.
 * @note Complexity: O( 1 )
 * @pre T must be a non-empty _gdsl_bstree_t.
 * @param T The low-level binary search tree to use.
 * @return the right sub-tree of the low-level binary search tree T if T has a 
 * right sub-tree.
 * @return NULL if the low-level binary search tree T has no right sub-tree.
 * @see _gdsl_bstree_get_left()
 */
extern _gdsl_bstree_t
_gdsl_bstree_get_right (const _gdsl_bstree_t T
			);

/**
 * @brief Get the size of a low-level binary search tree.
 * @note Complexity: O( |T| )
 * @pre nothing.
 * @param T The low-level binary search tree to compute the size from.
 * @return the number of elements of T (noted |T|).
 * @see _gdsl_bstree_get_height()
 */
extern ulong
_gdsl_bstree_get_size (const _gdsl_bstree_t T
		       );
  
/**
 * @brief Get the height of a low-level binary search tree.
 *
 * Compute the height of the low-level binary search tree T (noted h(T)).
 *
 * @note Complexity: O( |T| )
 * @pre nothing.
 * @param T The low-level binary search tree to compute the height from.
 * @return the height of T.
 * @see _gdsl_bstree_get_size()
 */
extern ulong
_gdsl_bstree_get_height (const _gdsl_bstree_t T
			 );

/******************************************************************************/
/* Modification functions of low-level binary search trees                    */
/******************************************************************************/

/**
 * @brief Insert an element into a low-level binary search tree if it's not 
 * found or return it.
 *
 * Search for the first element E equal to VALUE into the low-level binary 
 * search tree T, by using COMP_F function to find it. If an element E equal to
 * VALUE is found, then it's returned. If no element equal to VALUE is found, 
 * then E is inserted and its root returned.
 *
 * @note Complexity: O( h(T) ), where log2(|T|) <= h(T) <= |T|-1
 * @pre COMP_F != NULL & RESULT != NULL.
 * @param T The reference of the low-level binary search tree to use.
 * @param COMP_F The comparison function to use to compare T's elements with
 * VALUE to find E.
 * @param VALUE The value used to search for the element E.
 * @param RESULT The address where the result code will be stored.
 * @return the root containing E and RESULT = GDSL_INSERTED if E is inserted.
 * @return the root containing E and RESULT = GDSL_ERR_DUPLICATE_ENTRY if E is
 * not inserted.
 * @return NULL and RESULT = GDSL_ERR_MEM_ALLOC in case of failure.
 * @see _gdsl_bstree_search()
 * @see _gdsl_bstree_remove()
 */
extern _gdsl_bstree_t
_gdsl_bstree_insert (_gdsl_bstree_t* T,
		     const gdsl_compare_func_t COMP_F,
		     const gdsl_element_t VALUE,
		     int* RESULT
		     );

/**
 * @brief Remove an element from a low-level binary search tree.
 *
 * Remove from the low-level binary search tree T the first founded element E
 * equal to VALUE, by using COMP_F function to compare T's elements. If E is 
 * found, it is removed from T.
 *
 * @note Complexity: O( h(T) ), where log2(|T|) <= h(T) <= |T|-1
 * @note The resulting T is modified by examinating the left sub-tree from the
 * founded e.
 * @pre COMP_F != NULL.
 * @param T The reference of the low-level binary search tree to modify.
 * @param COMP_F The comparison function to use to compare T's elements with
 * VALUE to find the element e to remove.
 * @param VALUE The value that must be used by COMP_F to find the element e to
 * remove.
 * @return the fisrt founded element equal to VALUE in T.
 * @return NULL if no element equal to VALUE is found or if T is empty.
 * @see _gdsl_bstree_insert()
 * @see _gdsl_bstree_search()
 */
extern gdsl_element_t
_gdsl_bstree_remove (_gdsl_bstree_t* T,
		     const gdsl_compare_func_t COMP_F,
		     const gdsl_element_t VALUE
		     );
  
/******************************************************************************/
/* Search functions of low-level binary search trees                          */
/******************************************************************************/

/**
 * @brief Search for a particular element into a low-level binary search tree.
 *
 * Search the first element E equal to VALUE in the low-level binary search tree
 * T, by using COMP_F function to find it.
 *
 * @note Complexity: O( h(T) ), where log2(|T|) <= h(T) <= |T|-1
 * @pre COMP_F != NULL.
 * @param T The low-level binary search tree to use.
 * @param COMP_F The comparison function to use to compare T's elements with 
 * VALUE to find the element E.
 * @param VALUE The value that must be used by COMP_F to find the element E.
 * @return the root of the tree containing E if it's found.
 * @return NULL if VALUE is not found in T.
 * @see _gdsl_bstree_insert()
 * @see _gdsl_bstree_remove()
 */
extern _gdsl_bstree_t
_gdsl_bstree_search (const _gdsl_bstree_t T,
		     const gdsl_compare_func_t COMP_F,
		     const gdsl_element_t VALUE
		     );

/**
 * @brief Search for the next element of a particular element into a low-level 
 * binary search tree, according to the binary search tree order.
 *
 * Search for an element E in the low-level binary search tree T, by using 
 * COMP_F function to find the first element E equal to VALUE. 
 *
 * @note Complexity: O( h(T) ), where log2(|T|) <= h(T) <= |T|-1
 * @pre COMP_F != NULL.
 * @param T The low-level binary search tree to use.
 * @param COMP_F The comparison function to use to compare T's elements with 
 * VALUE to find the element E.
 * @param VALUE The value that must be used by COMP_F to find the element E.
 * @return the root of the tree containing the successor of E if it's found.
 * @return NULL if VALUE is not found in T or if E has no sucessor.
 */
extern _gdsl_bstree_t
_gdsl_bstree_search_next (const _gdsl_bstree_t T, 
			  const gdsl_compare_func_t COMP_F,
			  const gdsl_element_t VALUE
			  );

/******************************************************************************/
/* Parse functions of low-level binary search trees                           */
/******************************************************************************/

/**
 * @brief Parse a low-level binary search tree in prefixed order.
 *
 * Parse all nodes of the low-level binary search tree T in prefixed order. The 
 * MAP_F function is called on each node with the USER_DATA argument. If MAP_F
 * returns GDSL_MAP_STOP, then _gdsl_bstree_map_prefix() stops and returns its 
 * last examinated node.
 *
 * @note Complexity: O( |T| )
 * @pre MAP_F != NULL.
 * @param T The low-level binary search tree to map.
 * @param MAP_F The map function.
 * @param USER_DATA User's datas passed to MAP_F.
 * @return the first node for which MAP_F returns GDSL_MAP_STOP.
 * @return NULL when the parsing is done.
 * @see _gdsl_bstree_map_infix()
 * @see _gdsl_bstree_map_postfix()
 */
extern _gdsl_bstree_t
_gdsl_bstree_map_prefix (const _gdsl_bstree_t T,
			 const _gdsl_bstree_map_func_t MAP_F,
			 void* USER_DATA
			 );

/**
 * @brief Parse a low-level binary search tree in infixed order.
 *
 * Parse all nodes of the low-level binary search tree T in infixed order. The 
 * MAP_F function is called on each node with the USER_DATA argument. If MAP_F
 * returns GDSL_MAP_STOP, then _gdsl_bstree_map_infix() stops and returns its 
 * last examinated node.
 *
 * @note Complexity: O( |T| )
 * @pre MAP_F != NULL.
 * @param T The low-level binary search tree to map.
 * @param MAP_F The map function.
 * @param USER_DATA User's datas passed to MAP_F.
 * @return the first node for which MAP_F returns GDSL_MAP_STOP.
 * @return NULL when the parsing is done.
 * @see _gdsl_bstree_map_prefix()
 * @see _gdsl_bstree_map_postfix()
 */
extern _gdsl_bstree_t
_gdsl_bstree_map_infix (const _gdsl_bstree_t T,
			const _gdsl_bstree_map_func_t MAP_F,
			void* USER_DATA
			);

/**
 * @brief Parse a low-level binary search tree in postfixed order.
 *
 * Parse all nodes of the low-level binary search tree T in postfixed order. The
 * MAP_F function is called on each node with the USER_DATA argument. If MAP_F
 * returns GDSL_MAP_STOP, then _gdsl_bstree_map_postfix() stops and returns its 
 * last examinated node.
 *
 * @note Complexity: O( |T| )
 * @pre MAP_F != NULL.
 * @param T The low-level binary search tree to map.
 * @param MAP_F The map function.
 * @param USER_DATA User's datas passed to MAP_F.
 * @return the first node for which MAP_F returns GDSL_MAP_STOP.
 * @return NULL when the parsing is done.
 * @see _gdsl_bstree_map_prefix()
 * @see _gdsl_bstree_map_infix()
 */
extern _gdsl_bstree_t
_gdsl_bstree_map_postfix (const _gdsl_bstree_t T,
			  const _gdsl_bstree_map_func_t MAP_F,
			  void* USER_DATA
			  );

/******************************************************************************/
/* Input/output functions of low-level binary search trees                    */
/******************************************************************************/

/**
 * @brief Write the content of all nodes of a low-level binary search tree to a
 * file.
 *
 * Write the nodes contents of the low-level binary search tree T to 
 * OUTPUT_FILE, using WRITE_F function.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |T| )
 * @pre WRITE_F != NULL& OUTPUT_FILE != NULL.
 * @param T The low-level binary search tree to write.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write T's nodes.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see _gdsl_bstree_write_xml()
 * @see _gdsl_bstree_dump()
 */
extern void
_gdsl_bstree_write (const _gdsl_bstree_t T,
		    const _gdsl_bstree_write_func_t WRITE_F,
		    FILE* OUTPUT_FILE,
		    void* USER_DATA
		    );

/**
 * @brief Write the content of a low-level binary search tree to a file into 
 * XML.
 *
 * Write the nodes contents of the low-level binary search tree T to 
 * OUTPUT_FILE, into XML language.
 * If WRITE_F != NULL, then use WRITE_F function to write T's nodes contents to
 * OUTPUT_FILE.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |T| )
 * @pre OUTPUT_FILE != NULL.
 * @param T The low-level binary search tree to write.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write T's nodes.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see _gdsl_bstree_write()
 * @see _gdsl_bstree_dump()
 */
extern void
_gdsl_bstree_write_xml (const _gdsl_bstree_t T,
			const _gdsl_bstree_write_func_t WRITE_F,
			FILE* OUTPUT_FILE,
			void* USER_DATA
			);

/**
 * @brief Dump the internal structure of a low-level binary search tree to a 
 * file.
 *
 * Dump the structure of the low-level binary search tree T to OUTPUT_FILE. If 
 * WRITE_F != NULL, then use WRITE_F function to write T's nodes content to 
 * OUTPUT_FILE.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |T| )
 * @pre OUTPUT_FILE != NULL.
 * @param T The low-level binary search tree to dump.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write T's nodes.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see _gdsl_bstree_write()
 * @see _gdsl_bstree_write_xml()
 */
extern void
_gdsl_bstree_dump (const _gdsl_bstree_t T,
		   const _gdsl_bstree_write_func_t WRITE_F,
		   FILE* OUTPUT_FILE,
		   void* USER_DATA
		   );

/*
 * @}
 */


#ifdef __cplusplus
}
#endif /* __cplusplus */


#endif /* _GDSL_BSTREE_H_ */


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
