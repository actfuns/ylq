## Process this file with automake to produce Makefile.in

CLEANFILES		= *~
AM_CFLAGS		= -I$(top_builddir) -I$(top_srcdir)/src

check_PROGRAMS		= lllist list llbstree bstree rbtree llbintree perm array2d queue stack hash heap sort interval_heap

lllist_SOURCES		= main_lllist.c _strings.c _strings.h
lllist_LDADD		= ../libgdsl.la

list_SOURCES		= main_list.c _strings.c _strings.h
list_LDADD		= ../libgdsl.la

llbstree_SOURCES	= main_llbstree.c _strings.c _strings.h _integers.c _integers.h
llbstree_LDADD		= ../libgdsl.la

bstree_SOURCES		= main_bstree.c _strings.c _strings.h _integers.c _integers.h
bstree_LDADD		= ../libgdsl.la

llbintree_SOURCES	=  main_llbintree.c _strings.c _strings.h
llbintree_LDADD		= ../libgdsl.la

perm_SOURCES		= main_perm.c _integers.c _integers.h
perm_LDADD		= ../libgdsl.la

array2d_SOURCES		= main_2darray.c _integers.c _integers.h
array2d_LDADD		= ../libgdsl.la

queue_SOURCES		= main_queue.c _integers.c _integers.h
queue_LDADD		= ../libgdsl.la

stack_SOURCES		= main_stack.c _integers.c _integers.h
stack_LDADD		= ../libgdsl.la

rbtree_SOURCES		= main_rbtree.c _strings.c _strings.h _integers.c _integers.h
rbtree_LDADD		= ../libgdsl.la

hash_SOURCES		= main_hash.c _strings.c _strings.h
hash_LDADD		= ../libgdsl.la

heap_SOURCES		= main_heap.c _integers.c _integers.h
heap_LDADD		= ../libgdsl.la

interval_heap_SOURCES		= main_interval_heap.c _integers.c _integers.h
interval_heap_LDADD		= ../libgdsl.la

sort_SOURCES		= main_sort.c
sort_LDADD		= ../libgdsl.la

