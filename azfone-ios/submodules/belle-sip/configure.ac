#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.63])

AC_INIT([belle-sip],[1.3.3],[jehan.monnier@linphone.org])

BELLESIP_SO_CURRENT=0 dnl increment this number when you add/change/remove an interface
BELLESIP_SO_REVISION=0 dnl increment this number when you change source code, without changing interfaces; set to 0 when incrementing CURRENT
BELLESIP_SO_AGE=0 dnl increment this number when you add an interface, set to 0 if you remove an interface

BELLESIP_SO_VERSION=$BELLESIP_SO_CURRENT:$BELLESIP_SO_REVISION:$BELLESIP_SO_AGE

AC_SUBST(BELLESIP_SO_CURRENT, $BELLESIP_SO_CURRENT)
AC_SUBST(BELLESIP_SO_VERSION)

AC_CONFIG_SRCDIR([src/belle_sip_utils.c])

AC_CONFIG_MACRO_DIR([m4])

AC_CONFIG_HEADERS([config.h])

AC_CANONICAL_SYSTEM

dnl initialize pkg-config so that we can use it within if else fi statements.
PKG_PROG_PKG_CONFIG()

AM_INIT_AUTOMAKE([subdir-objects])
AM_SILENT_RULES(yes)

# Checks for programs.
dnl do not put anythingelse before AC_PROG_CC unless checking if macro still work for clang
dnl because of tunnel library wrapper, C++ is required.
AC_PROG_CXX(["xcrun clang++" g++])
AC_PROG_CC(["xcrun clang" gcc])
AC_PROG_OBJC(["xcrun clang" gcc])

AM_PROG_CC_C_O

dnl AC_PROG_CC_C99
LT_INIT(win32-dll)

case "$target" in
	#macosx 64 bits
        x86_64-apple-darwin*)
                LIBS="$LIBS -mmacosx-version-min=10.6"
                CXXFLAGS="$CXXFLAGS -mmacosx-version-min=10.6"
                CFLAGS="$CFLAGS -mmacosx-version-min=10.6"
        ;;
        i386-apple*|armv6-apple*|armv7-apple*|armv7s-apple*)
		LIBS="$LIBS -framework Foundation -framework CoreFoundation -framework CFNetwork -framework UIKit"
		build_ios=yes
	;;
esac

AM_CONDITIONAL([BUILD_IOS], [test "x$build_ios" = "xyes"])

dnl Workaround for mingw, whose compiler does not check in /usr/include ...
case "$target_os" in
	*mingw*)
		if test "$cross_compiling" != "yes"; then
			if test "$prefix" = "/usr" ; then
				CPPFLAGS="$CPPFLAGS -I/usr/include"
				LDFLAGS="$LDFLAGS -L/usr/lib"
			fi
		fi
	;;
esac


if test -f /etc/debian_version ; then
	use_deb=true;
else
	use_rpm=true;
fi

AC_ARG_ENABLE(debug,
		[  --enable-debug    Turn on debug mode (default=no)],
		[case "${enableval}" in
		yes) debug=true ;;
		no)  debug=false ;;
		*) AC_MSG_ERROR(bad value ${enableval} for --enable-debug) ;;
		esac],[debug=false])

CFLAGS="$CFLAGS -fms-extensions"
if test "$debug" = "no" ; then
	CFLAGS="$CFLAGS -g -O2"
else
	CFLAGS="$CFLAGS -g"
fi

AC_ARG_ENABLE(strict,
		[  --enable-strict    Turn on strict mode compilation, no warnings allowed (default=yes)],
		[case "${enableval}" in
		yes) strict=true ;;
		no)  strict=false ;;
		*) AC_MSG_ERROR(bad value ${enableval} for --enable-strict) ;;
		esac],[strict=true])

STRICT_OPTIONS="-Wall"
STRICT_OPTIONS_CC=""
STRICT_OPTIONS_CXX=""

case "$CC" in
	*clang*)
	STRICT_OPTIONS="$STRICT_OPTIONS -Wno-error=unknown-warning-option -Qunused-arguments -Wno-tautological-compare -Wno-builtin-requires-header -Wno-unused-function -Wno-gnu-designator "
	#disabled due to wrong optimization false positive with small string
	#(cf. https://gcc.gnu.org/bugzilla/show_bug.cgi?id=35903)
	STRICT_OPTIONS="$STRICT_OPTIONS -Wno-array-bounds "
	;;
	gcc*)
	STRICT_OPTIONS="$STRICT_OPTIONS -Wno-error=pragmas"
	;;
esac

# because Darwin's gcc is actually clang, we need to check it...
case "$target_os" in
	*darwin*)
	STRICT_OPTIONS="$STRICT_OPTIONS -Wno-error=unknown-warning-option -Qunused-arguments -Wno-tautological-compare -Wno-unused-function "
	#disabled due to wrong optimization false positive with small string
	#(cf. https://gcc.gnu.org/bugzilla/show_bug.cgi?id=35903)
	STRICT_OPTIONS="$STRICT_OPTIONS -Wno-array-bounds "
	;;
esac

if test "$strict" = "true"; then
	STRICT_OPTIONS="$STRICT_OPTIONS -Werror -Wno-error=unknown-pragmas -Wuninitialized"
	STRICT_OPTIONS_CC="$STRICT_OPTIONS_CC -Wdeclaration-after-statement"
fi

dnl because of antlr3 we must accept a few warnings...
dnl more portable for the moment
       LESS_STRICT_OPTIONS=
dnl       LESS_STRICT_OPTIONS="$STRICT_OPTIONS -Wno-error=unused-function \
dnl        -Wno-error=uninitialized -Wno-error=unused-variable \
dnl        -Wno-error=unused-but-set-variable "

AC_SUBST(STRICT_OPTIONS)
AC_SUBST(STRICT_OPTIONS_CC)
AC_SUBST(STRICT_OPTIONS_CXX)
AC_SUBST(LESS_STRICT_OPTIONS)

# Checks for libraries.

# Checks for header files.
AC_ARG_WITH( antlr,
      [  --with-antlr      Set prefix where libantlr3c can be found (ex:/usr or /usr/local)[default=PREFIX] ],
      [ antlr_prefix=${withval}],[ antlr_prefix=${prefix} ])

found_antlr3=no
if test "$antlr_prefix" != "NONE" ; then
	ANTLR_CFLAGS="-I${antlr_prefix}/include"
	ANTLR_LIBS="-L${antlr_prefix}/lib"
fi

ANTLR_LIBS="$ANTLR_LIBS -lantlr3c"

dnl check antlr headers
CPPFLAGS_save=$CPPFLAGS
CPPFLAGS="$ANTLR_CFLAGS $CPPFLAGS"
AC_CHECK_HEADERS([antlr3.h], [found_antlr3=yes])
AC_CHECK_DECL([antlr3StringStreamNew],
		[AC_DEFINE(HAVE_ANTLR_STRING_STREAM_NEW,1,[Defined when antlr 3.4 api is detected])],
		[foo=bar],
		[#include <antlr3.h>])
libresolv_have_res_get_servers=no
resolv_h_hav_res_ndestroy=no
LIBS_save=$LIBS

LIBS="$LIBS -lresolv"

AC_LINK_IFELSE([AC_LANG_PROGRAM([[#include <resolv.h>]],
                      			[[res_getservers(NULL,NULL,0)]])]
								,[libresolv_have_res_get_servers=yes
									AC_MSG_NOTICE([res_getservers usable])]
								,[LIBS=$LIBS_save
									AC_MSG_WARN([res_getservers not usable])])

AC_CHECK_DECL([res_ndestroy],
		[resolv_h_hav_res_ndestroy=yes],
		[foo=bar],
		[#include <resolv.h>])
if test "${libresolv_have_res_get_servers}${resolv_h_hav_res_ndestroy}" == "yesyes" ; then
	AC_DEFINE(HAVE_RESINIT,1,[Defined when res_ninit api is available])
fi
CPPFLAGS=$CPPFLAGS_save

if test "$found_antlr3" != "yes" ; then
	AC_MSG_ERROR([Could not find antlr3 development files. Please install antlr3 version > 3.2 (libantlr3c-dev on debian/ubuntu systems)])
	ANTLR_CFLAGS=
	ANTLR_LIBS=
fi
AC_PATH_PROG([ANTLR],[antlr3],[no],[$antlr_prefix/bin /usr/bin])

if test $ANTLR = "no" ; then
antlr_java_prefixes="$antlr_prefix/share/java /usr/local/share/java /usr/share/java /opt/local/share/java"

	for antlr_java_prefix in $antlr_java_prefixes
	do
		antlr_jar=$antlr_java_prefix/antlr.jar
		if test -f $antlr_jar ; then
			break
		else
			antlr_jar=no
		fi
		antlr_jar=$antlr_java_prefix/antlr3.jar
		if test -f $antlr_jar ; then
			break
		else
			antlr_jar=no
		fi
	done
	if test $antlr_jar = "no" ; then
		AC_MSG_ERROR([Could not find antlr.jar. Please install antlr3 ])
	fi
	AC_PATH_PROG([JAVA],[java],[no])
	if test $JAVA = "no" ; then
		AC_MSG_ERROR([Could not find java prog. Please install java ])
	else
		ANTLR="$JAVA -jar $antlr_jar"
	fi
fi
AC_SUBST(ANTLR_CFLAGS)
AC_SUBST(ANTLR_LIBS)

AC_ARG_ENABLE(	tls,
		[  --enable-tls		Enable TLS support (default=yes)],
		[case "${enableval}" in
		yes) use_tls=true ;;
		no)  use_tls=false ;;
		*) AC_MSG_ERROR(bad value ${enableval} for --enable-tls) ;;
		esac],[use_tls=true])

AC_ARG_WITH( polarssl,
      [  --with-polarssl      Set prefix where polarssl can be found (ex:/usr, /usr/local)[default=PREFIX] ],
      [ polarssl_prefix=${withval}],[ polarssl_prefix=${prefix} ])

if test "$polarssl_prefix" != "NONE" ; then
	POLARSSL_CFLAGS="-I${polarssl_prefix}/include"
	POLARSSL_LIBS="-L${polarssl_prefix}/lib"
fi

POLARSSL_LIBS="$POLARSSL_LIBS -lpolarssl"
found_polarssl=no

if test "$use_tls" = "true" ; then
	CPPFLAGS_save=$CPPFLAGS
	LIBS_save=$LIBS

	CPPFLAGS="$CPPFLAGS $POLARSSL_CFLAGS"
	LIBS="$LIBS $POLARSSL_LIBS"
	AC_CHECK_HEADERS(polarssl/ssl.h,
		[
		AC_LINK_IFELSE([AC_LANG_PROGRAM([[
			#include <polarssl/version.h>
			#include <polarssl/x509.h>
			#if POLARSSL_VERSION_NUMBER >= 0x01030000
			#include <polarssl/compat-1.2.h>
			#endif
			]],
                      	[[x509parse_crtpath(0,0)]])]
			,[found_polarssl=yes
			POLARSSL_LIBS=" -lpolarssl"
			AC_MSG_NOTICE([polarssl usable])]
			,[AC_MSG_WARN([polarssl not usable])])

		])
	CPPFLAGS=$CPPFLAGS_save
	LIBS=$LIBS_save
fi

AM_CONDITIONAL([BUILD_TLS], [test "x$found_polarssl" = "xyes"])
TLS_CFLAGS=""
TLS_LIBS=""
TLS_PC=""
if test "x$found_polarssl" = "xyes" ; then
	AC_DEFINE(HAVE_POLARSSL,1,[Defined when polarssl api is available])
	TLS_CFLAGS=$POLARSSL_CFLAGS
	TLS_LIBS=$POLARSSL_LIBS
fi
AC_SUBST(TLS_CFLAGS)
AC_SUBST(TLS_LIBS)
AC_SUBST(TLS_PC)

AC_ARG_ENABLE(server_sockets,
	[AS_HELP_STRING([--disable-server-sockets], [Disable server sockets creation])],
	[case "${enableval}" in
		yes) server_sockets_enabled=true ;;
		no) server_sockets_enabled=false ;;
		*) AC_MSG_ERROR(bad value ${enableval} for --disable-server-sockets) ;;
	esac],
	[server_sockets_enabled=yes]
)
if test "x$server_sockets_enabled" = "xyes" ; then
	AC_DEFINE(ENABLE_SERVER_SOCKETS,1,[Defined when server sockets are enabled])
fi

AC_ARG_ENABLE(tunnel,
	[AS_HELP_STRING([--enable-tunnel], [Enable tunnel support (default=no)])])
if test "$enable_tunnel" = "yes" ; then
	PKG_CHECK_MODULES(TUNNEL, tunnel, [found_tunnel=yes], [found_tunnel=no])
	if test "$found_tunnel" = "yes" ; then
		AC_DEFINE(HAVE_TUNNEL, 1, [Defined when tunnel is enabled and available])
	fi
fi
AM_CONDITIONAL(BUILD_TUNNEL, test "$found_tunnel" = "yes")

PKG_CHECK_MODULES(CUNIT, cunit, [found_pkg_config_cunit=yes],[found_pkg_config_cunit=no])

if test "$found_pkg_config_cunit" = "no" ; then
	AC_CHECK_HEADERS(CUnit/CUnit.h,
		[
			AC_CHECK_LIB(cunit,CU_add_suite,[
				found_cunit=yes
				CUNIT_LIBS+=" -lcunit"
			])

		])
else
	found_cunit=yes
fi
case "$target_os" in
	*darwin*)
		#hack for macport
		CUNIT_LIBS+=" -lncurses"
	;;
	*mingw*)
		LIBBELLESIP_CFLAGS="-DBELLESIP_EXPORTS"
		CPPFLAGS="$CPPFLAGS -D_WIN32_WINNT=0x0501"
		LIBS="$LIBS -lws2_32 -liphlpapi"
		LDFLAGS="$LDFLAGS -Wl,--export-all-symbols"
	;;
esac
AC_SUBST(LIBBELLESIP_CFLAGS)

if test "$found_cunit" = "no" ; then
	AC_MSG_WARN([Could not find cunit framework, tests are not compiled.])
else
	AC_CHECK_LIB(cunit,CU_get_suite,[
					AC_DEFINE(HAVE_CU_GET_SUITE,1,[defined when CU_get_suite is available])
					],[foo=bar],[$CUNIT_LIBS])
	AC_CHECK_LIB(cunit,CU_curses_run_tests,[
					AC_DEFINE(HAVE_CU_CURSES,1,[defined when CU_curses_run_tests is available])
					],[foo=bar],[$CUNIT_LIBS])
fi
AC_ARG_ENABLE(tests,
        [AS_HELP_STRING([--disable-tests], [Disable compilation of tests])],
        [case "${enableval}" in
                yes)    tests_enabled=true ;;
                no)     tests_enabled=false ;;
                *)      AC_MSG_ERROR(bad value ${enableval} for --disable-tests) ;;
        esac],
        [tests_enabled=yes]
)
AM_CONDITIONAL(ENABLE_TESTS, test x$tests_enabled = xyes && test x$found_cunit = xyes)

REQUIRES_PRIVATE=""
LIBS_PRIVATE=""
if test "$found_pkg_config_cunit" = "yes" ; then
	REQUIRES_PRIVATE="$REQUIRES_PRIVATE cunit"
else
	if test "$found_cunit" = "yes" ; then
		LIBS_PRIVATE="$LIBS_PRIVATE $CUNIT_LIBS"
	fi
fi
LIBS_PRIVATE="$LIBS_PRIVATE $ANTLR_LIBS $POLARSSL_LIBS"
AC_SUBST(REQUIRES_PRIVATE)
AC_SUBST(LIBS_PRIVATE)

# Checks for typedefs, structures, and compiler characteristics.


# Eliminate -lstdc++ addition to postdeps for cross compiles.
postdeps_CXX=`echo " $postdeps_CXX " | sed 's, -lstdc++ ,,g'`


# Checks for library functions.
AC_CHECK_LIB(rt, clock_gettime)
AC_CHECK_LIB(dl, dlopen)
AC_CHECK_LIB(pthread, pthread_getspecific,,
    [AC_MSG_ERROR([pthread library not found])])

AC_CONFIG_FILES(
[
Makefile
include/Makefile
include/belle-sip/Makefile
src/Makefile
src/grammars/Makefile
tester/Makefile
belle-sip.pc
belle-sip.spec
])
AC_OUTPUT
