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
 * $RCSfile: _gdsl_list.h,v $
 * $Revision: 1.27 $
 * $Date: 2006/03/04 16:32:05 $
 */


#ifndef __GDSL_LIST_H_
#define __GDSL_LIST_H_


#include <stdio.h>


#include "_gdsl_node.h"
#include "gdsl_types.h"


#ifdef __cplusplus
extern "C" 
{
#endif /* __cplusplus */


/**
 * @defgroup _gdsl_list Low-level doubly-linked list manipulation module
 * @{
 */

/**
 * @brief GDSL low-level doubly-linked list type.
 *
 * This type is voluntary opaque. Variables of this kind could'nt be directly
 * used, but by the functions of this module.
 */
typedef _gdsl_node_t _gdsl_list_t;

/******************************************************************************/
/* Management functions of low-level doubly-linked lists                      */
/******************************************************************************/

/**
 * @brief Create a new low-level list.
 *
 * Allocate a new low-level list data structure which have only one node.
 * The node's content is set to E.
 *
 * @note Complexity: O( 1 )
 * @pre nothing.
 * @param E The content of the first node of the new low-level list to create.
 * @return the newly allocated low-level list in case of success.
 * @return NULL in case of insufficient memory.
 * @see _gdsl_list_free()
 */
extern _gdsl_list_t
_gdsl_list_alloc (const gdsl_element_t E
		  );

/**
 * @brief Destroy a low-level list.
 *
 * Flush and destroy the low-level list L. If FREE_F != NULL, then the FREE_F
 * function is used to deallocated each L's element. Otherwise, nothing is
 * done with L's elements.
 *
 * @note Complexity: O( |L| )
 * @pre nothing.
 * @param L The low-level list to destroy.
 * @param FREE_F The function used to deallocated L's nodes contents.
 * @see _gdsl_list_alloc()
 */
extern void 
_gdsl_list_free (_gdsl_list_t L,
		 const gdsl_free_func_t FREE_F
		 );

/******************************************************************************/
/* Consultation functions of low-level doubly-linked lists                    */
/******************************************************************************/

/**
 * @brief Check if a low-level list is empty.
 *
 * @note Complexity: O( 1 )
 * @pre nothing.
 * @param L The low-level list to check.
 * @return TRUE if the low-level list L is empty.
 * @return FALSE if the low-level list L is not empty.
 */
extern bool
_gdsl_list_is_empty (const _gdsl_list_t L
		     );

/**
 * @brief Get the size of a low-level list.
 * @note Complexity: O( |L| )
 * @pre nothing.
 * @param L The low-level list to use.
 * @return the number of elements of L (noted |L|).
 */
extern ulong
_gdsl_list_get_size (const _gdsl_list_t L
		     );

/******************************************************************************/
/* Modification functions of low-level doubly-linked lists                    */
/******************************************************************************/

/**
 * @brief Link two low-level lists together.
 *
 * Link the low-level list L2 after the end of the low-level list L1. So L1 is
 * before L2.
 *
 * @note Complexity: O( |L1| )
 * @pre L1 & L2 must be non-empty _gdsl_list_t.
 * @param L1 The low-level list to link before L2.
 * @param L2 The low-level list to link after L1.
 */
extern void
_gdsl_list_link (_gdsl_list_t L1,
		 _gdsl_list_t L2
		 );

/**
 * @brief Insert a low-level list after another one.
 * 
 * Insert the low-level list L after the low-level list PREV.
 *
 * @note Complexity: O( |L| )
 * @pre L & PREV must be non-empty _gdsl_list_t.
 * @param L The low-level list to link after PREV.
 * @param PREV The low-level list that will be linked before L.
 * @see _gdsl_list_insert_before()
 * @see _gdsl_list_remove()
 */
extern void 
_gdsl_list_insert_after (_gdsl_list_t L,
			 _gdsl_list_t PREV
			 );

/**
 * @brief Insert a low-level list before another one.
 *
 * Insert the low-level list L before the low-level list SUCC.
 *
 * @note Complexity: O( |L| )
 * @pre L & SUCC must be non-empty _gdsl_list_t.
 * @param L The low-level list to link before SUCC.
 * @param SUCC The low-level list that will be linked after L.
 * @see _gdsl_list_insert_after()
 * @see _gdsl_list_remove()
 */
extern void
_gdsl_list_insert_before (_gdsl_list_t L,
			  _gdsl_list_t SUCC
			  );

/**
 * @brief Remove a node from a low-level list.
 *
 * Unlink the node NODE from the low-level list in which it is inserted.
 *
 * @note Complexity: O( 1 )
 * @pre NODE must be a non-empty _gdsl_node_t.
 * @param NODE The low-level node to unlink from the low-level list in which
 * it's linked.
 * @see _gdsl_list_insert_after()
 * @see _gdsl_list_insert_before()
 */
extern void
_gdsl_list_remove (_gdsl_node_t NODE
		   );

/******************************************************************************/
/* Search functions of low-level doubly-linked lists                          */
/******************************************************************************/
 
/**
 * @brief Search for a particular node in a low-level list.
 *
 * Research an element e in the low-level list L, by using COMP_F function to
 * find the first element e equal to VALUE.
 *
 * @note Complexity: O( |L| )
 * @pre COMP_F != NULL
 * @param L The low-level list to use
 * @param COMP_F The comparison function to use to compare L's elements with
 * VALUE to find the element e
 * @param VALUE The value that must be used by COMP_F to find the element e
 * @return the sub-list starting by e if it's found.
 * @return NULL if VALUE is not found in L.
 */
extern _gdsl_list_t
_gdsl_list_search (_gdsl_list_t L,
 		   const gdsl_compare_func_t COMP_F,
 		   void* VALUE
 		   );

/******************************************************************************/
/* Parse functions of low-level doubly-linked lists                           */
/******************************************************************************/

/**
 * @brief Parse a low-level list in forward order.
 *
 * Parse all nodes of the low-level list L in forward order. The MAP_F function 
 * is called on each node with the USER_DATA argument. If MAP_F returns 
 * GDSL_MAP_STOP, then _gdsl_list_map_forward() stops and returns its last 
 * examinated node.
 *
 * @note Complexity: O( |L| )
 * @pre MAP_F != NULL.
 * @param L Th low-level list to map.
 * @param MAP_F The map function.
 * @param USER_DATA User's datas.
 * @return the first node for which MAP_F returns GDSL_MAP_STOP.
 * @return NULL when the parsing is done.
 * @see _gdsl_list_map_backward()
 */
extern _gdsl_list_t
_gdsl_list_map_forward (const _gdsl_list_t L,
			const _gdsl_node_map_func_t MAP_F,
			void* USER_DATA
			);
		
/**
 * @brief Parse a low-level list in backward order.
 *
 * Parse all nodes of the low-level list L in backward order. The MAP_F function 
 * is called on each node with the USER_DATA argument. If MAP_F returns 
 * GDSL_MAP_STOP, then _gdsl_list_map_backward() stops and returns its last 
 * examinated node.
 *
 * @note Complexity: O( 2 |L| )
 * @pre L must be a non-empty _gdsl_list_t & MAP_F != NULL.
 * @param L Th low-level list to map.
 * @param MAP_F The map function.
 * @param USER_DATA User's datas.
 * @return the first node for which MAP_F returns GDSL_MAP_STOP.
 * @return NULL when the parsing is done.
 * @see _gdsl_list_map_forward()
 */
extern _gdsl_list_t
_gdsl_list_map_backward (const _gdsl_list_t L,
			 const _gdsl_node_map_func_t MAP_F,
			 void* USER_DATA
			 );

/******************************************************************************/
/* Input/output functions of low-level doubly-linked lists                    */
/******************************************************************************/

/**
 * @brief Write all nodes of a low-level list to a file.
 *
 * Write the nodes of the low-level list L to OUTPUT_FILE, using WRITE_F 
 * function.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |L| )
 * @pre WRITE_F != NULL & OUTPUT_FILE != NULL.
 * @param L The low-level list to write.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write L's nodes.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see _gdsl_list_write_xml()
 * @see _gdsl_list_dump()
 */
extern void
_gdsl_list_write (const _gdsl_list_t L,
		  const _gdsl_node_write_func_t WRITE_F,
		  FILE* OUTPUT_FILE,
		  void* USER_DATA
		  );

/**
 * @brief Write all nodes of a low-level list to a file into XML.
 *
 * Write the nodes of the low-level list L to OUTPUT_FILE, into XML 
 * language.
 * If WRITE_F != NULL, then uses WRITE_F function to write L's nodes to 
 * OUTPUT_FILE.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |L| )
 * @pre OUTPUT_FILE != NULL.
 * @param L The low-level list to write.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write L's nodes.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see _gdsl_list_write()
 * @see _gdsl_list_dump()
 */
extern void
_gdsl_list_write_xml (const _gdsl_list_t L,
		      const _gdsl_node_write_func_t WRITE_F,
		      FILE* OUTPUT_FILE,
		      void* USER_DATA
		      );
		     
/**
 * @brief Dump the internal structure of a low-level list to a file.
 *
 * Dump the structure of the low-level list L to OUTPUT_FILE. 
 * If WRITE_F != NULL, then uses WRITE_F function to write L's nodes to 
 * OUTPUT_FILE.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |L| )
 * @pre OUTPUT_FILE != NULL.
 * @param L The low-level list to dump.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write L's nodes.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see _gdsl_list_write()
 * @see _gdsl_list_write_xml()
 */
extern void
_gdsl_list_dump (const _gdsl_list_t L,
		 const _gdsl_node_write_func_t WRITE_F,
		 FILE* OUTPUT_FILE,
		 void* USER_DATA
		 );

/*
 * @}
 */


#ifdef __cplusplus
}
#endif /* __cplusplus */


#endif /* __GDSL_LIST_H_ */


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
