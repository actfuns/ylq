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
 * $RCSfile: gdsl_2darray.h,v $
 * $Revision: 1.17 $
 * $Date: 2006/03/04 16:32:05 $
 */


#ifndef _GDSL_2DARRAY_H_
#define _GDSL_2DARRAY_H_


#include <stdio.h>


#include "gdsl_types.h"


#ifdef __cplusplus
extern "C" 
{
#endif /* __cplusplus */


/**
 * @defgroup gdsl_2darray 2D-Arrays manipulation module
 * @{
 */

/**
 * @brief GDSL 2D-array type.
 *
 * This type is voluntary opaque. Variables of this kind could'nt be directly
 * used, but by the functions of this module.
 */
typedef struct gdsl_2darray* gdsl_2darray_t;

/******************************************************************************/
/* Management functions of 2D-arrays                                          */
/******************************************************************************/

/**
 * @brief Create a new 2D-array. 
 *
 * Allocate a new 2D-array data structure with R rows and C columns and its
 * name is set to a copy of NAME.
 * The functions pointers ALLOC_F and FREE_F could be used to respectively, 
 * alloc and free elements in the 2D-array. These pointers could be set to NULL
 * to use the default ones:
 * - the default ALLOC_F simply returns its argument
 * - the default FREE_F does nothing
 * 
 * @note Complexity: O( 1 )
 * @pre nothing
 * @param NAME The name of the new 2D-array to create
 * @param R The number of rows of the new 2D-array to create
 * @param C The number of columns of the new 2D-array to create
 * @param ALLOC_F Function to alloc element when inserting it in a 2D-array
 * @param FREE_F Function to free element when removing it from a 2D-array
 * @return the newly allocated 2D-array in case of success.
 * @return NULL in case of insufficient memory.
 * @see gdsl_2darray_free()
 * @see gdsl_alloc_func_t
 * @see gdsl_free_func_t
 */
extern gdsl_2darray_t
gdsl_2darray_alloc (const char* NAME,
		    const ulong R,
		    const ulong C,
		    const gdsl_alloc_func_t ALLOC_F,
		    const gdsl_free_func_t FREE_F
		    );

/**
 * @brief Destroy a 2D-array.
 *
 * Flush and destroy the 2D-array A. 
 * The FREE_F function passed to gdsl_2darray_alloc() is used to free elements
 * from A, but no check is done to see if an element was set (ie. != NULL) or 
 * not.It's up to you to check if the element to free is NULL or not into the 
 * FREE_F function.
 * 
 * @note Complexity: O( R x C ), where R is A's rows count, and C is A's columns
 *                   count
 * @pre A must be a valid gdsl_2darray_t
 * @param A The 2D-array to destroy
 * @see gdsl_2darray_alloc()
 */
extern void 
gdsl_2darray_free (gdsl_2darray_t A
		   );

/******************************************************************************/
/* Consultation functions of 2D-arrays                                        */
/******************************************************************************/

/**
 * @brief Get the name of a 2D-array.
 * @note Complexity: O( 1 )
 * @pre A must be a valid gdsl_2darray_t
 * @post The returned string MUST NOT be freed.
 * @param A The 2D-array from which getting the name
 * @return the name of the 2D-array A.
 * @see gdsl_2darray_set_name()
 */
extern const char*
gdsl_2darray_get_name (const gdsl_2darray_t A
		       );

/**
 * @brief Get the number of rows of a 2D-array.
 * @note Complexity: O( 1 )
 * @pre A must be a valid gdsl_2darray_t
 * @param A The 2D-array from which getting the rows count
 * @return the number of rows of the 2D-array A.
 * @see gdsl_2darray_get_columns_number()
 * @see gdsl_2darray_get_size()
 */
extern ulong
gdsl_2darray_get_rows_number (const gdsl_2darray_t A
			      );

/**
 * @brief Get the number of columns of a 2D-array.
 * @note Complexity: O( 1 )
 * @pre A must be a valid gdsl_2darray_t
 * @param A The 2D-array from which getting the columns count
 * @return the number of columns of the 2D-array A.
 * @see gdsl_2darray_get_rows_number()
 * @see gdsl_2darray_get_size()
 */
extern ulong
gdsl_2darray_get_columns_number (const gdsl_2darray_t A
				 );

/**
 * @brief Get the size of a 2D-array.
 * @note Complexity: O( 1 )
 * @pre A must be a valid gdsl_2darray_t
 * @param A The 2D-array to use.
 * @return the number of elements of A (noted |A|).
 * @see gdsl_2darray_get_rows_number()
 * @see gdsl_2darray_get_columns_number()
 */
extern ulong
gdsl_2darray_get_size (const gdsl_2darray_t A
		       );

/**
 * @brief Get an element from a 2D-array.
 * @note Complexity: O( 1 )
 * @pre A must be a valid gdsl_2darray_t
 *      & R <= gdsl_2darray_get_rows_number( A )
 *      & C <= gdsl_2darray_get_columns_number( A )
 * @param A The 2D-array from which getting the element
 * @param R The row indix of the element to get
 * @param C The column indix of the element to get
 * @return the element of the 2D-array A contained in row R and column C.
 * @see gdsl_2darray_set_content()
 */
extern gdsl_element_t
gdsl_2darray_get_content (const gdsl_2darray_t A,
			  const ulong R,
			  const ulong C
			  );

/******************************************************************************/
/* Modification functions of 2D-arrays                                        */
/******************************************************************************/

/**
 * @brief Set the name of a 2D-array.
 *
 * Change the previous name of the 2D-array A to a copy of NEW_NAME.
 *
 * @note Complexity: O( 1 )
 * @pre A must be a valid gdsl_2darray_t
 * @param A The 2D-array to change the name
 * @param NEW_NAME The new name of A
 * @return the modified 2D-array in case of success.
 * @return NULL in case of failure.
 * @see gdsl_2darray_get_name()
 */
extern gdsl_2darray_t
gdsl_2darray_set_name (gdsl_2darray_t A,
		       const char* NEW_NAME
		       );

/**
 * @brief Modify an element in a 2D-array.
 *
 * Change the element at row R and column C of the 2D-array A, and returns it.
 * The new element to insert is allocated using the ALLOC_F function passed to
 * gdsl_2darray_create() applied on VALUE. The previous element contained in row
 * R and in column C is NOT deallocated. It's up to you to do it before, if
 * necessary.
 * 
 * @note Complexity: O( 1 )
 * @pre A must be a valid gdsl_2darray_t
 *      & R <= gdsl_2darray_get_rows_number( A )
 *      & C <= gdsl_2darray_get_columns_number( A )
 * @param A The 2D-array to modify on element from
 * @param R The row number of the element to modify
 * @param C The column number of the element to modify
 * @param VALUE The user value to use for allocating the new element
 * @return the newly allocated element in case of success.
 * @return NULL in case of insufficient memory.
 * @see gdsl_2darray_get_content()
 */
extern gdsl_element_t
gdsl_2darray_set_content (gdsl_2darray_t A,
			  const ulong R,
			  const ulong C,
			  void* VALUE
			  );

/******************************************************************************/
/* Input/output functions of 2D-arrays                                        */
/******************************************************************************/

/**
 * @brief Write the content of a 2D-array to a file.
 *
 * Write the elements of the 2D-array A to OUTPUT_FILE, using WRITE_F function.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( R x C ), where R is A's rows count, and C is A's columns
 *                   count
 * @pre WRITE_F != NULL & OUTPUT_FILE != NULL
 * @param A The 2D-array to write
 * @param WRITE_F The write function
 * @param OUTPUT_FILE The file where to write A's elements
 * @param USER_DATA User's datas passed to WRITE_F
 * @see gdsl_2darray_write_xml()
 * @see gdsl_2darray_dump()
 */
extern void
gdsl_2darray_write (const gdsl_2darray_t A,
		    const gdsl_write_func_t WRITE_F,
		    FILE* OUTPUT_FILE,
		    void* USER_DATA
		    );

/**
 * @brief Write the content of a 2D array to a file into XML.
 *
 * Write all A's elements to OUTPUT_FILE, into XML language.
 * If WRITE_F != NULL, then uses WRITE_F to write A's elements to OUTPUT_FILE.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( R x C ), where R is A's rows count, and C is A's columns 
 *                   count
 * @pre A must be a valid gdsl_2darray_t & OUTPUT_FILE != NULL
 * @param A The 2D-array to write
 * @param WRITE_F The write function
 * @param OUTPUT_FILE The file where to write A's elements
 * @param USER_DATA User's datas passed to WRITE_F
 * @see gdsl_2darray_write()
 * @see gdsl_2darray_dump()
 */
extern void
gdsl_2darray_write_xml (const gdsl_2darray_t A,
			const gdsl_write_func_t WRITE_F,
			FILE* OUTPUT_FILE,
			void* USER_DATA
			);

/**
 * @brief Dump the internal structure of a 2D array to a file.
 *
 * Dump A's structure to OUTPUT_FILE. 
 * If WRITE_F != NULL, then uses WRITE_F to write A's elements to OUTPUT_FILE.
 * Additionnal USER_DATA argument could be passed to WRITE_F.
 *
 * @note Complexity: O( R x C ), where R is A's rows count, and C is A's columns 
 *                   count
 * @pre A must be a valid gdsl_2darray_t & OUTPUT_FILE != NULL
 * @param A The 2D-array to dump
 * @param WRITE_F The write function
 * @param OUTPUT_FILE The file where to write A's elements
 * @param USER_DATA User's datas passed to WRITE_F
 * @see gdsl_2darray_write()
 * @see gdsl_2darray_write_xml()
 */
extern void
gdsl_2darray_dump (const gdsl_2darray_t A,
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


#endif /* _GDSL_2DARRAY_H_ */


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
