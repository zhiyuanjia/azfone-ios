#   -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.



AC_INIT([bcg729],[0.1])
AC_CANONICAL_SYSTEM
AC_PREREQ(2.63)
AC_CONFIG_SRCDIR([src/encoder.c])
AC_CONFIG_MACRO_DIR([m4])
AM_INIT_AUTOMAKE([tar-ustar --warnings=no-portability])
AC_PROG_LIBTOOL
AC_PROG_CC
AC_CONFIG_HEADERS(config.h)
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_ARG_ENABLE(strict,
	[  --enable-strict       Enable error on compilation warning [default=yes]],
	[wall_werror=$enableval],
	[wall_werror=yes]
)
# configure option to disable the tests
AC_ARG_ENABLE([tests],
	AS_HELP_STRING([--disable-tests], [Disable the tests]))
	AM_CONDITIONAL([RUN_TESTS], [test "x$enable_tests" != "xno"])
# configure option to disable mediastreamer plugin
AC_ARG_ENABLE([msplugin],
	AS_HELP_STRING([--disable-msplugin], [Disable the mediastreamer plugin]),
	enable_msplugin="$enableval",
	enable_msplugin="yes"
)

CFLAGS="$CFLAGS -Wall"

if test $GCC = yes && test $wall_werror = yes;  then
	CFLAGS="$CFLAGS -Werror "
fi

# check for libraries that have pkg-config files installed
PKG_CHECK_MODULES(ORTP, ortp >= 0.21.0,[found_ortp=true],foo=bar)
PKG_CHECK_MODULES(MEDIASTREAMER, mediastreamer >= 2.8.99,[found_ms2=true],foo=bar)
AM_CONDITIONAL(BUILD_MSBCG729, test x${found_ms2}x${found_ortp}x${enable_msplugin} = xtruextruexyes)

VISIBILITY_CFLAGS=
case "$target_os" in
	*mingw*)
		CFLAGS="$CFLAGS -D_WIN32_WINNT=0x0501"
		mingw_found=yes
	;;
	*)
		VISIBILITY_CFLAGS="-fvisibility=hidden"
	;;
esac
AC_SUBST(VISIBILITY_CFLAGS)

# Initialize libtool
LT_INIT([win32-dll shared disable-static])

AC_CONFIG_COMMANDS([libtool-hacking],
	[if test "$mingw_found" = "yes" ; then
		echo "Hacking libtool to work with mingw..."
		sed -e 's/\*\" \$a_deplib \"\*/\*/' < ./libtool > libtool.tmp
		cp -f ./libtool.tmp ./libtool
		rm -f ./libtool.tmp
	fi],
	[mingw_found=$mingw_found]
)

# Create the following files from their .in counterparts
AC_CONFIG_FILES([
	Makefile
	src/Makefile 
	include/Makefile 
	include/bcg729/Makefile 
	msbcg729/Makefile 
	test/Makefile 
	test/bin/Makefile 
	libbcg729.pc
	bcg729.spec
])


AC_OUTPUT
