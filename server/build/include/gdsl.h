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
 * $RCSfile: gdsl.h,v $
 * $Revision: 1.27 $
 * $Date: 2013/06/12 16:36:13 $
 */


#ifndef _GDSL_H_
#define _GDSL_H_

/*
 * This is the GDSL main header file.
 * Include it in your source code to be able to use all GDSL modules.
 * Alternatively, you can include only the GDSL headers you needs in your 
 * source files.
 */


#include "gdsl/gdsl_types.h"
#include "gdsl/gdsl_macros.h"


/* 
 * High-level modules: use them to get the easier access to data structures and
 * GDSL's algorithms.
 */
#include "gdsl/gdsl_list.h"            /* lists */
#include "gdsl/gdsl_stack.h"           /* stacks */
#include "gdsl/gdsl_queue.h"           /* queues */
#include "gdsl/gdsl_2darray.h"         /* 2D arrays */
#include "gdsl/gdsl_bstree.h"          /* binary search trees */
#include "gdsl/gdsl_perm.h"            /* permutations */
#include "gdsl/gdsl_rbtree.h"          /* red-black trees */
#include "gdsl/gdsl_hash.h"            /* hashtables */
#include "gdsl/gdsl_sort.h"            /* general-sorting functions */
#include "gdsl/gdsl_heap.h"            /* heaps */
#include "gdsl/gdsl_interval_heap.h"   /* interval heaps */


/* 
 * Low-level modules: use them to get a low-level access to data structures.
 */
#include "gdsl/_gdsl_list.h"           /* low-level lists */
#include "gdsl/_gdsl_bintree.h"        /* low-level binary trees */
#include "gdsl/_gdsl_bstree.h"         /* low-level binary search trees */


#if defined (__cplusplus)
extern "C" 
{
#endif /* __cplusplus */


/**
 * @defgroup gdsl Main module
 * @{
 */

/**
 * @brief Get GDSL version number as a string. 
 * @note Complexity: O( 1 )
 * @pre nothing.
 * @post the returned string MUST NOT be deallocated.
 * @return the GDSL version number as a string.
 */
extern const char*
gdsl_get_version (void);


/*
 * @}
 */


#ifdef __cplusplus
}
#endif/* __cplusplus */


#endif /* _GDSL_H_ */


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
