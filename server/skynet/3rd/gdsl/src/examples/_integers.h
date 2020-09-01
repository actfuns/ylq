/*
 * This file is part of Generic Data Structures Library (GDSL).
 * Copyright (C) 1998-2006 Nicolas Darnis <ndarnis@free.fr>
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
 * 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA.
 *
 * $RCSfile: _integers.h,v $
 * $Revision: 1.10 $
 * $Date: 2006/03/04 16:32:05 $
 */


#ifndef __MY_INTEGERS_H_
#define __MY_INTEGERS_H_


#include "gdsl_types.h"


extern gdsl_element_t 
alloc_integer (void* integer);

extern void 
free_integer (gdsl_element_t e);

extern void
print_integer (gdsl_element_t e, FILE* file, gdsl_location_t location, void* d);

extern long int
compare_integers (gdsl_element_t e1, void* e2);


#endif /* __MY_INTEGERS_H_ */


/** EMACS **
 * Local variables:
 * mode: c
 * c-basic-offset: 4
 * End:
 */
