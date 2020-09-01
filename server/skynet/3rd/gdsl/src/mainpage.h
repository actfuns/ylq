/** @mainpage gdsl
 *
 * @section intro Introduction
 *
 * This is the %gdsl (Release 1.8) documentation.
 *
 * @section about About
 *
 *  The Generic Data Structures Library (GDSL) is a collection of routines for
 *  generic data structures manipulation. It is a portable and re-entrant 
 *  library fully written from scratch in pure ANSI C. It is designed to offer
 *  for C programmers common data structures with powerful algorithms, and 
 *  hidden implementation. Available structures are lists, queues, stacks, hash
 *  tables, binary trees, binary search trees, red-black trees, 2D arrays,
 *  permutations, heaps and interval heaps.
 *
 * @subsection authors Authors
 *
 *  Nicolas Darnis <ndarnis@free.fr>: all GDSL modules excepted the ones listed below. <BR>
 *
 *  Peter Kerpedjiev <pkerpedjiev@gmail.com>: interval_heap module. <BR>
 *
 *
 * @subsection cdp Project Manager
 * 
 * Nicolas Darnis <ndarnis@free.fr>. <BR>
 *
 *
 * @section thanks Thanks
 *
 *
  This is the list of persons (in randomized order) the GDSL Team 
  want to thanks for their direct and/or indirect help:

  - Vincent Vidal <vidal@cril.univ-artois.fr>

    For his bug report in hash_insert method and into gdsl.h.

  - Martin Pichlmair <pi@igw.tuwien.ac.at>

    For his patch to compile GDSL under OSX.
  
  - Mathieu Clabaut <mathieu.clabaut@gmail.com>

    For his bug report in gdsl_stack_insert().

  - Xavier De Labouret <Xavier.de_Labouret@cvf.fr>

    For his bug report in gdsl_hash_search().

  - Kaz Kylheku <kaz@ashi.footprints.net>

    For his KazLib from wich the deletion algorithm for gdsl_rbtree.c
    is inspired.

  - David Lewin <dlewin@free.fr>

    For his bug report in gdsl_list_map_backward(), and for the problem
    of redefining bool type in gdsl_types.h.

  - Torsten Luettgert <t.luettgert@combox.de>

    For his gdsl.spec file to build GDSL's RPM package.

  - Charles F. Randall <cfriv@yahoo.com>

    For his patch to compile GDSL under FreeBSD.

  - Sascha Alexander Jopen <jopen@informatik.uni-bonn.de>

    For his patch to compile GDSL under Android OS.

  - Peter Kerpedjiev <pkerpedjiev@gmail.com>

    For his gdsl_interval_heap module.


                                                                  The GDSL Team.
 */
