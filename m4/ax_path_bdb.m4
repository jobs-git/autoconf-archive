# ===========================================================================
#       https://www.gnu.org/software/autoconf-archive/ax_path_bdb.html
# ===========================================================================
#
# SYNOPSIS
#
#   AX_PATH_BDB([MINIMUM-VERSION], [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND])
#
# DESCRIPTION
#
#   This macro finds the latest version of Berkeley DB on the system, and
#   ensures that the header file and library versions match. If
#   MINIMUM-VERSION is specified, it will ensure that the library found is
#   at least that version.
#
#   It determines the name of the library as well as the path to the header
#   file and library. It will check both the default environment as well as
#   the default Berkeley DB install location. When found, it sets BDB_LIBS,
#   BDB_CPPFLAGS, and BDB_LDFLAGS to the necessary values to add to LIBS,
#   CPPFLAGS, and LDFLAGS, as well as setting BDB_VERSION to the version
#   found. HAVE_DB_H is defined also.
#
#   The option --with-bdb-dir=DIR can be used to specify a specific Berkeley
#   DB installation to use.
#
#   An example of it's use is:
#
#     AX_PATH_BDB([3],[
#       LIBS="$BDB_LIBS $LIBS"
#       LDFLAGS="$BDB_LDFLAGS $LDFLAGS"
#       CPPFLAGS="$CPPFLAGS $BDB_CPPFLAGS"
#     ])
#
#   which will locate the latest version of Berkeley DB on the system, and
#   ensure that it is version 3.0 or higher.
#
#   Details: This macro does not use either AC_CHECK_HEADERS or AC_CHECK_LIB
#   because, first, the functions inside the library are sometimes renamed
#   to contain a version code that is only available from the db.h on the
#   system, and second, because it is common to have multiple db.h and libdb
#   files on a system it is important to make sure the ones being used
#   correspond to the same version. Additionally, there are many different
#   possible names for libdb when installed by an OS distribution, and these
#   need to be checked if db.h does not correspond to libdb.
#
#   When cross compiling, only header versions are verified since it would
#   be difficult to check the library version. Additionally the default
#   Berkeley DB installation locations /usr/local/BerkeleyDB* are not
#   searched for higher versions of the library.
#
#   The format for the list of library names to search came from the Cyrus
#   IMAP distribution, although they are generated dynamically here, and
#   only for the version found in db.h.
#
#   The macro AX_COMPARE_VERSION is required to use this macro, and should
#   be available from the Autoconf Macro Archive.
#
#   The author would like to acknowledge the generous and valuable feedback
#   from Guido Draheim, without which this macro would be far less robust,
#   and have poor and inconsistent cross compilation support.
#
#   Changes:
#
#    1/5/05 applied patch from Rafal Rzepecki to eliminate compiler
#           warning about unused variable, argv
#
# LICENSE
#
#   Copyright (c) 2008 Tim Toolan <toolan@ele.uri.edu>
#
#   Copying and distribution of this file, with or without modification, are
#   permitted in any medium without royalty provided the copyright notice
#   and this notice are preserved. This file is offered as-is, without any
#   warranty.

#serial 23

dnl #########################################################################
AC_DEFUN([AX_PATH_BDB], [
  dnl # Used to indicate success or failure of this function.
  ax_path_bdb_ok=no
  _AX_PATH_BDB_MIN_VERSION='m4_default_quoted($1,0)'

  # Add --with-bdb-dir option to configure.
  AC_ARG_WITH([bdb-dir],
    [AS_HELP_STRING([--with-bdb-dir=DIR],
                    [Berkeley DB installation directory])])

  # Check if --with-bdb-dir was specified.
  if test "x$with_bdb_dir" = "x" ; then
    # No option specified, so just search the system.
    AX_PATH_BDB_NO_OPTIONS([${_AX_PATH_BDB_MIN_VERSION}], [HIGHEST], [
      ax_path_bdb_ok=yes
    ])
   else
     # Set --with-bdb-dir option.
     ax_path_bdb_INC="$with_bdb_dir/include"
     ax_path_bdb_LIB="$with_bdb_dir/lib"

     dnl # Save previous environment, and modify with new stuff.
     ax_path_bdb_save_CPPFLAGS="$CPPFLAGS"
     CPPFLAGS="-I$ax_path_bdb_INC $CPPFLAGS"

     ax_path_bdb_save_LDFLAGS=$LDFLAGS
     LDFLAGS="-L$ax_path_bdb_LIB $LDFLAGS"

     # Check for specific header file db.h
     AC_MSG_CHECKING([db.h presence in $ax_path_bdb_INC])
     if test -f "$ax_path_bdb_INC/db.h" ; then
       AC_MSG_RESULT([yes])
       # Check for library
       AX_PATH_BDB_NO_OPTIONS([${_AX_PATH_BDB_MIN_VERSION}], [ENVONLY], [
         ax_path_bdb_ok=yes
         BDB_CPPFLAGS="-I$ax_path_bdb_INC"
         BDB_LDFLAGS="-L$ax_path_bdb_LIB"
       ])
     else
       AC_MSG_RESULT([no])
       AC_MSG_NOTICE([no usable Berkeley DB not found])
     fi

     dnl # Restore the environment.
     CPPFLAGS="$ax_path_bdb_save_CPPFLAGS"
     LDFLAGS="$ax_path_bdb_save_LDFLAGS"

  fi

  dnl # Execute ACTION-IF-FOUND / ACTION-IF-NOT-FOUND.
  if test "$ax_path_bdb_ok" = "yes" ; then
    m4_ifvaln([$2],[$2],[:])dnl
    m4_ifvaln([$3],[else $3])dnl
  fi

]) dnl AX_PATH_BDB

dnl #########################################################################
dnl Check for berkeley DB of at least MINIMUM-VERSION on system.
dnl
dnl The OPTION argument determines how the checks occur, and can be one of:
dnl
dnl   HIGHEST -  Check both the environment and the default installation
dnl              directories for Berkeley DB and choose the version that
dnl              is highest. (default)
dnl   ENVFIRST - Check the environment first, and if no satisfactory
dnl              library is found there check the default installation
dnl              directories for Berkeley DB which is /usr/local/BerkeleyDB*
dnl   ENVONLY -  Check the current environment only.
dnl
dnl Requires AX_PATH_BDB_PATH_GET_VERSION, AX_PATH_BDB_PATH_FIND_HIGHEST,
dnl          _AX_PATH_BDB_ENV_CONFIRM_LIB, AX_PATH_BDB_ENV_GET_VERSION, and
dnl          AX_COMPARE_VERSION macros.
dnl
dnl Result: sets ax_path_bdb_no_options_ok to yes or no
dnl         sets BDB_LIBS, BDB_CPPFLAGS, BDB_LDFLAGS, BDB_VERSION
dnl
dnl AX_PATH_BDB_NO_OPTIONS([MINIMUM-VERSION], [OPTION], [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND])
AC_DEFUN([AX_PATH_BDB_NO_OPTIONS], [
  dnl # Used to indicate success or failure of this function.
  _AX_PATH_BDB_NO_OPTIONS_ok=no

  # Values to add to environment to use Berkeley DB.
  BDB_VERSION=''
  BDB_LIBS=''
  BDB_CPPFLAGS=''
  BDB_LDFLAGS=''

  # Check version of Berkeley DB in the current environment.
  _AX_PATH_BDB_ENV_GET_VERSION([
    AX_COMPARE_VERSION([$_AX_PATH_BDB_ENV_GET_VERSION_VERSION],[ge],[$1],[
      # Found acceptable version in current environment.
      _AX_PATH_BDB_NO_OPTIONS_ok=yes
      BDB_VERSION="$_AX_PATH_BDB_ENV_GET_VERSION_VERSION"
      BDB_LIBS="$_AX_PATH_BDB_ENV_GET_VERSION_LIBS"
    ])
  ])
  AC_MSG_CHECKING([for version >= $1 of Berkeley DB in current environment])
  AS_IF([test "x$BDB_VERSION" = "x"],AC_MSG_RESULT([no]),AC_MSG_RESULT([$BDB_VERSION]))

  # Check cross compilation here.
  if test "x$cross_compiling" = "xno" ; then
    # Not cross compiling.
    AC_MSG_CHECKING([for local installation of Berkeley DB])
    # Determine if we need to search /usr/local/BerkeleyDB*
    AS_CASE(["x$2"],
            [xENVONLY],[_AX_PATH_BDB_NO_OPTIONS_DONE=yes],
	    [xENVFIRST],[_AX_PATH_BDB_NO_OPTIONS_DONE="${_AX_PATH_BDB_NO_OPTIONS_ok}"],
	    [_AX_PATH_BDB_NO_OPTIONS_DONE=no])
    AS_IF([test "x$_AX_PATH_BDB_NO_OPTIONS_DONE" = "xyes"],AC_MSG_RESULT([no]),AC_MSG_RESULT([yes]))

    if test "x$_AX_PATH_BDB_NO_OPTIONS_DONE" = 'xno' ; then
      # Check for highest in /usr/local/BerkeleyDB*
      _AX_PATH_BDB_PATH_FIND_HIGHEST([
        if test "x$_AX_PATH_BDB_NO_OPTIONS_ok" = "xyes" ; then
        # If we already have an acceptable version use this if higher.
          AX_COMPARE_VERSION(
             [$_AX_PATH_BDB_PATH_FIND_HIGHEST_VERSION],[gt],[$BDB_VERSION])
        else
          # Since we didn't have an acceptable version check if this one is.
          AX_COMPARE_VERSION(
             [$_AX_PATH_BDB_PATH_FIND_HIGHEST_VERSION],[ge],[$1])
        fi
      ])

      dnl # If result from _AX_COMPARE_VERSION is true we want this version.
      if test "$ax_compare_version" = "true" ; then
        _AX_PATH_BDB_NO_OPTIONS_ok=yes
        BDB_LIBS="-ldb"
	if test "x$ax_path_bdb_path_find_highest_DIR" != x ; then
	  BDB_CPPFLAGS="-I$_AX_PATH_BDB_PATH_FIND_HIGHEST_DIR/include"
	  BDB_LDFLAGS="-L$_AX_PATH_BDB_PATH_FIND_HIGHEST_DIR/lib"
	fi
        BDB_VERSION="$_AX_PATH_BDB_PATH_FIND_HIGHEST_VERSION"
      fi
    fi
  fi

  dnl # Execute ACTION-IF-FOUND / ACTION-IF-NOT-FOUND.
  if test "x$_AX_PATH_BDB_NO_OPTIONS_ok" = "xyes" ; then
    AC_MSG_NOTICE([using Berkeley DB version $BDB_VERSION])
    AC_DEFINE([HAVE_DB_H],[1],
              [Define to 1 if you have the <db.h> header file.])
    m4_ifvaln([$3],[$3])dnl
  else
    AC_MSG_NOTICE([no Berkeley DB version $1 or higher found])
    m4_ifvaln([$4],[$4])dnl
  fi
]) dnl AX_PATH_BDB_NO_OPTIONS

dnl #########################################################################
dnl Check the default installation directory for Berkeley DB which is
dnl of the form /usr/local/BerkeleyDB* for the highest version.
dnl
dnl Result: sets _AX_PATH_BDB_PATH_FIND_HIGHEST_ok to yes or no,
dnl         sets _AX_PATH_BDB_PATH_FIND_HIGHEST_VERSION to version,
dnl         sets _AX_PATH_BDB_PATH_FIND_HIGHEST_DIR to directory.
dnl
dnl AX_PATH_BDB_PATH_FIND_HIGHEST([ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND])
AC_DEFUN([_AX_PATH_BDB_PATH_FIND_HIGHEST], [
  dnl # Used to indicate success or failure of this function.
  _AX_PATH_BDB_PATH_FIND_HIGHEST_ok=no
  _AX_PATH_BDB_PATH_FIND_HIGHEST_VERSION=''
  _AX_PATH_BDB_PATH_FIND_HIGHEST_DIR=''

  # find highest version in default install directory for Berkeley DB
  for _AX_PATH_BDB_PATH_FIND_HIGHEST_CURDIR in `ls -d /usr/local/BerkeleyDB* 2> /dev/null`
  do
    _AX_PATH_BDB_PATH_GET_VERSION([$_AX_PATH_BDB_PATH_FIND_HIGHEST_CURDIR],[
      AS_IF([test "x_AX_PATH_BDB_PATH_FIND_HIGHEST_VERSION" = "x"],
            [
	      _AX_PATH_BDB_PATH_FIND_HIGHEST_ok=yes
	      _AX_PATH_BDB_PATH_FIND_HIGHEST_DIR="$_AX_PATH_BDB_PATH_FIND_HIGHEST_CURDIR"
	      _AX_PATH_BDB_PATH_FIND_HIGHEST_VERSION="$_AX_PATH_BDB_PATH_GET_VERSION_VERSION"
	    ],
	    [
	      AX_COMPARE_VERSION([$_AX_PATH_BDB_PATH_GET_VERSION_VERSION],[gt],[$_AX_PATH_BDB_PATH_FIND_HIGHEST_VERSION],[
                _AX_PATH_BDB_PATH_FIND_HIGHEST_ok=yes
                _AX_PATH_BDB_PATH_FIND_HIGHEST_DIR="$_AX_PATH_BDB_PATH_FIND_HIGHEST_CURDIR"
                _AX_PATH_BDB_PATH_FIND_HIGHEST_VERSION="$_AX_PATH_BDB_PATH_GET_VERSION_VERSION"
                ])
      ])
    ])
  done

  dnl # Execute ACTION-IF-FOUND / ACTION-IF-NOT-FOUND.
  AC_MSG_CHECKING([for highest version Berkeley database local install dir])
  if test "x$_AX_PATH_BDB_PATH_FIND_HIGHEST_ok" = 'xyes' ; then
    AC_MSG_RESULT([$_AX_PATH_BDB_PATH_FIND_HIGHEST_DIR])
    m4_ifvaln([$1],[$1],[:])dnl
  else
    AC_MSG_RESULT([none found])
    m4_ifvaln([$2],[else $2])dnl
  fi

]) dnl AX_PATH_BDB_PATH_FIND_HIGHEST

dnl #########################################################################
dnl Checks for Berkeley DB in specified directory's lib and include
dnl subdirectories.
dnl
dnl Result: sets ax_path_bdb_path_get_version_ok to yes or no,
dnl         _AX_PATH_BDB_PATH_GET_VERSION_VERSION to version.
dnl
dnl __AX_PATH_BDB_PATH_GET_VERSION(BDB-DIR, [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND])
AC_DEFUN([_AX_PATH_BDB_PATH_GET_VERSION], [
  dnl # Used to indicate success or failure of this function.
  _AX_PATH_BDB_PATH_GET_VERSION_ok=no
  # Indicate status of checking for Berkeley DB library.
  _AX_PATH_BDB_PATH_GET_VERSION_VERSION=''

  # Indicate status of checking for Berkeley DB header.
  AC_MSG_CHECKING([in $1 for Berkeley DB dir and files])
  AS_IF([test -d "$1/include" && test -f "$1/include/db.h" && test -d "$1/lib"],
        [_AX_PATH_BDB_PATH_GET_VERSION_got_files=yes],
 	[_AX_PATH_BDB_PATH_GET_VERSION_got_files=no])
  AC_MSG_RESULT([$_AX_PATH_BDB_PATH_GET_VERSION_got_files])

  if test "x$_AX_PATH_BDB_PATH_GET_VERSION_got_files" = 'xyes'; then
    AX_SAVE_FLAGS([_AX_PATH_BDB_PATH_GET_VERSION])
    CPPFLAGS="-I$1/include $CPPFLAGS"
    LIBS="-ldb $LIBS"
    LDFLAGS="-L$1/lib $LDFLAGS"

    _AX_PATH_BDB_ENV_GET_VERSION([
      _AX_PATH_BDB_PATH_GET_VERSION_ok=yes
    ])
    AX_RESTORE_FLAGS([_AX_PATH_BDB_PATH_GET_VERSION])
  fi

  dnl # Finally, execute ACTION-IF-FOUND / ACTION-IF-NOT-FOUND.
  AC_MSG_CHECKING([in $1 for Berkeley database])
  if test "_AX_PATH_BDB_PATH_GET_VERSION_ok" = "yes" ; then
     AC_MSG_RESULT([$_AX_PATH_BDB_PATH_GET_VERSION_VERSION])
     m4_ifvaln([$2],[$2])dnl
  else
     AC_MSG_RESULT([no])
     m4_ifvaln([$3],[$3])dnl
  fi
]) dnl _AX_PATH_BDB_PATH_GET_VERSION

#############################################################################
dnl Checks if version of library and header match specified version.
dnl Only meant to be used by AX_PATH_BDB_ENV_GET_VERSION macro.
dnl
dnl
dnl Result: sets _AX_PATH_BDB_ENV_CONFIRM_LIB_ok to yes or no.
dnl
dnl _AX_PATH_BDB_ENV_CONFIRM_LIB(VERSION, [LIBNAME])
AC_DEFUN([_AX_PATH_BDB_ENV_CONFIRM_LIB], [
  dnl # Used to indicate success or failure of this function.
  _AX_PATH_BDB_ENV_CONFIRM_LIB_ok=no

  dnl # save and modify environment to link with library LIBNAME
  ax_path_bdb_env_confirm_lib_save_LIBS="$LIBS"
  LIBS="$2 $LIBS"

  # compile and link a simple program
  AC_MSG_CHECKING([for compiling simple Berkeley database program using LIBS="$2"])
  AC_LINK_IFELSE([
    AC_LANG_SOURCE([[
#include <db.h>
int main(int argc,char **argv)
{
  int major,minor,patch;
  (void) argv;
  db_version(&major,&minor,&patch);
  (void) major; (void) minor; (void) patch;
  return 0;
}
    ]])
  ],[_AX_PATH_BDB_ENV_CONFIRM_LIB_ok=yes],[_AX_PATH_BDB_ENV_CONFIRM_LIB_ok=no])
  AC_MSG_RESULT($_AX_PATH_BDB_ENV_CONFIRM_LIB_ok)

  if test "x$_AX_PATH_BDB_ENV_CONFIRM_LIB_ok" = xyes; then
    # Compile and run a program that compares the version defined in
    # the header file with a version defined in the library function
    # db_version.
    # in case of crosscompile ignore
    AC_MSG_CHECKING([for runtime Berkeley database library version])
    AC_RUN_IFELSE([
      AC_LANG_SOURCE([[
#include <db.h>
int main(int argc,char **argv)
{
  int major,minor,patch;
  (void) argv;
  db_version(&major,&minor,&patch);
  if (DB_VERSION_MAJOR == major && DB_VERSION_MINOR == minor &&
      DB_VERSION_PATCH == patch)
    return 0;
  else
    return 1;
}
      ]])
    ],
    [
      AC_MSG_RESULT([yes])
      _AX_PATH_BDB_ENV_CONFIRM_LIB_ok=yes
    ],
    [
      AC_MSG_RESULT([no])
      _AX_PATH_BDB_ENV_CONFIRM_LIB_ok=no
    ],
    [
      AC_MSG_RESULT([guessing yes])
      _AX_PATH_BDB_ENV_CONFIRM_LIB_ok=yes]
    )
  fi
  dnl # restore environment
  LIBS="$ax_path_bdb_env_confirm_lib_save_LIBS"
]) dnl AX_PATH_BDB_ENV_CONFIRM_LIB


dnl Find the header using env result
dnl   _AX_PATH_BDB_ENV_GET_VERSION_HEADER_header_db_h=(yes|no)
dnl   _AX_PATH_BDB_ENV_GET_VERSION_HEADER_MAJOR
dnl   _AX_PATH_BDB_ENV_GET_VERSION_HEADER_MINOR
dnl   _AX_PATH_BDB_ENV_GET_VERSION_HEADER_PATCH
dnl   _AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION
AC_DEFUN([_AX_PATH_BDB_ENV_GET_VERSION_HEADER],[
  # default value
  _AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_MAJOR=''
  _AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_MINOR=''
  _AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_PATCH=''
  _AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_HEADER_VERSION=''
  # Indicate status of checking for Berkeley DB library.
  AC_MSG_CHECKING([for db.h])
  # could not cache compile manualy
  AC_COMPILE_IFELSE([
    AC_LANG_SOURCE([[
#include <db.h>
    ]])
    ],
    [
      _AX_PATH_BDB_ENV_GET_VERSION_HEADER_header_db_h=yes
      AC_MSG_RESULT([yes])
    ],
    [
      _AX_PATH_BDB_ENV_GET_VERSION_HEADER_header_db_h=no
      AC_MSG_RESULT([no])
    ]
  )

  if test "x$_AX_PATH_BDB_ENV_GET_VERSION_HEADER_header_db_h" = xyes; then
    AC_MSG_CHECKING([for db.h major version])
    AC_COMPUTE_INT(_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_MAJOR,DB_VERSION_MAJOR,[[#include <db.h>]],_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_MAJOR='none')
    AC_MSG_RESULT($_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_MAJOR)

    AC_MSG_CHECKING([for db.h minor version])
    AC_COMPUTE_INT(_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_MINOR,DB_VERSION_MINOR,[[#include <db.h>]],_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_MINOR='none')
    AC_MSG_RESULT($_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_MINOR)

    AC_MSG_CHECKING([for db.h patch level version])
    AC_COMPUTE_INT(_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_PATCH,DB_VERSION_PATCH,[[#include <db.h>]],_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_PATCH='none')
    AC_MSG_RESULT($_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_PATCH)
   
    AC_MSG_CHECKING([for db.h version])
    AS_IF([test "x$_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_MAJOR" = 'x'],[ax_path_bdb_env_get_version_HEADER_VERSION=''],
          [test "x$_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_MAJOR" = 'none'],[ax_path_bdb_env_get_version_HEADER_VERSION=''],
          [test "x$_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_MINOR" = 'x'],[ax_path_bdb_env_get_version_HEADER_VERSION=''],
          [test "x$_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_MINOR" = 'none'],[ax_path_bdb_env_get_version_HEADER_VERSION=''],
	  [test "x$_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_PATCH" = 'x'],[ax_path_bdb_env_get_version_HEADER_VERSION=''],
          [test "x$_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_PATCH" = 'none'],[ax_path_bdb_env_get_version_HEADER_VERSION=''],
          [_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION="$_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_MAJOR"."$_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_MINOR"."$_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_PATCH"])
    AS_IF([test "x$_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION" = 'x'],
       [
        AC_MSG_RESULT([none])
	_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_MAJOR=''
	_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_MINOR=''
        _AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_PATCH=''
       ],
       AC_MSG_RESULT([$_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION])
    )
  fi
])

#############################################################################
dnl Finds the version and library name for Berkeley DB in the
dnl current environment.  Tries many different names for library.
dnl
dnl Requires AX_PATH_BDB_ENV_CONFIRM_LIB macro.
dnl
dnl Result: set _AX_PATH_BDB_ENV_GET_VERSION_ok to yes or no,
dnl         set ax_path_bdb_env_get_version_VERSION to the version found,
dnl         and ax_path_bdb_env_get_version_LIBNAME to the library name.
dnl
dnl AX_PATH_BDB_ENV_GET_VERSION([ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND])
AC_DEFUN([_AX_PATH_BDB_ENV_GET_VERSION], [
  dnl # Used to indicate success or failure of this function.
  _AX_PATH_BDB_ENV_GET_VERSION_ok='no'
  _AX_PATH_BDB_ENV_GET_VERSION_VERSION=''
  _AX_PATH_BDB_ENV_GET_VERSION_LIBS=''

  _AX_PATH_BDB_ENV_GET_VERSION_HEADER

  # Have header version, so try to find corresponding library.
  # Looks for library names in the order:
  #   nothing, db, db-X.Y, dbX.Y, dbXY, db-X, dbX
  # and stops when it finds the first one that matches the version
  # of the header file.
  if test "x$_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION" != 'x' ; then
    AS_VAR_PUSHDEF([MAJOR],[_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_MAJOR])dnl
    AS_VAR_PUSHDEF([MINOR],[_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION_MINOR])dnl

    for _AX_PATH_BDB_ENV_GET_VERSION_TEST_LIBNAME in '' '-ldb' "-ldb-${MAJOR}.${MINOR}" "-ldb${MAJOR}.${MINOR}" "-ldb-${MAJOR}" "-ldb${MAJOR}${MINOR}"; do
       _AX_PATH_BDB_ENV_CONFIRM_LIB([$_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION], [$_AX_PATH_BDB_ENV_GET_VERSION_TEST_LIBNAME])
       if test "x$_AX_PATH_BDB_ENV_CONFIRM_LIB_ok" = "xyes"; then break; fi
    done

    AC_MSG_CHECKING([for library containing Berkeley DB version $_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION])
    dnl # Found a valid library.
    if test "$_AX_PATH_BDB_ENV_CONFIRM_LIB_ok" = "yes" ; then
      if test "x$_AX_PATH_BDB_ENV_GET_VERSION_TEST_LIBNAME" = "x" ; then
        AC_MSG_RESULT([none required])
      else
        AC_MSG_RESULT([$_AX_PATH_BDB_ENV_GET_VERSION_TEST_LIBNAME])
      fi
      _AX_PATH_BDB_ENV_GET_VERSION_VERSION="$_AX_PATH_BDB_ENV_GET_VERSION_HEADER_VERSION"
      _AX_PATH_BDB_ENV_GET_VERSION_LIBS="$_AX_PATH_BDB_ENV_GET_VERSION_TEST_LIBNAME"
      _AX_PATH_BDB_ENV_GET_VERSION_ok=yes
    else
      AC_MSG_RESULT([no])
    fi

    AS_VAR_POPDEF([MAJOR])dnl
    AS_VAR_POPDEF([MINOR])dnl
  fi

  dnl # Execute ACTION-IF-FOUND / ACTION-IF-NOT-FOUND.
  if test "x$_AX_PATH_BDB_ENV_GET_VERSION_ok" = "xyes" ; then
    m4_ifvaln([$1],[$1],[:])dnl
    m4_ifvaln([$2],[else $2])dnl
  fi

]) dnl BDB_ENV_GET_VERSION

#############################################################################
