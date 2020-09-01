## Process this file with automake to produce Makefile.in

SUBDIRS			= examples
CLEANFILES		= *~

lib_LTLIBRARIES		= libgdsl.la

include_HEADERS		= gdsl.h

pkginclude_HEADERS	= \
			_gdsl_node.h \
			_gdsl_list.h \
			_gdsl_bintree.h \
			_gdsl_bstree.h \
			gdsl_list.h \
			gdsl_queue.h \
			gdsl_stack.h \
			gdsl_2darray.h \
			gdsl_hash.h \
			gdsl_interval_heap.h \
			gdsl_heap.h \
			gdsl_bstree.h \
			gdsl_rbtree.h \
			gdsl_perm.h \
			gdsl_types.h  \
			gdsl_macros.h \
			gdsl_sort.h

libgdsl_la_SOURCES	= \
			_gdsl_node.c \
			_gdsl_node.h \
			_gdsl_list.c \
			_gdsl_list.h \
			_gdsl_bintree.c \
			_gdsl_bintree.h \
			_gdsl_bstree.c \
			_gdsl_bstree.h \
			gdsl_list.c \
			gdsl_list.h \
			gdsl_queue.c \
			gdsl_queue.h \
			gdsl_stack.c \
			gdsl_stack.h \
			gdsl_2darray.c \
			gdsl_2darray.h \
			gdsl_hash.c \
			gdsl_hash.h \
			gdsl_heap.c \
			gdsl_heap.h \
			gdsl_interval_heap.c \
			gdsl_interval_heap.h \
			gdsl_bstree.c \
			gdsl_bstree.h \
			gdsl_rbtree.c \
			gdsl_rbtree.h \
			gdsl_perm.c \
			gdsl_perm.h \
			gdsl_types.h \
			gdsl_macros.h \
			gdsl_sort.c \
			gdsl_sort.h \
			gdsl.c \
			gdsl.h

libgdsl_la_LDFLAGS 	= -version-info ${GDSL_LT_VERSION}
