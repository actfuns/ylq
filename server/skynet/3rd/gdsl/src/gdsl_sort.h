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
 * $RCSfile: gdsl_sort.h,v $
 * $Revision: 1.7 $
 * $Date: 2006/03/04 16:32:05 $
 */


#ifndef _GDSL_SORT_H_
#define _GDSL_SORT_H_


#if defined (__cplusplus)
extern "C" 
{
#endif /* __cplusplus */


/**
 * @defgroup gdsl_sort Sort module
 * @{
 */

/**
 * @brief Sort an array in place.
 *
 * Sort the array T in place. The function COMP_F is used to compare T's 
 * elements and must be user-defined.
 *
 * @note Complexity: O( N log( N ) )
 * @pre N == |T| & T != NULL & COMP_F != NULL 
 *      & for all i <= N: sizeof (T[i]) == sizeof (gdsl_element_t)
 * @param T The array of elements to sort
 * @param N The number of elements into T
 * @param COMP_F The function pointer used to compare T's elements
 */

extern void
gdsl_sort (gdsl_element_t* T,
	   ulong N,
	   const gdsl_compare_func_t COMP_F
	   );

/*
 * @}
 */


#ifdef __cplusplus
}
#endif/* __cplusplus */


#endif /* _GDSL_SORT_H_ */


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
