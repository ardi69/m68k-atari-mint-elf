#!/bin/bash
#---------------------------------------------------------------------------------
# Build script for
#	devkitMINT release 1
#---------------------------------------------------------------------------------
REMAKE=0

if [ 1 -eq 1 ] ; then
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

GCC_VER=4.8.2
BINUTILS_VER=2.24
NEWLIB_VER=1.20.0
MINTLIB_VER="CVS20120301"
PMLLIB_VER="2.03"
GEMLIB_VER="CVS-20130415"
GDB_VER=7.4

package=devkitMINT
builddir=m68k-atari-mint
target=m68k-atari-mint
toolchain=DEVKITMINT

GCC="gcc-$GCC_VER.tar.bz2"

GCC_URL="$DEVKITMINT_URL/$GCC"

BINUTILS="binutils-$BINUTILS_VER.tar.bz2"
BINUTILS_URL="$DEVKITMINT_URL/$BINUTILS"
GDB="gdb-$GDB_VER.tar.bz2"
GDB_URL="$DEVKITMINT_URL/$GDB"

MINTLIB="mintlib-src-$MINTLIB_VER.tar.bz2"
MINTLIB_URL="$DEVKITMINT_URL/$MINTLIB"

PMLLIB="pml-$PMLLIB_VER.tar.bz2"
PMLLIB_URL="$DEVKITMINT_URL/$PMLLIB"

GEMLIB="gemlib-CVS-20130415.tar.bz2"
GEMLIB_URL="http://vincent.riviere.free.fr/soft/m68k-atari-mint/archives/gemlib-CVS-20130415.tar.bz2"

DOWNLOAD=0

if [ ! -z "$BUILD_DKMINT_DOWNLOAD" ] ; then
	DOWNLOAD="$BUILD_DKMINT_DOWNLOAD"
fi

if [ -f downloaded_sources ] ; then
	DOWNLOAD=1
fi

while [ $DOWNLOAD -eq 0 ]
do
  echo
  echo "The installation requires binutils-$BINUTILS_VER, gcc-$GCC_VER, mintlib-$MINTLIB_VER, PML-$PMLLIB_VER, GEMlib-$GEMLIB_VER and gdb-$GDB_VER.  Please select an option:"
  echo
  echo "1: I have already downloaded the source packages"
  echo "2: Download the packages for me (requires curl or wget)"
  read DOWNLOAD

  if [ "$DOWNLOAD" -ne 1 -a "$DOWNLOAD" -ne 2 ]
  then
      DOWNLOAD=0
  fi
done

if [ "$DOWNLOAD" -eq 2 ]; then
  if test "`curl -V`"; then
    FETCH="curl -f -L -O"
  elif test "`wget -V`"; then
    FETCH=wget
  else
    echo "ERROR: Please make sure you have wget or curl installed."
    exit 1
  fi
fi


#---------------------------------------------------------------------------------
# Get preferred installation directory and set paths to the sources
#---------------------------------------------------------------------------------

if [ ! -z "$BUILD_DKMINT_INSTALLDIR" ] ; then
	INSTALLDIR="$BUILD_DKMINT_INSTALLDIR"
else
	echo
	echo "Please enter the directory where you would like '$package' to be installed:"
	echo "for mingw/msys you must use <drive>:/<install path> or you will have include path problems"
	echo "this is the top level directory for devkitpro, i.e. e:/devkitPro"

	read INSTALLDIR
	echo
fi

[ ! -z "$INSTALLDIR" ] && mkdir -p $INSTALLDIR && touch $INSTALLDIR/nonexistantfile && rm $INSTALLDIR/nonexistantfile || exit 1;

if [ $DOWNLOAD -eq 1 ]
then
    FOUND=0
    while [ $FOUND -eq 0 ]
	  do
	  if [ ! -z "$BUILD_DKMINT_SRCDIR" ] ; then
		  SRCDIR="$BUILD_DKMINT_SRCDIR"
	  else
		  echo
		  echo "Please enter the path to the directory that contains the source packages:"
		  read SRCDIR
	  fi

      if [ ! -f $SRCDIR/$BINUTILS ]
      then
	    echo "Error: $BINUTILS not found in $SRCDIR"
	    exit 1
      else
	    FOUND=1
      fi

      if [ ! -f $SRCDIR/$GCC ]
      then
        echo "Error: $GCC not found in $SRCDIR"
        exit 1
      else
	      FOUND=1
      fi

      if [ ! -f $SRCDIR/$MINTLIB ]
      then
        echo "Error: $MINTLIB not found in $SRCDIR"
        exit 1
      else
	      FOUND=1
      fi

      if [ ! -f $SRCDIR/$PMLLIB ]
      then
        echo "Error: $PMLLIB not found in $SRCDIR"
        exit 1
      else
	      FOUND=1
      fi

      if [ ! -f $SRCDIR/$GEMLIB ]
      then
        echo "Error: $GEMLIB not found in $SRCDIR"
        exit 1
      else
	      FOUND=1
      fi

 #     if [ ! -f $SRCDIR/$NEWLIB ]
 #     then
 #       echo "Error: $NEWLIB not found in $SRCDIR"
 #       exit 1
 #     else
 #       FOUND=1
 #     fi

#      if [ ! -f $SRCDIR/$GDB ]
#      then
#        echo "Error: $GDB not found in $SRCDIR"
#	    exit 1
#     else
#        FOUND=1
#      fi
    done

else

    if [ ! -f downloaded_sources ]
    then
			TEMP_DIR=`pwd`
	  	if [ ! -z "$BUILD_DKMINT_SRCDIR" ] && mkdir -p $BUILD_DKMINT_SRCDIR ; then
      	cd $BUILD_DKMINT_SRCDIR
			fi
      $FETCH $BINUTILS_URL || { echo "Error: Failed to download "$BINUTILS; exit 1; }

      $FETCH $GCC_URL || { echo "Error: Failed to download "$GCC; exit 1; }

      $FETCH $GDB_URL || { echo "Error: Failed to download "$GDB; exit 1; }

      $FETCH $MINTLIB_URL || { echo "Error: Failed to download "$MINTLIB; exit 1; }

      $FETCH $PMLLIB_URL || { echo "Error: Failed to download "$PMLLIB; exit 1; }

      $FETCH $GEMLIB_URL || { echo "Error: Failed to download "$GEMLIB; exit 1; }

      SRCDIR=`pwd`
      cd $TEMP_DIR
      unset TEMP_DIR

      touch downloaded_sources
    fi
fi

BINUTILS_SRCDIR="binutils-$BINUTILS_VER"
GCC_SRCDIR="gcc-$GCC_VER"
MINTLIB_SRCDIR="mintlib-$MINTLIB_VER"
PMLLIB_SRCDIR="pml-$PMLLIB_VER"
GEMLIB_SRCDIR="gemlib-$GEMLIB_VER"
GDB_SRCDIR="gdb-$GDB_VER"


#---------------------------------------------------------------------------------
# find proper make
#---------------------------------------------------------------------------------
if [ -z "$MAKE" -a -x "$(which gnumake)" ]; then MAKE=$(which gnumake); fi
if [ -z "$MAKE" -a -x "$(which gmake)" ]; then MAKE=$(which gmake); fi
if [ -z "$MAKE" -a -x "$(which make)" ]; then MAKE=$(which make); fi
if [ -z "$MAKE" ]; then
  echo no make found
  exit 1
fi
echo use $MAKE as make
export MAKE

  
#---------------------------------------------------------------------------------
# find proper gawk
#---------------------------------------------------------------------------------
if [ -z "$GAWK" -a -x "$(which gawk)" ]; then GAWK=$(which gawk); fi
if [ -z "$GAWK" -a -x "$(which awk)" ]; then GAWK=$(which awk); fi
if [ -z "$GAWK" ]; then
  echo no awk found
  exit 1
fi
echo use $GAWK as gawk
export GAWK

#---------------------------------------------------------------------------------
# find makeinfo, needed for newlib
#---------------------------------------------------------------------------------
if [ ! -x $(which makeinfo) ]; then
  echo makeinfo not found
  exit 1
fi

#---------------------------------------------------------------------------------
# Add installed devkit to the path, adjusting path on minsys
#---------------------------------------------------------------------------------
TOOLPATH=$(echo $INSTALLDIR | sed -e 's/^\([a-zA-Z]\):/\/\1/')
export PATH=$PATH:$TOOLPATH/$package/bin

if [ "$BUILD_DKMINT_AUTOMATED" != "1" ] ; then

	echo
	echo 'Ready to install '$package' in '$INSTALLDIR
	echo
	echo 'press return to continue'

	read dummy
fi

patchdir=$(pwd)/patches
scriptdir=$(pwd)/scripts

#---------------------------------------------------------------------------------
# Extract source packages
#---------------------------------------------------------------------------------

BUILDSCRIPTDIR=$(pwd)

if [ $REMAKE -eq 1 ]
then
	rm -r $SRCDIR/$MINTLIB_SRCDIR
	echo "Extracting $MINTLIB"
	tar -xjf $SRCDIR/$MINTLIB || { echo "Error extracting "$BINUTILS; exit 1; }
fi

if [ ! -f extracted_archives ]
then
  echo "Extracting $BINUTILS"
  tar -xjf $SRCDIR/$BINUTILS || { echo "Error extracting "$BINUTILS; exit 1; }

  echo "Extracting $GCC"
  tar -xjf $SRCDIR/$GCC || { echo "Error extracting "$GCC; exit 1; }

  echo "Extracting $MINTLIB"
  tar -xjf $SRCDIR/$MINTLIB || { echo "Error extracting "$MINTLIB; exit 1; }

  echo "Extracting $PMLLIB"
  tar -xjf $SRCDIR/$PMLLIB || { echo "Error extracting "$PMLLIB; exit 1; }

  echo "Extracting $GEMLIB"
  tar -xjf $SRCDIR/$GEMLIB || { echo "Error extracting "$GEMLIB; exit 1; }

  touch extracted_archives

fi

#---------------------------------------------------------------------------------
# apply patches
#---------------------------------------------------------------------------------

if [ ! -f patched_sources ]
then

  if [ -f $patchdir/binutils-$BINUTILS_VER.patch ]
  then
    patch -p1 -d $BINUTILS_SRCDIR -i $patchdir/binutils-$BINUTILS_VER.patch || { echo "Error patching binutils"; exit 1; }
  fi

  if [ -f $patchdir/gcc-$GCC_VER.patch ]
  then
    patch -p1 -d $GCC_SRCDIR -i $patchdir/gcc-$GCC_VER.patch || { echo "Error patching gcc"; exit 1; }
  fi

  if [ -f $patchdir/mintlib-$MINTLIB_VER.patch ]
  then
    patch -p0 -d $MINTLIB_SRCDIR -i $patchdir/mintlib-$MINTLIB_VER.patch || { echo "Error patching mintlib"; exit 1; }
  fi

  if [ -f $patchdir/pml-$PMLLIB_VER.patch ]
  then
    patch -p1 -d $PMLLIB_SRCDIR -i $patchdir/pml-$PMLLIB_VER.patch || { echo "Error patching portable math lib"; exit 1; }
  fi

#  if [ -f $patchdir/gdb-$GDB_VER.patch ]
#  then
#    patch -p1 -d $GDB_SRCDIR -i $patchdir/gdb-$GDB_VER.patch || { echo "Error patching gdb"; exit 1; }
#  fi

  touch patched_sources
fi

#---------------------------------------------------------------------------------
# Build and install devkit components
#---------------------------------------------------------------------------------
if [ -f $scriptdir/build-gcc.sh ]; then . $scriptdir/build-gcc.sh || { echo "Error building toolchain"; exit 1; }; cd $BUILDSCRIPTDIR; fi
exit;
if [ -f $scriptdir/build-crtls.sh ]; then . $scriptdir/build-crtls.sh || { echo "Error building crtls"; exit 1; }; cd $BUILDSCRIPTDIR; fi
if [ -f $scriptdir/build-tools.sh ]; then . $scriptdir/build-tools.sh || { echo "Error building tools"; exit 1; }; cd $BUILDSCRIPTDIR; fi

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
