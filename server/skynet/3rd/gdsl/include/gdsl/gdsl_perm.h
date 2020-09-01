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
 * $RCSfile: gdsl_perm.h,v $
 * $Revision: 1.22 $
 * $Date: 2007/01/08 13:59:23 $
 */


#ifndef _GDSL_PERM_H_
#define _GDSL_PERM_H_


#include "gdsl_types.h"


#ifdef __cplusplus
extern "C" 
{
#endif /* __cplusplus */


/**
 * @defgroup gdsl_perm Permutation manipulation module
 * @{
 */

/**
 * @brief GDSL permutation type.
 *
 * This type is voluntary opaque. Variables of this kind could'nt be directly
 * used, but by the functions of this module.
 */
typedef struct gdsl_perm* gdsl_perm_t;

/**
 * @brief This type is for gdsl_perm_write_func_t.
 */
typedef enum
{
    /** When element is at first position */
    GDSL_PERM_POSITION_FIRST = 1,

    /** When element is at last position */
    GDSL_PERM_POSITION_LAST = 2

} gdsl_perm_position_t;

/**
 * @brief GDSL permutation write function type.
 * @param E The permutation element to write
 * @param OUTPUT_FILE The file where to write E
 * @param POSITION is an or-ed combination of gdsl_perm_position_t values to
 * indicate where E is located into the gdsl_perm_t mapped.
 * @param USER_DATA User's datas
 */
typedef void (* gdsl_perm_write_func_t) 
    (ulong E,
     FILE* OUTPUT_FILE,
     gdsl_location_t POSITION,
     void* USER_DATA
     );

typedef struct gdsl_perm_data* gdsl_perm_data_t;

/******************************************************************************/
/* Management functions of permutations                                       */
/******************************************************************************/

/**
 * @brief Create a new permutation.
 *
 * Allocate a new permutation data structure of size N wich name is set to a 
 * copy of NAME. 
 *
 * @note Complexity: O( N )
 * @pre N > 0
 * @param N The number of elements of the permutation to create.
 * @param NAME The name of the new permutation to create
 * @return the newly allocated identity permutation in its linear form in case 
 * of success.
 * @return NULL in case of insufficient memory.
 * @see gdsl_perm_free()
 * @see gdsl_perm_copy()
 */
extern gdsl_perm_t
gdsl_perm_alloc (const char* NAME,
		 const ulong N
		 );

/**
 * @brief Destroy a permutation.
 * 
 * Deallocate the permutation P.
 *
 * @note Complexity: O( |P| )
 * @pre P must be a valid gdsl_perm_t
 * @param P The permutation to destroy
 * @see gdsl_perm_alloc()
 * @see gdsl_perm_copy()
 */
extern void
gdsl_perm_free (gdsl_perm_t P
		);

/**
 * @brief Copy a permutation.
 *
 * Create and return a copy of the permutation P.
 *
 * @note Complexity: O( |P| )
 * @pre P must be a valid gdsl_perm_t.
 * @post The returned permutation must be deallocated with gdsl_perm_free.
 * @param P The permutation to copy.
 * @return a copy of P in case of success.
 * @return NULL in case of insufficient memory.
 * @see gdsl_perm_alloc
 * @see gdsl_perm_free
 */
extern gdsl_perm_t
gdsl_perm_copy (const gdsl_perm_t P
		);

/******************************************************************************/
/* Consultation functions of permutations                                     */
/******************************************************************************/

/**
 * @brief Get the name of a permutation.
 * @note Complexity: O( 1 )
 * @pre P must be a valid gdsl_perm_t
 * @post The returned string MUST NOT be freed.
 * @param P The permutation to get the name from
 * @return the name of the permutation P.
 * @see gdsl_perm_set_name()
 */
extern const char*
gdsl_perm_get_name (const gdsl_perm_t P
		    );

/**
 * @brief Get the size of a permutation.
 * @note Complexity: O( 1 )
 * @pre P must be a valid gdsl_perm_t
 * @param P The permutation to get the size from.
 * @return the number of elements of P (noted |P|).
 * @see gdsl_perm_get_element()
 * @see gdsl_perm_get_elements_array()
 */
extern ulong
gdsl_perm_get_size (const gdsl_perm_t P
		    );

/**
 * @brief Get the (INDIX+1)-th element from a permutation.
 * @note Complexity: O( 1 )
 * @pre P must be a valid gdsl_perm_t & <= 0 INDIX < |P|
 * @param P The permutation to use.
 * @param INDIX The indix of the value to get.
 * @return the value at the INDIX-th position in the permutation P.
 * @see gdsl_perm_get_size()
 * @see gdsl_perm_get_elements_array()
 */
extern ulong
gdsl_perm_get_element (const gdsl_perm_t P,
		       const ulong INDIX
		       );

/**
 * @brief Get the array elements of a permutation.
 * @note Complexity: O( 1 )
 * @pre P must be a valid gdsl_perm_t
 * @param P The permutation to get datas from.
 * @return the values array of the permutation P.
 * @see gdsl_perm_get_element()
 * @see gdsl_perm_set_elements_array()
 */
extern ulong*
gdsl_perm_get_elements_array (const gdsl_perm_t P
			      );

/**
 * @brief Count the inversions number into a linear permutation.
 * @note Complexity: O( |P| )
 * @pre P must be a valid linear gdsl_perm_t
 * @param P The linear permutation to use.
 * @return the number of inversions into the linear permutation P.
 */
extern ulong
gdsl_perm_linear_inversions_count (const gdsl_perm_t P
				   );

/**
 * @brief Count the cycles number into a linear permutation.
 * @note Complexity: O( |P| )
 * @pre P must be a valid linear gdsl_perm_t
 * @param P The linear permutation to use.
 * @return the number of cycles into the linear permutation P.
 * @see gdsl_perm_canonical_cycles_count()
 */
extern ulong
gdsl_perm_linear_cycles_count (const gdsl_perm_t P
			       );

/**
 * @brief Count the cycles number into a canonical permutation.
 * @note Complexity: O( |P| )
 * @pre P must be a valid canonical gdsl_perm_t
 * @param P The canonical permutation to use.
 * @return the number of cycles into the canonical permutation P.
 * @see gdsl_perm_linear_cycles_count()
 */
extern ulong
gdsl_perm_canonical_cycles_count (const gdsl_perm_t P
				  );

/******************************************************************************/
/* Modification functions of permutations                                     */
/******************************************************************************/

/**
 * @brief Set the name of a permutation.
 *
 * Change the previous name of the permutation P to a copy of NEW_NAME.
 *
 * @note Complexity: O( 1 )
 * @pre P must be a valid gdsl_perm_t
 * @param P The permutation to change the name
 * @param NEW_NAME The new name of P
 * @return the modified permutation in case of success.
 * @return NULL in case of insufficient memory.
 * @see gdsl_perm_get_name()
 */
extern gdsl_perm_t
gdsl_perm_set_name (gdsl_perm_t P,
		    const char* NEW_NAME
		    );

/** 
 * @brief Get the next permutation from a linear permutation.
 *
 * The permutation P is modified to become the next permutation after P.
 *
 * @note Complexity: O( |P| )
 * @pre P must be a valid linear gdsl_perm_t & |P| > 1
 * @param P The linear permutation to modify
 * @return the next permutation after the permutation P.
 * @return NULL if P is already the last permutation.
 * @see gdsl_perm_linear_prev()
 */
extern gdsl_perm_t
gdsl_perm_linear_next (gdsl_perm_t P
		       );

/**
 * @brief Get the previous permutation from a linear permutation.
 *
 * The permutation P is modified to become the previous permutation before P.
 *
 * @note Complexity: O( |P| )
 * @pre P must be a valid linear gdsl_perm_t & |P| >= 2
 * @param P The linear permutation to modify
 * @return the previous permutation before the permutation P.
 * @return NULL if P is already the first permutation.
 * @see gdsl_perm_linear_next()
 */
extern gdsl_perm_t
gdsl_perm_linear_prev (gdsl_perm_t P
		       );

/**
 * @brief Initialize a permutation with an array of values.
 *
 * Initialize the permutation P with the values contained in the array of 
 * values ARRAY. If ARRAY does not design a permutation, then P is left 
 * unchanged.
 *
 * @note Complexity: O( |P| )
 * @pre P must be a valid gdsl_perm_t & V != NULL & |V| == |P|
 * @param P The permutation to initialize
 * @param ARRAY The array of values to initialize P
 * @return the modified permutation in case of success.
 * @return NULL in case V does not design a valid permutation.
 * @see gdsl_perm_get_elements_array()
 */
extern gdsl_perm_t
gdsl_perm_set_elements_array (gdsl_perm_t P,
			      const ulong* ARRAY
			      );

/******************************************************************************/
/* Operations functions of permutations                                       */
/******************************************************************************/

/**
 * @brief Multiply two permutations.
 *
 * Compute the product of the permutations ALPHA x BETA and puts the result in
 * RESULT without modifying ALPHA and BETA.
 *
 * @note Complexity: O( |RESULT| )
 * @pre RESULT, ALPHA and BETA must be valids gdsl_perm_t
 *      & |RESULT| == |ALPHA| == |BETA| 
 * @param RESULT The result of the product ALPHA x BETA
 * @param ALPHA The first permutation used in the product
 * @param BETA The second permutation used in the product
 * @return RESULT, the result of the multiplication ALPHA x BETA.
 */
extern gdsl_perm_t
gdsl_perm_multiply (gdsl_perm_t RESULT,
		    const gdsl_perm_t ALPHA,
		    const gdsl_perm_t BETA
		    );
  
/**
 * @brief Convert a linear permutation to its canonical form.
 *
 * Convert the linear permutation P to its canonical form. The resulted 
 * canonical permutation is placed into Q without modifying P.
 *
 * @note Complexity: O( |P| )
 * @pre P & Q must be valids gdsl_perm_t & |P| == |Q| & P != Q
 * @param Q The canonical form of P
 * @param P The linear permutation used to compute its canonical form into Q
 * @return the canonical form Q of the permutation P.
 * @see gdsl_perm_canonical_to_linear()
 */
extern gdsl_perm_t
gdsl_perm_linear_to_canonical (gdsl_perm_t Q,
			       const gdsl_perm_t P
			       );

/**
 * @brief Convert a canonical permutation to its linear form.
 *
 * Convert the canonical permutation P to its linear form. The resulted linear
 * permutation is placed into Q without modifying P.
 *
 * @note Complexity: O( |P| )
 * @pre P & Q must be valids gdsl_perm_t & |P| == |Q| & P != Q
 * @param Q The linear form of P
 * @param P The canonical permutation used to compute its linear form into Q
 * @return the linear form Q of the permutation P.
 * @see gdsl_perm_linear_to_canonical()
 */
extern gdsl_perm_t
gdsl_perm_canonical_to_linear (gdsl_perm_t Q,
			       const gdsl_perm_t P
			       );

/**
 * @brief Inverse in place a permutation.
 * @note Complexity: O( |P| )
 * @pre P must be a valid gdsl_perm_t
 * @param P The permutation to invert
 * @return the inverse permutation of P in case of success.
 * @return NULL in case of insufficient memory.
 * @see gdsl_perm_reverse()
 */
extern gdsl_perm_t
gdsl_perm_inverse (gdsl_perm_t P
		   );

/**
 * @brief Reverse in place a permutation.
 * @note Complexity: O( |P| / 2 )
 * @pre P must be a valid gdsl_perm_t
 * @param P The permutation to reverse
 * @return the mirror image of the permutation P
 * @see gdsl_perm_inverse()
 */
extern gdsl_perm_t
gdsl_perm_reverse (gdsl_perm_t P
		   );

/**
 * @brief Randomize a permutation.
 *
 * The permutation P is randomized in an efficient way, using inversions array.
 *
 * @note Complexity: O( |P| )
 * @pre P must be a valid gdsl_perm_t
 * @param P The permutation to randomize
 * @return the mirror image ~P of the permutation of P in case of success.
 * @return NULL in case of insufficient memory.
 */
extern gdsl_perm_t
gdsl_perm_randomize (gdsl_perm_t P
		     );

/**
 * @brief Apply a permutation on to a vector.
 * @note Complexity: O( |P| )
 * @pre P must be a valid gdsl_perm_t & |P| == |V|
 * @param V The vector/array to reorder according to P
 * @param P The permutation to use to reorder V
 * @return the reordered array V according to the permutation P in case of 
 * success.
 * @return NULL in case of insufficient memory.
 */
extern gdsl_element_t*
gdsl_perm_apply_on_array (gdsl_element_t* V,
			  const gdsl_perm_t P
			  );

/******************************************************************************/
/* Input/output functions of permutations                                     */
/******************************************************************************/

/**
 * @brief Write the elements of a permutation to a file.
 *
 * Write the elements of the permuation P to OUTPUT_FILE, using 
 * WRITE_F function.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |P| )
 * @pre P must be a valid gdsl_perm_t & WRITE_F != NULL & OUTPUT_FILE != NULL
 * @param P The permutation to write.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write P's elements.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see gdsl_perm_write_xml()
 * @see gdsl_perm_dump()
 */
extern void
gdsl_perm_write (const gdsl_perm_t P,
		 const gdsl_write_func_t WRITE_F,
		 FILE* OUTPUT_FILE,
		 void* USER_DATA
		 );

/**
 * @brief Write the elements of a permutation to a file into XML.
 *
 * Write the elements of the permutation P to OUTPUT_FILE, into XML
 * language.
 * If WRITE_F != NULL, then uses WRITE_F function to write P's elements to
 * OUTPUT_FILE.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |P| )
 * @pre P must be a valid gdsl_perm_t & OUTPUT_FILE != NULL
 * @param P The permutation to write.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write P's elements.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see gdsl_perm_write()
 * @see gdsl_perm_dump()
 */
extern void
gdsl_perm_write_xml (const gdsl_perm_t P,
		     const gdsl_write_func_t WRITE_F,
		     FILE* OUTPUT_FILE,
		     void* USER_DATA
		     );

/**
 * @brief Dump the internal structure of a permutation to a file.
 *
 * Dump the structure of the permutation P to OUTPUT_FILE. 
 * If WRITE_F != NULL, then uses WRITE_F function to write P's elements to
 * OUTPUT_FILE.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( |P| )
 * @pre P must be a valid gdsl_perm_t & OUTPUT_FILE != NULL
 * @param P The permutation to dump.
 * @param WRITE_F The write function.
 * @param OUTPUT_FILE The file where to write P's elements.
 * @param USER_DATA User's datas passed to WRITE_F.
 * @see gdsl_perm_write()
 * @see gdsl_perm_write_xml()
 */
extern void
gdsl_perm_dump (const gdsl_perm_t P,
		const gdsl_write_func_t WRITE_F,
		FILE* OUTPUT_FILE,
		void* USER_DATA
		);

/*
 * @}
 */


#ifdef __cplusplus
}
#endif /* __cplusplus */


#endif /* _GDSL_PERM_H_ */


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
