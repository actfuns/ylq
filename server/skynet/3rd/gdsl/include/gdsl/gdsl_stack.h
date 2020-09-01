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
 * $RCSfile: gdsl_stack.h,v $
 * $Revision: 1.17 $
 * $Date: 2006/03/04 16:32:05 $
 */


#ifndef _GDSL_STACK_H_
#define _GDSL_STACK_H_


#include <stdio.h>


#include "gdsl_types.h"

#ifdef __cplusplus
extern "C" 
{
#endif /* __cplusplus */


/**
 * @defgroup gdsl_stack Stack manipulation module
 * @{
 */


/**
 * @brief GDSL stack type.
 *
 * This type is voluntary opaque. Variables of this kind could'nt be directly
 * used, but by the functions of this module.
 */
typedef struct _gdsl_stack* gdsl_stack_t;

/******************************************************************************/
/* Management functions of stacks                                             */
/******************************************************************************/

/**
 * @brief Create a new stack.
 *
 * Allocate a new stack data structure which name is set to a copy of NAME.
 * The functions pointers ALLOC_F and FREE_F could be used to respectively, 
 * alloc and free elements in the stack. These pointers could be set to NULL to
 * use the default ones:
 * - the default ALLOC_F simply returns its argument
 * - the default FREE_F does nothing
 *
 * @note Complexity: O( 1 )
 * @pre nothing.
 * @param NAME The name of the new stack to create
 * @param ALLOC_F Function to alloc element when inserting it in a stack
 * @param FREE_F Function to free element when deleting it from a stack
 * @return the newly allocated stack in case of success.
 * @return NULL in case of insufficient memory.
 * @see gdsl_stack_free()
 * @see gdsl_stack_flush()
 */
extern gdsl_stack_t
gdsl_stack_alloc (const char* NAME,
		  gdsl_alloc_func_t ALLOC_F,
		  gdsl_free_func_t FREE_F
		  );

/**
 * @brief Destroy a stack.
 *
 * Deallocate all the elements of the stack S by calling S's FREE_F function 
 * passed to gdsl_stack_alloc(). The name of S is deallocated and S is 
 * deallocated itself too.
 * 
 * @note Complexity: O( |S| )
 * @pre S must be a valid gdsl_stack_t
 * @param S The stack to destroy
 * @see gdsl_stack_alloc()
 * @see gdsl_stack_flush()
 */
extern void 
gdsl_stack_free (gdsl_stack_t S
		 );

/**
 * @brief Flush a stack.
 *
 * Deallocate all the elements of the stack S by calling S's FREE_F function
 * passed to gdsl_stack_alloc(). S is not deallocated itself and S's name is
 * not modified.
 *
 * @note Complexity: O( |S| )
 * @pre S must be a valid gdsl_stack_t
 * @param S The stack to flush
 * @see gdsl_stack_alloc()
 * @see gdsl_stack_free()
 */
extern void
gdsl_stack_flush (gdsl_stack_t S
		  );

/******************************************************************************/
/* Consultation functions of stacks                                           */
/******************************************************************************/

/**
 * @brief Getsthe name of a stack.
 * @note Complexity: O( 1 )
 * @pre Q must be a valid gdsl_stack_t
 * @post The returned string MUST NOT be freed.
 * @param S The stack to get the name from
 * @return the name of the stack S.
 * @see gdsl_stack_set_name()
 */
extern const char*
gdsl_stack_get_name (const gdsl_stack_t S
		     );

/**
 * @brief Get the size of a stack.
 * @note Complexity: O( 1 )
 * @pre S must be a valid gdsl_stack_t
 * @param S The stack to get the size from
 * @return the number of elements of the stack S (noted |S|).
 */
extern ulong
gdsl_stack_get_size (const gdsl_stack_t S
		     );

/**
 * @brief Get the growing factor of a stack.
 *
 * Get the growing factor of the stack S. This value is the amount of cells to
 * reserve for next insertions. For example, if you set this value to 10, each
 * time the number of elements of S reaches 10, then 10 new cells will be
 * reserved for next 10 insertions. It is a way to save time for insertions.
 * This value is 1 by default and can be modified with 
 * gdsl_stack_set_growing_factor().
 *
 * @note Complexity: O( 1 )
 * @pre S must be a valid gdsl_stack_t
 * @param S The stack to get the growing factor from
 * @return the growing factor of the stack S.
 * @see gdsl_stack_insert()
 * @see gdsl_stack_set_growing_factor()
 */
extern ulong
gdsl_stack_get_growing_factor (const gdsl_stack_t S
			       );

/**
 * @brief Check if a stack is empty.
 * @note Complexity: O( 1 )
 * @pre S must be a valid gdsl_stack_t
 * @param S The stack to check
 * @return TRUE if the stack S is empty.
 * @return FALSE if the stack S is not empty.
 */
extern bool 
gdsl_stack_is_empty (const gdsl_stack_t S
		     );

/**
 * @brief Get the top of a stack.
 * @note Complexity: O( 1 )
 * @pre S must be a valid gdsl_stack_t
 * @param S The stack to get the top from
 * @return the element contained at the top position of the stack S if S is not
 * empty. The returned element is not removed from S.
 * @return NULL if the stack S is empty.
 * @see gdsl_stack_get_bottom()
 */
extern gdsl_element_t
gdsl_stack_get_top (const gdsl_stack_t S
		    );

/**
 * @brief Get the bottom of a stack.
 * @note Complexity: O( 1 )
 * @pre S must be a valid gdsl_stack_t
 * @param S The stack to get the bottom from
 * @return the element contained at the bottom position of the stack S if S is 
 * not empty. The returned element is not removed from S.
 * @return NULL if the stack S is empty.
 * @see gdsl_stack_get_top()
 */
extern gdsl_element_t
gdsl_stack_get_bottom (const gdsl_stack_t S
		       );

/******************************************************************************/
/* Modification functions of stacks                                           */
/******************************************************************************/

/**
 * @brief Set the name of a stack.
 *
 * Change the previous name of the stack S to a copy of NEW_NAME.
 *
 * @note Complexity: O( 1 )
 * @pre S must be a valid gdsl_stack_t
 * @param S The stack to change the name
 * @param NEW_NAME The new name of S
 * @return the modified stack in case of success.
 * @return NULL in case of insufficient memory.
 * @see gdsl_stack_get_name()
 */
extern gdsl_stack_t
gdsl_stack_set_name (gdsl_stack_t S,
		     const char* NEW_NAME
		     );

/**
 * @brief Set the growing factor of a stack.
 *
 * Set the growing factor of the stack S. This value is the amount of cells to
 * reserve for next insertions. For example, if you set this value to 10, each
 * time the number of elements of S reaches 10, then 10 new cells will be
 * reserved for next 10 insertions. It is a way to save time for insertions.
 * To know the actual value of the growing factor, 
 * use gdsl_stack_get_growing_factor()
 *
 * @note Complexity: O( 1 )
 * @pre S must be a valid gdsl_stack_t
 * @param S The stack to get the growing factor from
 * @param G The new growing factor of S.
 * @return the growing factor of the stack S.
 * @see gdsl_stack_insert()
 * @see gdsl_stack_get_growing_factor()
 */
extern void
gdsl_stack_set_growing_factor (gdsl_stack_t S,
			       ulong G
			       );

/**
 * @brief Insert an element in a stack (PUSH).
 *
 * Allocate a new element E by calling S's ALLOC_F function on VALUE. ALLOC_F
 * is the function pointer passed to gdsl_stack_alloc(). The new element E is
 * the inserted at the top position of the stack S. If the number of elements
 * in S reaches S's growing factor (G), then G new cells are reserved for
 * future insertions into S to save time.
 *
 * @note Complexity: O( 1 )
 * @pre S must be a valid gdsl_stack_t
 * @param S The stack to insert in
 * @param VALUE  The value used to make the new element to insert into S
 * @return the inserted element E in case of success.
 * @return NULL in case of insufficient memory.
 * @see gdsl_stack_set_growing_factor()
 * @see gdsl_stack_get_growing_factor()
 * @see gdsl_stack_remove()
 */
extern gdsl_element_t
gdsl_stack_insert (gdsl_stack_t S,
		   void* VALUE
		   );

/**
 * @brief Remove an element from a stack (POP).
 *
 * Remove the element at the top position of the stack S.
 *
 * @note Complexity: O( 1 )
 * @pre S must be a valid gdsl_stack_t
 * @param S The stack to remove the top from
 * @return the removed element in case of success.
 * @return NULL in case of S is empty.
 * @see gdsl_stack_insert()
 */
extern gdsl_element_t
gdsl_stack_remove (gdsl_stack_t S
		   );

/******************************************************************************/
/* Search functions of stacks                                                 */
/******************************************************************************/

/**
 * @brief Search for a particular element in a stack.
 *
 * Search for the first element E equal to VALUE in the stack S, by using COMP_F
 * to compare all S's element with.
 *
 * @note Complexity: O( |S| )
 * @pre S must be a valid gdsl_stack_t & COMP_F != NULL
 * @param S The stack to search the element in
 * @param COMP_F The comparison function used to compare S's element with VALUE
 * @param VALUE The value to compare S's elements with
 * @return the first founded element E in case of success.
 * @return NULL if no element is found.
 * @see gdsl_stack_search_by_position()
 */
extern gdsl_element_t
gdsl_stack_search (const gdsl_stack_t S,
		   gdsl_compare_func_t COMP_F,
		   void* VALUE
		   );

/**
 * @brief Search for an element by its position in a stack.
 * @note Complexity: O( 1 )
 * @pre S must be a valid gdsl_stack_t & POS > 0 & POS <= |S|
 * @param S The stack to search the element in
 * @param POS The position where is the element to search
 * @return the element at the POS-th position in the stack S.
 * @return NULL if POS > |L| or POS <= 0.
 * @see gdsl_stack_search()
 */
extern gdsl_element_t
gdsl_stack_search_by_position (const gdsl_stack_t S,
			       ulong POS
			       );

/******************************************************************************/
/* Parse functions of stacks                                                  */
/******************************************************************************/

/**
 * @brief Parse a stack from bottom to top.
 *
 * Parse all elements of the stack S from bottom to top. The MAP_F function is
 * called on each S's element with USER_DATA argument. If MAP_F returns 
 * GDSL_MAP_STOP, then gdsl_stack_map_forward() stops and returns its last 
 * examinated element.
 *
 * @note Complexity: O( |S| )
 * @pre S must be a valid gdsl_stack_t & MAP_F != NULL
 * @param S The stack to parse
 * @param MAP_F The map function to apply on each S's element
 * @param USER_DATA User's datas passed to MAP_F
 * Returns the first element for which MAP_F returns GDSL_MAP_STOP.
 * Returns NULL when the parsing is done.
 * @see gdsl_stack_map_backward()
 */
extern gdsl_element_t
gdsl_stack_map_forward (const gdsl_stack_t S,
			gdsl_map_func_t MAP_F,
			void* USER_DATA
			);

/**
 * @brief Parse a stack from top to bottom.
 *
 * Parse all elements of the stack S from top to bottom. The MAP_F function is
 * called on each S's element with USER_DATA argument. If MAP_F returns
 * GDSL_MAP_STOP, then gdsl_stack_map_backward() stops and returns its last
 * examinated element.
 *
 * @note Complexity: O( |S| )
 * @pre S must be a valid gdsl_stack_t & MAP_F != NULL
 * @param S The stack to parse
 * @param MAP_F The map function to apply on each S's element
 * @param USER_DATA User's datas passed to MAP_F
 * @return the first element for which MAP_F returns GDSL_MAP_STOP.
 * @return NULL when the parsing is done.
 * @see gdsl_stack_map_forward()
 */
extern gdsl_element_t
gdsl_stack_map_backward (const gdsl_stack_t S,
			 gdsl_map_func_t MAP_F,
			 void* USER_DATA
			 );

/******************************************************************************/
/* Input/output functions of stacks                                           */ 
/******************************************************************************/

/**
 * @brief Write all the elements of a stack to a file.
 *
 * Write the elements of the stack S to OUTPUT_FILE, using WRITE_F function.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |S| )
 * @pre S must be a valid gdsl_stack_t & OUTPUT_FILE != NULL & WRITE_F != NULL
 * @param S The stack to write.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write S's elements.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see gdsl_stack_write_xml()
 * @see gdsl_stack_dump()
 */
extern void
gdsl_stack_write (const gdsl_stack_t S,
		  gdsl_write_func_t WRITE_F,
		  FILE* OUTPUT_FILE,
		  void* USER_DATA
		  );

/**
 * @brief Write the content of a stack to a file into XML.
 *
 * Write the elements of the stack S to OUTPUT_FILE, into XML language.
 * If WRITE_F != NULL, then uses WRITE_F to write S's elements to OUTPUT_FILE.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |S| )
 * @pre S must be a valid gdsl_stack_t & OUTPUT_FILE != NULL
 * @param S The stack to write.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write S's elements.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see gdsl_stack_write()
 * @see gdsl_stack_dump()
 */
extern void
gdsl_stack_write_xml (gdsl_stack_t S,
		      gdsl_write_func_t WRITE_F,
		      FILE* OUTPUT_FILE,
		      void* USER_DATA
		      );

/**
 * @brief Dump the internal structure of a stack to a file.
 *
 * Dump the structure of the stack S to OUTPUT_FILE. If WRITE_F != NULL, then 
 * uses WRITE_F to write S's elements to OUTPUT_FILE.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |S| )
 * @pre S must be a valid gdsl_stack_t & OUTPUT_FILE != NULL
 * @param S The stack to write.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write S's elements.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see gdsl_stack_write()
 * @see gdsl_stack_write_xml()
 */
extern void 
gdsl_stack_dump (gdsl_stack_t S,
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


#endif /* _GDSL_STACK_H_ */


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
