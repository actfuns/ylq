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
 * $RCSfile: gdsl_queue.h,v $
 * $Revision: 1.18 $
 * $Date: 2006/03/04 16:32:05 $
 */


#ifndef _GDSL_QUEUE_H_
#define _GDSL_QUEUE_H_


#include <stdio.h>


#include "gdsl_types.h"


#ifdef __cplusplus
extern "C" 
{
#endif /* __cplusplus */


/**
 * @defgroup gdsl_queue Queue manipulation module
 * @{
 */


/**
 * @brief GDSL queue type.
 *
 * This type is voluntary opaque. Variables of this kind could'nt be directly
 * used, but by the functions of this module.
 */
typedef struct _gdsl_queue* gdsl_queue_t;

/******************************************************************************/
/* Management functions of queues                                             */
/******************************************************************************/

/**
 * @brief Create a new queue.
 *
 * Allocate a new queue data structure which name is set to a copy of NAME.
 * The functions pointers ALLOC_F and FREE_F could be used to respectively, 
 * alloc and free elements in the queue. These pointers could be set to NULL to
 * use the default ones:
 * - the default ALLOC_F simply returns its argument
 * - the default FREE_F does nothing
 *
 * @note Complexity: O( 1 )
 * @pre nothing.
 * @param NAME The name of the new queue to create
 * @param ALLOC_F Function to alloc element when inserting it in a queue
 * @param FREE_F Function to free element when deleting it from a queue
 * @return the newly allocated queue in case of success.
 * @return NULL in case of insufficient memory.
 * @see gdsl_queue_free()
 * @see gdsl_queue_flush()
 */
extern gdsl_queue_t
gdsl_queue_alloc (const char* NAME,
		  gdsl_alloc_func_t ALLOC_F,
		  gdsl_free_func_t FREE_F
		  );

/**
 * @brief Destroy a queue.
 *
 * Deallocate all the elements of the queue Q by calling Q's FREE_F function 
 * passed to gdsl_queue_alloc(). The name of Q is deallocated and Q is 
 * deallocated itself too.
 *
 * @note Complexity: O( |Q| )
 * @pre Q must be a valid gdsl_queue_t
 * @param Q The queue to destroy
 * @see gdsl_queue_alloc()
 * @see gdsl_queue_flush()
 */
extern void 
gdsl_queue_free (gdsl_queue_t Q
		 );

/**
 * @brief Flush a queue.
 *
 * Deallocate all the elements of the queue Q by calling Q's FREE_F function
 * passed to gdsl_queue_allocc(). Q is not deallocated itself and Q's name is 
 * not modified.
 *
 * @note Complexity: O( |Q| )
 * @pre Q must be a valid gdsl_queue_t
 * @param Q The queue to flush
 * @see gdsl_queue_alloc()
 * @see gdsl_queue_free()
 */
extern void
gdsl_queue_flush (gdsl_queue_t Q
		  );

/******************************************************************************/
/* Consultation functions of queues                                           */
/******************************************************************************/

/**
 * @brief Getsthe name of a queue.
 * @note Complexity: O( 1 )
 * @pre Q must be a valid gdsl_queue_t
 * @post The returned string MUST NOT be freed.
 * @param Q The queue to get the name from
 * @return the name of the queue Q.
 * @see gdsl_queue_set_name()
 */
extern const char*
gdsl_queue_get_name (const gdsl_queue_t Q
		     );

/**
 * @brief Get the size of a queue.
 * @note Complexity: O( 1 )
 * @pre Q must be a valid gdsl_queue_t
 * @param Q The queue to get the size from
 * @return the number of elements of Q (noted |Q|).
 */
extern ulong
gdsl_queue_get_size (const gdsl_queue_t Q
		     );

/**
 * @brief Check if a queue is empty.
 * @note Complexity: O( 1 )
 * @pre Q must be a valid gdsl_queue_t
 * @param Q The queue to check
 * @return TRUE if the queue Q is empty.
 * @return FALSE if the queue Q is not empty.
 */
extern bool 
gdsl_queue_is_empty (const gdsl_queue_t Q
		     );

/**
 * @brief Get the head of a queue.
 * @note Complexity: O( 1 )
 * @pre Q must be a valid gdsl_queue_t
 * @param Q The queue to get the head from
 * @return the element contained at the header position of the queue Q if Q is
 * not empty. The returned element is not removed from Q.
 * @return NULL if the queue Q is empty.
 * @see gdsl_queue_get_tail()
 */
extern gdsl_element_t
gdsl_queue_get_head (const gdsl_queue_t Q
		     );

/**
 * @brief Get the tail of a queue.
 * @note Complexity: O( 1 )
 * @pre Q must be a valid gdsl_queue_t
 * @param Q The queue to get the tail from
 * @return the element contained at the footer position of the queue Q if Q is
 * not empty. The returned element is not removed from Q.
 * @return NULL if the queue Q is empty.
 * @see gdsl_queue_get_head()
 */
extern gdsl_element_t
gdsl_queue_get_tail (const gdsl_queue_t Q
		     );

/******************************************************************************/
/* Modification functions of queues                                           */
/******************************************************************************/

/**
 * @brief Set the name of a queue.
 *
 * Change the previous name of the queue Q to a copy of NEW_NAME.
 *
 * @note Complexity: O( 1 )
 * @pre Q must be a valid gdsl_queue_t
 * @param Q The queue to change the name
 * @param NEW_NAME The new name of Q
 * @return the modified queue in case of success.
 * @return NULL in case of insufficient memory.
 * @see gdsl_queue_get_name()
 */
extern gdsl_queue_t
gdsl_queue_set_name (gdsl_queue_t Q,
		     const char* NEW_NAME
		     );

/**
 * @brief Insert an element in a queue (PUT).
 *
 * Allocate a new element E by calling Q's ALLOC_F function on VALUE. ALLOC_F
 * is the function pointer passed to gdsl_queue_alloc(). The new element E is
 * then inserted at the header position of the queue Q.
 *
 * @note Complexity: O( 1 )
 * @pre Q must be a valid gdsl_queue_t
 * @param Q The queue to insert in
 * @param VALUE The value used to make the new element to insert into Q
 * @return the inserted element E in case of success.
 * @return NULL in case of insufficient memory.
 * @see gdsl_queue_remove()
 */
extern gdsl_element_t
gdsl_queue_insert (gdsl_queue_t Q,
		   void* VALUE
		   );

/**
 * @brief Remove an element from a queue (GET).
 *
 * Remove the element at the footer position of the queue Q.
 *
 * @note Complexity: O( 1 )
 * @pre Q must be a valid gdsl_queue_t
 * @param Q The queue to remove the tail from
 * @return the removed element in case of success.
 * @return NULL in case of Q is empty.
 * @see gdsl_queue_insert()
 */
extern gdsl_element_t
gdsl_queue_remove (gdsl_queue_t Q
		   );

/******************************************************************************/
/* Search functions of queues                                                 */
/******************************************************************************/

/**
 * @brief Search for a particular element in a queue.
 *
 * Search for the first element E equal to VALUE in the queue Q, by using 
 * COMP_F to compare all Q's element with.
 *
 * @note Complexity: O( |Q| / 2 )
 * @pre Q must be a valid gdsl_queue_t & COMP_F != NULL
 * @param Q The queue to search the element in
 * @param COMP_F The comparison function used to compare Q's element with VALUE
 * @param VALUE The value to compare Q's elements with
 * @return the first founded element E in case of success.
 * @return NULL in case the searched element E was not found.
 * @see gdsl_queue_search_by_position
 */
extern gdsl_element_t
gdsl_queue_search (const gdsl_queue_t Q,
		   gdsl_compare_func_t COMP_F,
		   void* VALUE
		   );

/**
 * @brief Search for an element by its position in a queue.
 * @note Complexity: O( |Q| / 2 )
 * @pre Q must be a valid gdsl_queue_t & POS > 0 & POS <= |Q|
 * @param Q The queue to search the element in
 * @param POS The position where is the element to search
 * @return the element at the POS-th position in the queue Q.
 * @return NULL if POS > |L| or POS <= 0.
 * @see gdsl_queue_search()
 */
extern gdsl_element_t
gdsl_queue_search_by_position (const gdsl_queue_t Q,
			       ulong POS
			       );

/******************************************************************************/
/* Parse functions of queues                                                  */
/******************************************************************************/

/**
 * @brief Parse a queue from head to tail.
 *
 * Parse all elements of the queue Q from head to tail. The MAP_F function is
 * called on each Q's element with USER_DATA argument. If MAP_F returns 
 * GDSL_MAP_STOP, then gdsl_queue_map_forward() stops and returns its last
 * examinated element.
 *
 * @note Complexity: O( |Q| )
 * @pre Q must be a valid gdsl_queue_t & MAP_F != NULL
 * @param Q The queue to parse
 * @param MAP_F The map function to apply on each Q's element
 * @param USER_DATA User's datas passed to MAP_F
 * @return the first element for which MAP_F returns GDSL_MAP_STOP.
 * @return NULL when the parsing is done.
 * @see gdsl_queue_map_backward()
 */
extern gdsl_element_t
gdsl_queue_map_forward (const gdsl_queue_t Q,
			gdsl_map_func_t MAP_F,
			void* USER_DATA
			);

/**
 * @brief Parse a queue from tail to head.
 *
 * Parse all elements of the queue Q from tail to head. The MAP_F function is
 * called on each Q's element with USER_DATA argument. If MAP_F returns 
 * GDSL_MAP_STOP, then gdsl_queue_map_backward() stops and returns its last 
 * examinated element.
 *
 * @note Complexity: O( |Q| )
 * @pre Q must be a valid gdsl_queue_t & MAP_F != NULL
 * @param Q The queue to parse
 * @param MAP_F The map function to apply on each Q's element
 * @param USER_DATA User's datas passed to MAP_F
 * Returns the first element for which MAP_F returns GDSL_MAP_STOP.
 * Returns NULL when the parsing is done.
 * @see gdsl_queue_map_forward()
 */
extern gdsl_element_t
gdsl_queue_map_backward (const gdsl_queue_t Q,
			 gdsl_map_func_t MAP_F,
			 void* USER_DATA
			 );

/******************************************************************************/
/* Input/output functions of queues                                           */
/******************************************************************************/

/**
 * @brief Write all the elements of a queue to a file.
 *
 * Write the elements of the queue Q to OUTPUT_FILE, using WRITE_F function.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |Q| )
 * @pre Q must be a valid gdsl_queue_t & OUTPUT_FILE != NULL & WRITE_F != NULL
 * @param Q The queue to write.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write Q's elements.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see gdsl_queue_write_xml()
 * @see gdsl_queue_dump()
 */
extern void
gdsl_queue_write (const gdsl_queue_t Q,
		  gdsl_write_func_t WRITE_F,
		  FILE* OUTPUT_FILE,
		  void* USER_DATA
		  );

/**
 * @brief Write the content of a queue to a file into XML.
 *
 * Write the elements of the queue Q to OUTPUT_FILE, into XML language.
 * If WRITE_F != NULL, then uses WRITE_F to write Q's elements to OUTPUT_FILE.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |Q| )
 * @pre Q must be a valid gdsl_queue_t & OUTPUT_FILE != NULL
 * @param Q The queue to write.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write Q's elements.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see gdsl_queue_write()
 * @see gdsl_queue_dump()
 */
extern void
gdsl_queue_write_xml (const gdsl_queue_t Q,
		      gdsl_write_func_t WRITE_F,
		      FILE* OUTPUT_FILE,
		      void* USER_DATA
		      );

/**
 * @brief Dump the internal structure of a queue to a file.
 *
 * Dump the structure of the queue Q to OUTPUT_FILE. If WRITE_F != NULL, then 
 * uses WRITE_F to write Q's elements to OUTPUT_FILE.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |Q| )
 * @pre Q must be a valid gdsl_queue_t & OUTPUT_FILE != NULL
 * @param Q The queue to write.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write Q's elements.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see gdsl_queue_write()
 * @see gdsl_queue_write_xml()
 */
extern void 
gdsl_queue_dump (const gdsl_queue_t Q,
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


#endif /* _GDSL_QUEUE_H_ */


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
