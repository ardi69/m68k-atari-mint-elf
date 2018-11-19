#!/bin/bash

{ { { {

#---------------------------------------------------------------------------------
# Build script for
#	devkitMINT release 1
#---------------------------------------------------------------------------------
REMAKE=0

if [ 1 -eq 0 ] ; then
  echo "Currently in release cycle, proceed with caution, do not report problems, do not ask for support."
  echo "Please use the latest release buildscripts unless advised otherwise by devkitPro staff."
  echo "http://sourceforge.net/projects/devkitpro/files/buildscripts/"
  echo
  echo "The scripts in svn are quite often dependent on things which currently only exist on developer"
  echo "machines. This is not a bug, use stable releases."
  exit 1
fi


#---------------------------------------------------------------------------------
# specify some urls to download the source packages from
#---------------------------------------------------------------------------------

DEVKITMINT_URL="http://m68k-atari-mint-elf.googlecode.com/files"

#---------------------------------------------------------------------------------
# Sane defaults for building toolchain
#---------------------------------------------------------------------------------
export CFLAGS="-O2 -pipe"
export CXXFLAGS="$CFLAGS"
[ -z $LIBRARY_PATH ] && export LIBRARY_PATH=/usr/lib || export LIBRARY_PATH=/usr/lib:$LIBRARY_PATH
unset LDFLAGS

#---------------------------------------------------------------------------------
# Look for automated configuration file to bypass prompts
#---------------------------------------------------------------------------------

echo -n "Looking for configuration file... "
if [ -f ./config.sh ]; then
  echo "Found."
  . ./config.sh
else
  echo "Not found"
fi


#---------------------------------------------------------------------------------
# Ask whether to download the source packages or not
#---------------------------------------------------------------------------------


package=devkitMINT
rootdir=$(pwd)
downloaddir=$(pwd)/downloads
srcdir=$(pwd)/src
patchdir=$(pwd)/patches
scriptdir=$(pwd)/scripts
builddir=$(pwd)/build




target=m68k-atari-mint
toolchain=DEVKITMINT


BINUTILS_VER=2.30
BINUTILS_ARC="binutils-$BINUTILS_VER.tar.gz"
BINUTILS_URL="https://ftp.gnu.org/gnu/binutils/$BINUTILS_ARC"
BINUTILS_SRC="binutils-$BINUTILS_VER"

GMP_VER=6.1.2
GMP_ARC=$(echo "#include <gmp.h>" | gcc -E - &> /dev/null || echo "gmp-$GMP_VER.tar.bz2")
GMP_URL="https://ftp.gnu.org/gnu/gmp/$GMP_ARC"
GMP_SRC="gmp-$GMP_VER"

MPFR_VER=4.0.1
MPFR_ARC=$(echo -e "#define __MPFR_H\n#include <mpfr.h>" | gcc -E - &> /dev/null || echo "mpfr-$MPFR_VER.tar.bz2")
MPFR_URL="https://ftp.gnu.org/gnu/mpfr/$MPFR_ARC"
MPFR_SRC="mpfr-$MPFR_VER"

MPC_VER=1.1.0
MPC_ARC=$(echo -e "#define __MPC_H\n#include <mpc.h>" | gcc -E - &> /dev/null || echo "mpc-$MPC_VER.tar.gz")
MPC_URL="https://ftp.gnu.org/gnu/mpc/$MPC_ARC"
MPC_SRC="mpc-$MPC_VER"

LIBICONV_VER=1.15
LIBICONV_ARC="libiconv-$LIBICONV_VER.tar.gz"
LIBICONV_URL="https://ftp.gnu.org/pub/gnu/libiconv/$LIBICONV_ARC"
LIBICONV_SRC="libiconv-$LIBICONV_VER"


GCC_VER=8.1.0
GCC_ARC="gcc-$GCC_VER.tar.gz"
GCC_URL="https://ftp.gnu.org/gnu/gcc/gcc-$GCC_VER/$GCC_ARC"
GCC_SRC="gcc-$GCC_VER"

#GDB_VER=7.4
#GDB_ARC="gdb-$GDB_VER.tar.bz2"
#GDB_URL=
#GDB_SRC="gdb-$GDB_VER"

MINTLIB_VER="master"
MINTLIB_ARC="mintlib-$MINTLIB_VER.tar.gz"
MINTLIB_URL="https://github.com/freemint/mintlib/archive/$MINTLIB_VER.tar.gz"
MINTLIB_SRC="mintlib-$MINTLIB_VER"

FDLIBM_VER="a159b62fc20f3ff5f1a268a4870aaf117d9c17d1"
FDLIBM_ARC="fdlibm-$FDLIBM_VER.tar.gz"
FDLIBM_URL="https://github.com/freemint/fdlibm/archive/$FDLIBM_VER.tar.gz"
FDLIBM_SRC="fdlibm-$FDLIBM_VER"

LIBCMINI_VER="0.47"
LIBCMINI_ARC="libcmini-$LIBCMINI_VER.tar.gz"
LIBCMINI_URL="https://github.com/mfro0/libcmini/archive/v$LIBCMINI_VER.tar.gz"
LIBCMINI_SRC="libcmini-$LIBCMINI_VER"

PMLLIB_VER="2.03"
PMLLIB_ARC="pml-$PMLLIB_VER.tar.bz2"
PMLLIB_URL=
PMLLIB_SRC="pml-$PMLLIB_VER"

GEMLIB_VER="b3f84206c2e05d7a589ee5d90bcf4eb1601887c2"
#GEMLIB_VER="6df3f962ff80c674443a0bc0335fc0c6a56b6598" # 0_44_0
GEMLIB_ARC="gemlib-$GEMLIB_VER.tar.gz"
GEMLIB_URL="https://github.com/freemint/lib/archive/$GEMLIB_VER.tar.gz"
GEMLIB_SRC="lib-$GEMLIB_VER"


PACKAGE_LIST="BINUTILS GMP MPFR MPC LIBICONV GCC GDB MINTLIB FDLIBM LIBCMINI GEMLIB"


#---------------------------------------------------------------------------------
# Get preferred installation directory and set paths to the sources
#---------------------------------------------------------------------------------

if [ ! -z "$BUILD_DKMINT_INSTALLDIR" ]; then
	INSTALLDIR="$BUILD_DKMINT_INSTALLDIR"
else
	while [ "x$INSTALLDIR" == "x" ]; do
		echo
		echo "Please enter the directory where you would like '$package' to be installed:"
		echo "for mingw/msys you must use <drive>:/<install path> or you will have include path problems"
		echo "this is the top level directory for devkitpro, i.e. e:/devkitPro"

		read INSTALLDIR
		echo
	done
fi


#---------------------------------------------------------------------------------
# download
#---------------------------------------------------------------------------------

function download() {
	local file=$1_ARC; file=${!file}
	local url=$1_URL; url=${!url}
	[ -z $file ] && return
	if [ ! -f $file ]; then
		[ -z $url ] && echo "no URL for $file. Download and store to `pwd`" && exit 1
		if [ -z "$FETCH" ]; then
			if [ -z "$FETCH" -a -x "$(which wget 2>/dev/null)" ]; then FETCH="$(which wget 2>/dev/null) --no-check-certificate -O"; fi
			if [ -z "$FETCH" -a -x "$(which curl 2>/dev/null)" ]; then FETCH="$(which curl 2>/dev/null) -k -f -L -o"; fi
			[ -z "$FETCH" ] && { echo "ERROR: Please make sure you have wget or curl installed."; exit 1; }
		fi
		rm -f "$file.tmp"
		echo $FETCH "$file.tmp" $url
		$FETCH "$file.tmp" $url && mv "$file.tmp" $file || { echo "Error: Failed to download $file form $url"; exit 1; }
	fi
	if [ -f $file ]; then
		echo "found $file"
	else
		echo "Error: $file not found in `pwd`"
		exit 1;
	fi
}

mkdir -p $downloaddir && cd $downloaddir || { echo "Can't go to $downloaddir"; exit 1; }

for p in $PACKAGE_LIST; do download $p; done

cd $rootdir

#---------------------------------------------------------------------------------
# find proper make
#---------------------------------------------------------------------------------
echo find make
if [ -z "$MAKE" -a -x "$(which gnumake 2>/dev/null)" ]; then MAKE=$(which gnumake); fi
if [ -z "$MAKE" -a -x "$(which gmake 2>/dev/null)" ]; then MAKE=$(which gmake); fi
if [ -z "$MAKE" -a -x "$(which make 2>/dev/null)" ]; then MAKE=$(which make); fi
if [ -z "$MAKE" ]; then
	echo no make found
	exit 1
fi
echo use $MAKE as make
export MAKE

echo find makeinfo
which makeinfo >/dev/null 2>&1 || { echo "Can't find makinfo. Please Install e.g. pacman -S texinfo"; exit 1; }
which bison >/dev/null 2>&1 || { echo "Can't find bison. Please Install e.g. pacman -S bison"; exit 1; }


#---------------------------------------------------------------------------------
# find proper gawk
#---------------------------------------------------------------------------------
if [ -z "$GAWK" -a -x "$(which gawk 2>/dev/null)" ]; then GAWK=$(which gawk); fi
if [ -z "$GAWK" -a -x "$(which awk 2>/dev/null)" ]; then GAWK=$(which awk); fi
if [ -z "$GAWK" ]; then
	echo no awk found
	exit 1
fi
echo use $GAWK as gawk
export GAWK

#---------------------------------------------------------------------------------
# Add installed devkit to the path, adjusting path on minsys
#---------------------------------------------------------------------------------
TOOLPATH=$(echo $INSTALLDIR | sed -e 's/^\([a-zA-Z]\):/\/\1/')
export PATH=$PATH:$TOOLPATH/$package/bin

if [ "$BUILD_DKMINT_AUTOMATED" != "1" ] ; then

	echo
	echo 'Ready to install '$package' in '$INSTALLDIR
	echo
	echo "ToolPath = $TOOLPATH/$package/bin"
	echo
	echo 'press return to continue'

	read dummy
fi


#---------------------------------------------------------------------------------
# extract & patch
#---------------------------------------------------------------------------------

function extract_package() {
	local arc=${1}_ARC; arc=${!arc}
	local src=${1}_SRC; src=${!src}
	local patchfile=${1}_PATCH; patchfile=${!patchfile}
	local patch
	[ -z $arc ] && return
	([ -d $src/.git ] || [ -d $src/.svn ]) && echo "found .git or .svn in $src -> extract and patch skipped" && return
	if [ ! -f $src/extracted ]; then
		echo "Extracting $arc"
		rm -fr $src
		case $arc in
		*bz2)
			tar -xjf $downloaddir/$arc || { echo "Error extracting $arc"; exit 1; }
			;;
		*gz)
			tar -xzf $downloaddir/$arc || { echo "Error extracting $arc"; exit 1; }
			;;
		*)
			echo "Error no extracting rule for $arc"
			exit 1
			;;
		esac
		[ ! -d $src ] && { echo "$arc extracted but `pwd`/$src not found"; exit 1; }
		touch $src/extracted
	fi
	if [ ! -f $src/patched ]; then
		for patch in $patchfile $patchdir/$src.p?.patch; do
			if [ -f $patch ]; then
				case $patch in
				*.p0.patch)
					echo "Patching $src"
					patch -s -p0 -d $srcdir/$src -i $patch || { echo "Error patching $src"; exit 1; }
					;;
				*.p1.patch)
					echo "Patching $src"
					patch -s -p1 -d $srcdir/$src -i $patch || { echo "Error patching $src"; exit 1; }
					;;
				*)
					echo skip $patch
					;;
				esac
			fi
		done
		touch $src/patched
	fi

}
mkdir -p $srcdir && cd $srcdir || { echo "Can't go to $srcdir"; exit 1; }
for p in $PACKAGE_LIST; do extract_package $p; done

cd $rootdir

#---------------------------------------------------------------------------------
# Build and install devkit components
#---------------------------------------------------------------------------------
if [ -f $scriptdir/build-gcc.sh ]; then . $scriptdir/build-gcc.sh || { echo "Error building toolchain"; exit 1; }; cd $rootdir; fi
exit
if [ -f $scriptdir/build-portlibs.sh ]; then . $scriptdir/build-portlibs.sh || { echo "Error building portlibs"; exit 1; }; cd $rootdir; fi
exit;
if [ -f $scriptdir/build-crtls.sh ]; then . $scriptdir/build-crtls.sh || { echo "Error building crtls"; exit 1; }; cd $rootdir; fi
if [ -f $scriptdir/build-tools.sh ]; then . $scriptdir/build-tools.sh || { echo "Error building tools"; exit 1; }; cd $rootdir; fi

#---------------------------------------------------------------------------------
# strip binaries
# strip has trouble using wildcards so do it this way instead
#---------------------------------------------------------------------------------
for f in $INSTALLDIR/$package/bin/* \
         $INSTALLDIR/$package/$target/bin/* \
         $INSTALLDIR/$package/libexec/gcc/$target/$GCC_VER/*
do
  # exclude dll for windows, so for linux/osx, directories .la files, embedspu script & the gccbug text file
  if  ! [[ "$f" == *.dll || "$f" == *.so || -d $f || "$f" == *.la || "$f" == *-embedspu || "$f" == *-gccbug ]]
  then
    strip $f
  fi
done

#---------------------------------------------------------------------------------
# strip debug info from libraries
#---------------------------------------------------------------------------------
find $INSTALLDIR/$package/lib/gcc/$target -name *.a -exec $target-strip -d {} \;
find $INSTALLDIR/$package/$target -name *.a -exec $target-strip -d {} \;

#---------------------------------------------------------------------------------
# Clean up temporary files and source directories
#---------------------------------------------------------------------------------
exit
if [ "$BUILD_DKMINT_AUTOMATED" != "1" ] ; then
  echo
  echo "Would you like to delete the build folders and patched sources? [Y/n]"
  read answer
else
  answer=y
fi

if [ "$answer" != "n" -a "$answer" != "N" ]
  then

  echo "Removing patched sources and build directories"

  rm -fr $target
  rm -fr $BINUTILS_SRCDIR
  rm -fr $NEWLIB_SRCDIR
  rm -fr $GCC_SRCDIR
  rm -fr $LIBOGC_SRCDIR $LIBGBA_SRCDIR $LIBNDS_SRCDIR $LIBMIRKO_SRCDIR $DSWIFI_SRCDIR $LIBFAT_SRCDIR $GDB_SRCDIR $DEFAULT_ARM7_SRCDIR $MAXMOD_SRCDIR $FILESYSTEM_SRCDIR
  rm -fr mn10200
  rm -fr pspsdk
  rm -fr extracted_archives patched_sources checkout-psp-sdk

fi

if [ "$BUILD_DKMINT_AUTOMATED" != "1" ] ; then
  echo
  echo "Would you like to delete the downloaded source packages? [y/N]"
  read answer
else
  answer=n
fi

if [ "$answer" = "y" -o "$answer" = "Y" ]
then
  echo "removing archives"
  rm -f $SRCDIR/$BINUTILS $SRCDIR/$GCC_CORE $SRCDIR/$GCC_GPP $SRCDIR/$NEWLIB

  if [ $VERSION -eq 1 -o $VERSION -eq 4 ]
  then
   rm -f  $SRCDIR/$LIBGBA $SRCDIR/$LIBNDS $SRCDIR/$LIBMIRKO
  fi

  if [ $VERSION -eq 2 ]
	then
	  rm -f  $SRCDIR/$LIBOGC
  fi
  rm -f downloaded_sources
fi

echo
echo "note: Add the following to your environment;  DEVKITPRO=$TOOLPATH $toolchain=$TOOLPATH/$package"
echo

} 2>&1 1>&3; } | tee build-devkit.err.log; } 3>&1; } | tee build-devkit.log
