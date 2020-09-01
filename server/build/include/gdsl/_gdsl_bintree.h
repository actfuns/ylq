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
 * $RCSfile: _gdsl_bintree.h,v $
 * $Revision: 1.29 $
 * $Date: 2006/03/04 16:32:05 $
 */


#ifndef __GDSL_BINTREE_H_
#define __GDSL_BINTREE_H_


#include <stdio.h>


#include "gdsl_types.h"
#include "gdsl_macros.h"


#if __cplusplus
extern "C" 
{
#endif /* __cplusplus */


/**
 * @defgroup _gdsl_bintree Low level binary tree manipulation module
 * @{
 */

/**
 * @brief GDSL low-level binary tree type.
 *
 * This type is voluntary opaque. Variables of this kind could'nt be directly
 * used, but by the functions of this module.
 */
typedef struct _gdsl_bintree* _gdsl_bintree_t;

/**
 * @brief GDSL low-level binary tree map function type.
 * @param TREE The low-level binary tree to map.
 * @param USER_DATA The user datas to pass to this function.
 * @return GDSL_MAP_STOP if the mapping must be stopped.
 * @return GDSL_MAP_CONT if the mapping must be continued.
 */
typedef int (* _gdsl_bintree_map_func_t) (const _gdsl_bintree_t TREE,
					  void* USER_DATA
					  );

/**
 * @brief GDSL low-level binary tree write function type.
 * @param TREE The low-level binary tree to write.
 * @param OUTPUT_FILE The file where to write TREE.
 * @param USER_DATA The user datas to pass to this function.
 */
typedef void (* _gdsl_bintree_write_func_t) (const _gdsl_bintree_t TREE,
					     FILE* OUTPUT_FILE,
					     void* USER_DATA
					     );

/******************************************************************************/
/* Management functions of low-level binary trees                             */
/******************************************************************************/

/**
 * @brief Create a new low-level binary tree.
 *
 * Allocate a new low-level binary tree data structure. Its root content is 
 * set to E and its left son (resp. right) is set to LEFT (resp. RIGHT).
 *
 * @note Complexity: O( 1 )
 * @pre nothing.
 * @param E The root content of the new low-level binary tree to create.
 * @param LEFT The left sub-tree of the new low-level binary tree to create.
 * @param RIGHT The right sub-tree of the new low-level binary tree to create.
 * @return the newly allocated low-level binary tree in case of success.
 * @return NULL in case of insufficient memory.
 * @see _gdsl_bintree_free()
 */
extern _gdsl_bintree_t
_gdsl_bintree_alloc (const gdsl_element_t E,
		     const _gdsl_bintree_t LEFT,
		     const _gdsl_bintree_t RIGHT
		     );

/**
 * @brief Destroy a low-level binary tree.
 *
 * Flush and destroy the low-level binary tree T. If FREE_F != NULL, FREE_F 
 * function is used to deallocate each T's element. Otherwise nothing is done 
 * with T's elements.
 *
 * @note Complexity: O( |T| )
 * @pre nothing.
 * @param T The low-level binary tree to destroy.
 * @param FREE_F The function used to deallocate T's nodes contents.
 * @see _gdsl_bintree_alloc()
 */
extern void 
_gdsl_bintree_free (_gdsl_bintree_t T,
		    const gdsl_free_func_t FREE_F
		    );

/**
 * @brief Copy a low-level binary tree.
 *
 * Create and return a copy of the low-level binary tree T using COPY_F on 
 * each T's element to copy them.
 *
 * @note Complexity: O( |T| )
 * @pre COPY_F != NULL
 * @param T The low-level binary tree to copy.
 * @param COPY_F The function used to copy T's nodes contents.
 * @return a copy of T in case of success.
 * @return NULL if _gdsl_bintree_is_empty (T) == TRUE or in case of insufficient
 * memory.
 * @see _gdsl_bintree_alloc()
 * @see _gdsl_bintree_free()
 * @see _gdsl_bintree_is_empty()
 */
extern _gdsl_bintree_t
_gdsl_bintree_copy (const _gdsl_bintree_t T,
		    const gdsl_copy_func_t COPY_F
		    );

/******************************************************************************/
/* Consultation functions of low-level binary trees                           */
/******************************************************************************/

/** 
 * @brief Check if a low-level binary tree is empty.
 * @note Complexity: O( 1 )
 * @pre nothing.
 * @param T The low-level binary tree to check.
 * @return TRUE if the low-level binary tree T is empty.
 * @return FALSE if the low-level binary tree T is not empty.
 * @see _gdsl_bintree_is_leaf()
 * @see _gdsl_bintree_is_root()
 */
extern bool
_gdsl_bintree_is_empty (const _gdsl_bintree_t T
			);
  
/**
 * @brief Check if a low-level binary tree is reduced to a leaf.
 * @note Complexity: O( 1 )
 * @pre T must be a non-empty _gdsl_bintree_t.
 * @param T The low-level binary tree to check.
 * @return TRUE if the low-level binary tree T is a leaf.
 * @return FALSE if the low-level binary tree T is not a leaf.
 * @see _gdsl_bintree_is_empty()
 * @see _gdsl_bintree_is_root()
 */
extern bool
_gdsl_bintree_is_leaf (const _gdsl_bintree_t T
		       );

/**
 * @brief Check if a low-level binary tree is a root.
 * @note Complexity: O( 1 )
 * @pre T must be a non-empty _gdsl_bintree_t.
 * @param T The low-level binary tree to check.
 * @return TRUE if the low-level binary tree T is a root.
 * @return FALSE if the low-level binary tree T is not a root.
 * @see _gdsl_bintree_is_empty()
 * @see _gdsl_bintree_is_leaf()
 */
extern bool
_gdsl_bintree_is_root (const _gdsl_bintree_t T
		       );

/**
 * @brief Get the root content of a low-level binary tree.
 * @note Complexity: O( 1 )
 * @pre T must be a non-empty _gdsl_bintree_t.
 * @param T The low-level binary tree to use.
 * @return the root's content of the low-level binary tree T.
 * @see _gdsl_bintree_set_content()
 */
extern gdsl_element_t
_gdsl_bintree_get_content (const _gdsl_bintree_t T
			   );

/**
 * @brief Get the parent tree of a low-level binary tree.
 * @note Complexity: O( 1 )
 * @pre T must be a non-empty _gdsl_bintree_t.
 * @param T The low-level binary tree to use.
 * @return the parent of the low-level binary tree T if T isn't a root.
 * @return NULL if the low-level binary tree T is a root (ie. T has no parent).
 * @see _gdsl_bintree_is_root()
 * @see _gdsl_bintree_set_parent()
 */
extern _gdsl_bintree_t
_gdsl_bintree_get_parent (const _gdsl_bintree_t T
			  );

/**
 * @brief Get the left sub-tree of a low-level binary tree.
 *
 * Return the left subtree of the low-level binary tree T (noted l(T)).
 *
 * @note Complexity: O( 1 )
 * @pre T must be a non-empty _gdsl_bintree_t.
 * @param T The low-level binary tree to use.
 * @return the left sub-tree of the low-level binary tree T if T has a left
 * sub-tree. 
 * @return NULL if the low-level binary tree T has no left sub-tree.
 * @see _gdsl_bintree_get_right()
 * @see _gdsl_bintree_set_left()
 * @see _gdsl_bintree_set_right()
 */
extern _gdsl_bintree_t
_gdsl_bintree_get_left (const _gdsl_bintree_t T
			);

/**
 * @brief Get the right sub-tree of a low-level binary tree.
 *
 * Return the right subtree of the low-level binary tree T (noted r(T)).
 *
 * @note Complexity: O( 1 )
 * @pre T must be a non-empty _gdsl_bintree_t
 * @param T The low-level binary tree to use.
 * @return the right sub-tree of the low-level binary tree T if T has a right 
 * sub-tree. 
 * @return NULL if the low-level binary tree T has no right sub-tree.
 * @see _gdsl_bintree_get_left()
 * @see _gdsl_bintree_set_left()
 * @see _gdsl_bintree_set_right()
 */
extern _gdsl_bintree_t
_gdsl_bintree_get_right (const _gdsl_bintree_t T
			 );

/**
 * @brief Get the left sub-tree reference of a low-level binary tree.
 * @note Complexity: O( 1 )
 * @pre T must be a non-empty _gdsl_bintree_t.
 * @param T The low-level binary tree to use.
 * @return the left sub-tree reference of the low-level binary tree T.
 * @see _gdsl_bintree_get_right_ref()
 */
extern _gdsl_bintree_t*
_gdsl_bintree_get_left_ref (const _gdsl_bintree_t T
			    );

/**
 * @brief Get the right sub-tree reference of a low-level binary tree.
 * @note Complexity: O( 1 )
 * @pre T must be a non-empty _gdsl_bintree_t.
 * @param T The low-level binary tree to use.
 * @return the right sub-tree reference of the low-level binary tree T.
 * @see _gdsl_bintree_get_left_ref()
 */
extern _gdsl_bintree_t*
_gdsl_bintree_get_right_ref (const _gdsl_bintree_t T
			     );

/**
 * @brief Get the height of a low-level binary tree.
 *
 * Compute the height of the low-level binary tree T (noted h(T)).
 *
 * @note Complexity: O( |T| )
 * @pre nothing.
 * @param T The low-level binary tree to use.
 * @return the height of T.
 * @see _gdsl_bintree_get_size()
 */
extern ulong
_gdsl_bintree_get_height (const _gdsl_bintree_t T
			  );

/**
 * @brief Get the size of a low-level binary tree.
 * @note Complexity: O( |T| )
 * @pre nothing.
 * @param T The low-level binary tree to use.
 * @return the number of elements of T  (noted |T|).
 * @see _gdsl_bintree_get_height()
 */
extern ulong
_gdsl_bintree_get_size (const _gdsl_bintree_t T
			);

/******************************************************************************/
/* Modification functions of low-level binary trees                           */
/******************************************************************************/

/**
 * @brief Set the root element of a low-level binary tree.
 *
 * Modify the root element of the low-level binary tree T to E.
 * 
 * @note Complexity: O( 1 )
 * @pre T must be a non-empty _gdsl_bintree_t.
 * @param T The low-level binary tree to modify.
 * @param E The new T's root content.
 * @see _gdsl_bintree_get_content
 */
extern void
_gdsl_bintree_set_content (_gdsl_bintree_t T,
			   const gdsl_element_t E
			   );

/**
 * @brief Set the parent tree of a low-level binary tree.
 *
 * Modify the parent of the low-level binary tree T to P.
 * 
 * @note Complexity: O( 1 )
 * @pre T must be a non-empty _gdsl_bintree_t.
 * @param T The low-level binary tree to modify.
 * @param P The new T's parent.
 * @see _gdsl_bintree_get_parent()
 */
extern void
_gdsl_bintree_set_parent (_gdsl_bintree_t T,
			  const _gdsl_bintree_t P
			  );

/**
 * @brief Set left sub-tree of a low-level binary tree.
 *
 * Modify the left sub-tree of the low-level binary tree T to L.
 * 
 * @note Complexity: O( 1 )
 * @pre T must be a non-empty _gdsl_bintree_t.
 * @param T The low-level binary tree to modify.
 * @param L The new T's left sub-tree.
 * @see _gdsl_bintree_set_right()
 * @see _gdsl_bintree_get_left()
 * @see _gdsl_bintree_get_right()
 */
extern void
_gdsl_bintree_set_left (_gdsl_bintree_t T,
			const _gdsl_bintree_t L
			);
  
/**
 * @brief Set right sub-tree of a low-level binary tree.
 *
 * Modify the right sub-tree of the low-level binary tree T to R.
 * 
 * @note Complexity: O( 1 )
 * @pre T must be a non-empty _gdsl_bintree_t.
 * @param T The low-level binary tree to modify.
 * @param R The new T's right sub-tree.
 * @see _gdsl_bintree_set_left()
 * @see _gdsl_bintree_get_left()
 * @see _gdsl_bintree_get_right()
 */
extern void
_gdsl_bintree_set_right (_gdsl_bintree_t T,
			 const _gdsl_bintree_t R
			 );

/******************************************************************************/
/* Rotation functions of low-level binary trees                               */
/******************************************************************************/

/**
 * @brief Left rotate a low-level binary tree.
 *
 * Do a left rotation of the low-level binary tree T.
 * 
 * @note Complexity: O( 1 )
 * @pre T & r(T) must be non-empty _gdsl_bintree_t.
 * @param T The low-level binary tree to rotate.
 * @return the modified T left-rotated.
 * @see _gdsl_bintree_rotate_right()
 * @see _gdsl_bintree_rotate_left_right()
 * @see _gdsl_bintree_rotate_right_left()
 */
extern _gdsl_bintree_t
_gdsl_bintree_rotate_left (_gdsl_bintree_t* T
			   );

/**
 * @brief Right rotate a low-level binary tree.
 *
 * Do a right rotation of the low-level binary tree T.
 *
 * @note Complexity: O( 1 )
 * @pre T & l(T) must be non-empty _gdsl_bintree_t.
 * @param T The low-level binary tree to rotate.
 * @return the modified T right-rotated.
 * @see _gdsl_bintree_rotate_left()
 * @see _gdsl_bintree_rotate_left_right()
 * @see _gdsl_bintree_rotate_right_left()
 */
extern _gdsl_bintree_t
_gdsl_bintree_rotate_right (_gdsl_bintree_t* T
			    );

/**
 * @brief Left-right rotate a low-level binary tree.
 *
 * Do a double left-right rotation of the low-level binary tree T.
 * 
 * @note Complexity: O( 1 )
 * @pre T & l(T) & r(l(T)) must be non-empty _gdsl_bintree_t.
 * @param T The low-level binary tree to rotate.
 * @return the modified T left-right-rotated.
 * @see _gdsl_bintree_rotate_left()
 * @see _gdsl_bintree_rotate_right()
 * @see _gdsl_bintree_rotate_right_left()
 */
extern _gdsl_bintree_t
_gdsl_bintree_rotate_left_right (_gdsl_bintree_t* T
				 );

/**
 * @brief Right-left rotate a low-level binary tree.
 *
 * Do a double right-left rotation of the low-level binary tree T.
 * 
 * @note Complexity: O( 1 )
 * @pre T & r(T) & l(r(T)) must be non-empty _gdsl_bintree_t.
 * @param T The low-level binary tree to rotate.
 * @return the modified T right-left-rotated.
 * @see _gdsl_bintree_rotate_left()
 * @see _gdsl_bintree_rotate_right()
 * @see _gdsl_bintree_rotate_left_right()
 */
extern _gdsl_bintree_t
_gdsl_bintree_rotate_right_left (_gdsl_bintree_t* T
				 );

/******************************************************************************/
/* Parse functions of low-level binary trees                                  */
/******************************************************************************/

/**
 * @brief Parse a low-level binary tree in prefixed order.
 *
 * Parse all nodes of the low-level binary tree T in prefixed order. The MAP_F 
 * function is called on each node with the USER_DATA argument. If MAP_F 
 * returns GDSL_MAP_STOP, then _gdsl_bintree_map_prefix() stops and returns its
 * last examinated node.
 *
 * @note Complexity: O( |T| )
 * @pre MAP_F != NULL
 * @param T The low-level binary tree to map.
 * @param MAP_F The map function.
 * @param USER_DATA User's datas.
 * @return the first node for which MAP_F returns GDSL_MAP_STOP.
 * @return NULL when the parsing is done.
 * @see _gdsl_bintree_map_infix()
 * @see _gdsl_bintree_map_postfix()
 */
extern _gdsl_bintree_t
_gdsl_bintree_map_prefix (const _gdsl_bintree_t T,
			  const _gdsl_bintree_map_func_t MAP_F,
			  void* USER_DATA
			  );

/**
 * @brief Parse a low-level binary tree in infixed order.
 *
 * Parse all nodes of the low-level binary tree T in infixed order. The MAP_F 
 * function is called on each node with the USER_DATA argument. If MAP_F 
 * returns GDSL_MAP_STOP, then _gdsl_bintree_map_infix() stops and returns its 
 * last examinated node.
 *
 * @note Complexity: O( |T| )
 * @pre MAP_F != NULL
 * @param T The low-level binary tree to map.
 * @param MAP_F The map function.
 * @param USER_DATA User's datas.
 * @return the first node for which MAP_F returns GDSL_MAP_STOP.
 * @return NULL when the parsing is done.
 * @see _gdsl_bintree_map_prefix()
 * @see _gdsl_bintree_map_postfix()
 */
extern _gdsl_bintree_t
_gdsl_bintree_map_infix (const _gdsl_bintree_t T,
			 const _gdsl_bintree_map_func_t MAP_F,
			 void* USER_DATA
			 );

/**
 * @brief Parse a low-level binary tree in postfixed order.
 *
 * Parse all nodes of the low-level binary tree T in postfixed order. The MAP_F 
 * function is called on each node with the USER_DATA argument. If MAP_F 
 * returns GDSL_MAP_STOP, then _gdsl_bintree_map_postfix() stops and returns its
 * last examinated node.
 *
 * @note Complexity: O( |T| )
 * @pre MAP_F != NULL
 * @param T The low-level binary tree to map.
 * @param MAP_F The map function.
 * @param USER_DATA User's datas.
 * @return the first node for which MAP_F returns GDSL_MAP_STOP.
 * @return NULL when the parsing is done.
 * @see _gdsl_bintree_map_prefix()
 * @see _gdsl_bintree_map_infix()
 */
extern _gdsl_bintree_t
_gdsl_bintree_map_postfix (const _gdsl_bintree_t T,
			   const _gdsl_bintree_map_func_t MAP_F,
			   void* USER_DATA
			   );

/******************************************************************************/
/* Input/output functions of low-level binary trees                           */
/******************************************************************************/

/**
 * @brief Write the content of all nodes of a low-level binary tree to a file.
 *
 * Write the nodes contents of the low-level binary tree T to OUTPUT_FILE, 
 * using WRITE_F function.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |T| )
 * @pre WRITE_F != NULL & OUTPUT_FILE != NULL
 * @param T The low-level binary tree to write.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write T's nodes.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see _gdsl_bintree_write_xml()
 * @see _gdsl_bintree_dump()
 */
extern void
_gdsl_bintree_write (const _gdsl_bintree_t T,
		     const _gdsl_bintree_write_func_t WRITE_F,
		     FILE* OUTPUT_FILE,
		     void* USER_DATA
		     );

/**
 * @brief Write the content of a low-level binary tree to a file into XML.
 *
 * Write the nodes contents of the low-level binary tree T to OUTPUT_FILE, 
 * into XML language. If WRITE_F != NULL, then uses WRITE_F function to write 
 * T's nodes content to OUTPUT_FILE.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |T| )
 * @pre OUTPUT_FILE != NULL
 * @param T The low-level binary tree to write.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write T's nodes.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see _gdsl_bintree_write()
 * @see _gdsl_bintree_dump()
 */
extern void
_gdsl_bintree_write_xml (const _gdsl_bintree_t T,
			 const _gdsl_bintree_write_func_t WRITE_F,
			 FILE* OUTPUT_FILE,
			 void* USER_DATA
			 );

/**
 * @brief Dump the internal structure of a low-level binary tree to a file.
 *
 * Dump the structure of the low-level binary tree T to OUTPUT_FILE. If 
 * WRITE_F != NULL, then use WRITE_F function to write T's nodes contents to 
 * OUTPUT_FILE.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |T| )
 * @pre OUTPUT_FILE != NULL
 * @param T The low-level binary tree to dump.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write T's nodes.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see _gdsl_bintree_write()
 * @see _gdsl_bintree_write_xml()
 */
extern void
_gdsl_bintree_dump (const _gdsl_bintree_t T,
		    const _gdsl_bintree_write_func_t WRITE_F,
		    FILE* OUTPUT_FILE,
		    void* USER_DATA
		    );

/*
 * @}
 */


#ifdef __cplusplus
}
#endif /* __cplusplus */


#endif /* __GDSL_BINTREE_H_ */


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
