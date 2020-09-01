dnl Process this file with autoconf to produce a configure script.

AC_PREREQ([2.59])
AC_INIT([gdsl], [1.8], [ndarnis@free.fr])

AM_INIT_AUTOMAKE
AM_CONFIG_HEADER(config.h)

AC_CANONICAL_HOST

dnl Library versioning (current:revision:age)
dnl See the libtool manual for an explanation of the numbers
dnl
dnl gdsl-1.0    libgdsl 1:0:0
dnl gdsl-1.1    libgdsl 1:0:1
dnl gdsl-1.2	libgdsl 1:0:2
dnl gdsl-1.3	libgdsl 1:0:3
dnl gdsl-1.4	libgdsl 1:0:4
dnl gdsl-1.5    libgdsl 1:0:5
dnl gdsl-1.6    libgdsl 1:0:6
dnl gdsl-1.7    libgdsl 1:0:7
dnl gdsl-1.8    libgdsl 1:0:8

GDSL_LT_VERSION="1:8:0"
AC_SUBST(GDSL_LT_VERSION)


dnl Things required by automake
AC_ARG_PROGRAM


dnl Checks for programs.
AC_PROG_CC
AC_PROG_AWK
AC_PROG_CPP
AC_PROG_INSTALL
AC_PROG_LN_S
AC_PROG_MAKE_SET
AC_PROG_RANLIB
AC_PROG_LIBTOOL


dnl Checks for libraries.


dnl Checks for header files.
AC_HEADER_STDC
AC_CHECK_HEADERS([sys/time.h stdlib.h stdio.h unistd.h])


dnl Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_TYPE_SIZE_T
AC_HEADER_TIME
AC_CHECK_TYPE([ulong])
AC_CHECK_TYPE([ushort])

dnl Checks for compiler features.
AC_TYPE_SIZE_T
AC_C_CONST
AC_C_INLINE


dnl Checks for library functions.
AC_FUNC_ALLOCA
AC_CHECK_FUNCS([gettimeofday strdup])


dnl Checks for system services.
AC_MSG_CHECKING([whether your compiler is gcc])
BASE_CC=`basename ${CC}x`
if test "`echo ${BASE_CC}|cut -c1-3`" = gcc ;
then
CFLAGS="-Wall -Wstrict-prototypes $CFLAGS"
	AC_MSG_RESULT([yes... -Wall -Wstrict-prototypes added.])
else
	AC_MSG_RESULT([no.])
fi


CPPFLAGS="-D_REENTRANT -D_THREAD_SAFE -D_GNU_SOURCE -pedantic $CPPFLAGS"


dnl  Enable debugging feature ?
ac_debug="no"
AC_ARG_ENABLE([debug],
	[  --enable-debug          enable debugging features [default=disabled]],
	[ac_debug=$enableval], [ac_debug=no])
AC_CACHE_CHECK([whether to enable debuging features], [ac_debug], [ac_debug=no])

if test "$ac_debug" = yes; then
  AC_DEFINE([HAVE_DEBUG])
fi


dnl  Without gdsl types ?
ac_without_gdsl_types="no"
AC_ARG_WITH()

if test "$ac_without_gdsl_types" = yes; then
  CPPFLAGS="-DWITHOUT_GDSL_TYPES $CPPFLAGS"
fi


dnl  Host os

case "$host_os" in
	linux*)		AC_DEFINE([HAVE_LINUX])
			;;

	freebsd*)	AC_DEFINE([HAVE_FREEBSD])
			;;

	netbsd*)	AC_DEFINE([HAVE_NETBSD])
			;;
esac


dnl For gdsl-config script
GDSL_CFLAGS="-I$includedir/gdsl"
GDSL_LIBS="-L$libdir -lgdsl"
AC_SUBST(GDSL_CFLAGS)
AC_SUBST(GDSL_LIBS)


dnl Output files
AC_OUTPUT([                        \
          gdsl.spec                \
          gdsl-config              \
          src/Makefile             \
          src/mainpage.h           \
          src/examples/Makefile    \
          doc/Makefile             \
          doc/Doxyfile             \
          doc/man3/Makefile        \
          doc/html/Makefile        \
          doc/latex/Makefile       \
          Makefile		   \
	  ])
