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
 * $RCSfile: gdsl_hash.h,v $
 * $Revision: 1.25 $
 * $Date: 2006/03/04 16:32:05 $
 */


#ifndef _GDSL_HASH_H_
#define _GDSL_HASH_H_


#include <stdio.h>


#include "gdsl_types.h"


#ifdef __cplusplus
extern "C" 
{
#endif /* __cplusplus */


/**
 * @defgroup gdsl_hash Hashtable manipulation module
 * @{
 */


/**
 * @brief GDSL hashtable type.
 *
 * This type is voluntary opaque. Variables of this kind could'nt be directly
 * used, but by the functions of this module.
 */
typedef struct hash_table* gdsl_hash_t;

/**
 * @brief GDSL hashtable key function type.
 * @post Returned value must be != "" && != NULL.
 * @param VALUE The value used to get the key from
 * @return The key associated to the VALUE.
 */
typedef const char* (*gdsl_key_func_t) (void* VALUE
					);

/**
 * @brief GDSL hashtable hash function type.
 * @param KEY the key used to compute the hash code.
 * @return The hashed value computed from KEY.
 */
typedef ulong (*gdsl_hash_func_t) (const char* KEY
				   );

/******************************************************************************/
/* Generic hash function                                                      */
/******************************************************************************/

/**
 * @brief Computes a hash value from a NULL terminated character string.
 *
 * This function computes a hash value from the NULL terminated KEY string.
 *
 * @note Complexity: O ( |key| )
 * @pre KEY must be NULL-terminated.
 * @param KEY The NULL terminated string to compute the key from
 * @return the hash code computed from KEY.
 */
extern ulong
gdsl_hash (const char* KEY
	   );

/******************************************************************************/
/* Management functions of hashtables                                         */
/******************************************************************************/

/**
 * @brief Create a new hashtable.
 *
 * Allocate a new hashtable data structure which name is set to a copy of NAME.
 * The new hashtable will contain initially INITIAL_ENTRIES_NB lists. This value
 * could be (only) increased with gdsl_hash_modify() function. Until this 
 * function is called, then all H's lists entries have no size limit.
 * The function pointers ALLOC_F and FREE_F could be used to respectively, alloc
 * and free elements in the hashtable. The KEY_F function must provide a unique 
 * key associated to its argument. The HASH_F function must compute a hash code
 * from its argument.
 * These pointers could be set to NULL to use the default ones:
 * - the default ALLOC_F simply returns its argument
 * - the default FREE_F does nothing
 * - the default KEY_F simply returns its argument
 * - the default HASH_F is gdsl_hash() above
 *
 * @note Complexity: O( 1 )
 * @pre nothing.
 * @param NAME The name of the new hashtable to create
 * @param ALLOC_F Function to alloc element when inserting it in the hashtable
 * @param FREE_F Function to free element when deleting it from the hashtable
 * @param KEY_F Function to get the key from an element
 * @param HASH_F Function used to compute the hash value.
 * @param INITIAL_ENTRIES_NB Initial number of entries of the hashtable
 * @return the newly allocated hashtable in case of success.
 * @return NULL in case of insufficient memory.
 * @see gdsl_hash_free()
 * @see gdsl_hash_flush()
 * @see gdsl_hash_insert()
 * @see gdsl_hash_modify()
 */
extern gdsl_hash_t
gdsl_hash_alloc (const char* NAME,
		 gdsl_alloc_func_t ALLOC_F,
		 gdsl_free_func_t FREE_F,
		 gdsl_key_func_t KEY_F,
		 gdsl_hash_func_t HASH_F,
		 ushort INITIAL_ENTRIES_NB
		 );

/**
 * @brief Destroy a hashtable.
 *
 * Deallocate all the elements of the hashtable H by calling H's FREE_F function
 * passed to gdsl_hash_alloc(). The name of H is deallocated and H is 
 * deallocated itself too.
 *
 * @note Complexity: O( |H| )
 * @pre H must be a valid gdsl_hash_t
 * @param H The hashtable to destroy
 * @see gdsl_hash_alloc()
 * @see gdsl_hash_flush()
 */
extern void
gdsl_hash_free (gdsl_hash_t H
		);

/**
 * @brief Flush a hashtable.
 *
 * Deallocate all the elements of the hashtable H by calling H's FREE_F function
 * passed to gdsl_hash_alloc(). H is not deallocated itself and H's name is not
 * modified.
 *
 * @note Complexity: O( |H| )
 * @pre H must be a valid gdsl_hash_t
 * @param H The hashtable to flush
 * @see gdsl_hash_alloc()
 * @see gdsl_hash_free()
 */
extern void
gdsl_hash_flush (gdsl_hash_t H
		 );

/******************************************************************************/
/* Consultation functions of hashtables                                       */
/******************************************************************************/

/**
 * @brief Get the name of a hashtable.
 * @note Complexity: O( 1 )
 * @pre H must be a valid gdsl_hash_t
 * @post The returned string MUST NOT be freed.
 * @param H The hashtable to get the name from
 * @return the name of the hashtable H.
 * @see gdsl_hash_set_name()
 */
extern const char*
gdsl_hash_get_name (const gdsl_hash_t H
		    );

/**
 * @brief Get the number of entries of a hashtable.
 * @note Complexity: O( 1 )
 * @pre H must be a valid gdsl_hash_t
 * @param H The hashtable to use.
 * @return the number of lists entries of the hashtable H.
 * @see gdsl_hash_get_size()
 * @see gdsl_hash_fill_factor()
 */
extern ushort
gdsl_hash_get_entries_number (const gdsl_hash_t H
			      );

/**
 * @brief Get the max number of elements allowed in each entry of a hashtable.
 * @note Complexity: O( 1 )
 * @pre H must be a valid gdsl_hash_t
 * @param H The hashtable to use.
 * @return 0 if no lists max size was set before (ie. no limit for H's entries).
 * @return the max number of elements for each entry of the hashtable H, if the
 * function gdsl_hash_modify() was used with a NEW_LISTS_MAX_SIZE greather than 
 * the actual one.
 * @see gdsl_hash_fill_factor()
 * @see gdsl_hash_get_entries_number()
 * @see gdsl_hash_get_longest_list_size()
 * @see gdsl_hash_modify()
 */
extern ushort
gdsl_hash_get_lists_max_size (const gdsl_hash_t H
			      );

/**
 * @brief Get the number of elements of the longest list entry of a hashtable.
 * @note Complexity: O( L ), where L = gdsl_hash_get_entries_number(H)
 * @pre H must be a valid gdsl_hash_t
 * @param H The hashtable to use.
 * @return the number of elements of the longest list entry of the hashtable H.
 * @see gdsl_hash_get_size()
 * @see gdsl_hash_fill_factor()
 * @see gdsl_hash_get_entries_number()
 * @see gdsl_hash_get_lists_max_size()
 */
extern ushort
gdsl_hash_get_longest_list_size (const gdsl_hash_t H
				 );

/**
 * @brief Get the size of a hashtable.
 * @note Complexity: O( L ), where L = gdsl_hash_get_entries_number(H)
 * @pre H must be a valid gdsl_hash_t
 * @param H The hashtable to get the size from
 * @return the number of elements of H (noted |H|).
 * @see gdsl_hash_get_entries_number()
 * @see gdsl_hash_fill_factor()
 * @see gdsl_hash_get_longest_list_size()
 */
extern ulong
gdsl_hash_get_size (const gdsl_hash_t H
		    );

/**
 * @brief Get the fill factor of a hashtable.
 * @note Complexity: O( L ), where L = gdsl_hash_get_entries_number(H)
 * @pre H must be a valid gdsl_hash_t
 * @param H The hashtable to use
 * @return The fill factor of H, computed as |H| / L
 * @see gdsl_hash_get_entries_number()
 * @see gdsl_hash_get_longest_list_size()
 * @see gdsl_hash_get_size()
 */
extern double
gdsl_hash_get_fill_factor (const gdsl_hash_t H
			   );

/******************************************************************************/
/* Modification functions of hashtables                                       */
/******************************************************************************/
  
/**
 * @brief Set the name of a hashtable.
 *
 * Change the previous name of the hashtable H to a copy of NEW_NAME.
 * 
 * @note Complexity: O( 1 )
 * @pre H must be a valid gdsl_hash_t
 * @param H The hashtable to change the name
 * @param NEW_NAME The new name of H
 * @return the modified hashtable in case of success.
 * @return NULL in case of insufficient memory.
 * @see gdsl_hash_get_name()
 */
extern gdsl_hash_t
gdsl_hash_set_name (gdsl_hash_t H,
		    const char* NEW_NAME
		    );

/**
 * @brief Insert an element into a hashtable (PUSH).
 *
 * Allocate a new element E by calling H's ALLOC_F function on VALUE. The key K
 * of the new element E is computed using KEY_F called on E. If the value of
 * gdsl_hash_get_lists_max_size(H) is not reached, or if it is equal to zero,
 * then the insertion is simple. Otherwise, H is re-organized as follow:
 * - its actual gdsl_hash_get_entries_number(H) (say N) is modified as N * 2 + 1
 * - its actual gdsl_hash_get_lists_max_size(H) (say M) is modified as M * 2
 * The element E is then inserted into H at the entry computed by HASH_F( K ) 
 * modulo gdsl_hash_get_entries_number(H). ALLOC_F, KEY_F and HASH_F are the 
 * function pointers passed to gdsl_hash_alloc(). 
 *
 * @note Complexity: O( 1 ) if gdsl_hash_get_lists_max_size(H) is not reached or
 * if it is equal to zero
 * @note Complexity: O ( gdsl_hash_modify (H) ) if 
 * gdsl_hash_get_lists_max_size(H) is reached, so H needs to grow
 * @pre H must be a valid gdsl_hash_t
 * @param H The hashtable to modify
 * @param VALUE The value used to make the new element to insert into H
 * @return the inserted element E in case of success.
 * @return NULL in case of insufficient memory.
 * @see gdsl_hash_alloc()
 * @see gdsl_hash_remove()
 * @see gdsl_hash_delete()
 * @see gdsl_hash_get_size()
 * @see gdsl_hash_get_entries_number()
 * @see gdsl_hash_modify()
 */
extern gdsl_element_t
gdsl_hash_insert (gdsl_hash_t H,
		  void* VALUE
		  );
  
/**
 * @brief Remove an element from a hashtable (POP).
 *
 * Search into the hashtable H for the first element E equal to KEY.
 * If E is found, it is removed from H and then returned. 
 *
 * @note Complexity: O( M ), where M is the average size of H's lists
 * @pre H must be a valid gdsl_hash_t
 * @param H The hashtable to modify
 * @param KEY The key used to find the element to remove
 * @return the first founded element equal to KEY in H in case is found.
 * @return NULL in case no element equal to KEY is found in H.
 * @see gdsl_hash_insert()
 * @see gdsl_hash_search()
 * @see gdsl_hash_delete()
 */
extern gdsl_element_t
gdsl_hash_remove (gdsl_hash_t H,
		  const char* KEY
		  );
/**
 * @brief Delete an element from a hashtable.
 *
 * Remove from he hashtable H the first founded element E equal to KEY.
 * If E is found, it is removed from H and E is deallocated using H's FREE_F
 * function passed to gdsl_hash_alloc(), then H is returned.
 *
 * @note Complexity: O( M ), where M is the average size of H's lists
 * @pre H must be a valid gdsl_hash_t
 * @param H The hashtable to modify
 * @param KEY The key used to find the element to remove
 * @return the modified hashtable after removal of E if E was found.
 * @return NULL if no element equal to KEY was found.
 * @see gdsl_hash_insert()
 * @see gdsl_hash_search()
 * @see gdsl_hash_remove()
 */
extern gdsl_hash_t
gdsl_hash_delete (gdsl_hash_t H,
		  const char* KEY
		  );

/**
 * @brief Increase the dimensions of a hashtable.
 *
 * The hashtable H is re-organized to have NEW_ENTRIES_NB lists entries. Each
 * entry is limited to NEW_LISTS_MAX_SIZE elements. After a call to this 
 * function, all insertions into H will make H automatically growing if needed.
 * The grow is needed each time an insertion makes an entry list to reach 
 * NEW_LISTS_MAX_SIZE elements. In this case, H will be reorganized 
 * automatically by gdsl_hash_insert().
 *
 * @note Complexity: O( |H| )
 * @pre H must be a valid gdsl_hash_t
 *      & NEW_ENTRIES_NB > gdsl_hash_get_entries_number(H)
 *      & NEW_LISTS_MAX_SIZE > gdsl_hash_get_lists_max_size(H)
 * @param H The hashtable to modify
 * @param NEW_ENTRIES_NB
 * @param NEW_LISTS_MAX_SIZE
 * @return the modified hashtable H in case of success
 * @return NULL in case of failure, 
 *         or in case NEW_ENTRIES_NB <= gdsl_hash_get_entries_number(H)
 *         or in case NEW_LISTS_MAX_SIZE <= gdsl_hash_get_lists_max_size(H)
 *         in these cases, H is not modified
 * @see gdsl_hash_insert()
 * @see gdsl_hash_get_entries_number()
 * @see gdsl_hash_get_fill_factor()
 * @see gdsl_hash_get_longest_list_size()
 * @see gdsl_hash_get_lists_max_size()
 */
extern gdsl_hash_t
gdsl_hash_modify (gdsl_hash_t H, 
		  ushort NEW_ENTRIES_NB, 
		  ushort NEW_LISTS_MAX_SIZE
		  );

/******************************************************************************/
/* Search functions of hashtables                                             */
/******************************************************************************/

/**
 * @brief Search for a particular element into a hashtable (GET).
 *
 * Search the first element E equal to KEY in the hashtable H.
 *
 * @note Complexity: O( M ), where M is the average size of H's lists
 * @pre H must be a valid gdsl_hash_t
 * @param H The hashtable to search the element in
 * @param KEY The key to compare H's elements with
 * @return the founded element E if it was found.
 * @return NULL in case the searched element E was not found.
 * @see gdsl_hash_insert()
 * @see gdsl_hash_remove()
 * @see gdsl_hash_delete()
 */
extern gdsl_element_t
gdsl_hash_search (const gdsl_hash_t H,
		  const char* KEY
		  );

/******************************************************************************/
/* Parse functions of hashtables                                              */
/******************************************************************************/

/**
 * @brief Parse a hashtable.
 *
 * Parse all elements of the hashtable H. The MAP_F function is called on each 
 * H's element with USER_DATA argument. If MAP_F returns GDSL_MAP_STOP then
 * gdsl_hash_map() stops and returns its last examinated element.
 *
 * @note Complexity: O( |H| )
 * @pre H must be a valid gdsl_hash_t & MAP_F != NULL
 * @param H The hashtable to map
 * @param MAP_F The map function.
 * @param USER_DATA User's datas passed to MAP_F
 * @return the first element for which MAP_F returns GDSL_MAP_STOP.
 * @return NULL when the parsing is done.
 */
extern gdsl_element_t
gdsl_hash_map (const gdsl_hash_t H,
	       gdsl_map_func_t MAP_F,
	       void* USER_DATA
	       );

/******************************************************************************/
/* Input/output functions of hashtables                                       */
/******************************************************************************/

/**
 * @brief Write all the elements of a hashtable to a file.
 *
 * Write the elements of the hashtable H to OUTPUT_FILE, using WRITE_F function.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |H| )
 * @pre H must be a valid gdsl_hash_t & OUTPUT_FILE != NULL & WRITE_F != NULL
 * @param H The hashtable to write.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write H's elements.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see gdsl_hash_write_xml()
 * @see gdsl_hash_dump()
 */
extern void
gdsl_hash_write (const gdsl_hash_t H,
		 gdsl_write_func_t WRITE_F,
		 FILE* OUTPUT_FILE,
		 void* USER_DATA
		 );

/**
 * @brief Write the content of a hashtable to a file into XML.
 *
 * Write the elements of the hashtable H to OUTPUT_FILE, into XML language.
 * If WRITE_F != NULL, then uses WRITE_F to write H's elements to OUTPUT_FILE.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |H| )
 * @pre H must be a valid gdsl_hash_t & OUTPUT_FILE != NULL
 * @param H The hashtable to write.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write H's elements.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see gdsl_hash_write()
 * @see gdsl_hash_dump()
 */
extern void
gdsl_hash_write_xml (const gdsl_hash_t H,
		     gdsl_write_func_t WRITE_F,
		     FILE* OUTPUT_FILE,
		     void* USER_DATA
		     );

/**
 * @brief Dump the internal structure of a hashtable to a file.
 *
 * Dump the structure of the hashtable H to OUTPUT_FILE. If WRITE_F != NULL,
 * then uses WRITE_F to write H's elements to OUTPUT_FILE.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |H| )
 * @pre H must be a valid gdsl_hash_t & OUTPUT_FILE != NULL
 * @param H The hashtable to write
 * @param WRITE_F The write function
 * @param OUTPUT_FILE The file where to write H's elements
 * @param USER_DATA User's datas passed to WRITE_F
 * @see gdsl_hash_write()
 * @see gdsl_hash_write_xml()
 */
extern void
gdsl_hash_dump (const gdsl_hash_t H,
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


#endif /* _GDSL_HASH_H_ */


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */

