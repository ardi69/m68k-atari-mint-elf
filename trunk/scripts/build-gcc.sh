#!/bin/sh
#---------------------------------------------------------------------------------
# Check Parameters
#---------------------------------------------------------------------------------

prefix=$INSTALLDIR/devkitMINT

PLATFORM=`uname -s`

case $PLATFORM in
  Darwin )	
    cflags="-mmacosx-version-min=10.4 -isysroot /Developer/SDKs/MacOSX10.4u.sdk -arch i386 -arch ppc"
    ldflags="-mmacosx-version-min=10.4 -arch i386 -arch ppc -Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk"
    ;;
  MINGW32* )
    cflags="-D__USE_MINGW_ACCESS"
# horrid hack to get -flto to work on windows
    plugin_ld="--with-plugin-ld=ld"
    ;;
esac

# breaks windows restriction sed -i
function sed_i {
  if [ ! -f $2.backup ]; then
	 cp $2 $2.backup
  fi
  sed "$1" $2 > $2.seded && rm $2 && mv $2.seded $2
}

#---------------------------------------------------------------------------------
# build and install binutils
#---------------------------------------------------------------------------------

mkdir -p $target/binutils
cd $target/binutils

if [ ! -f configured-binutils ]
then
  CFLAGS=$cflags LDFLAGS=$ldflags ../../$BINUTILS_SRCDIR/configure \
        --prefix=$prefix --target=$target --disable-nls --disable-dependency-tracking --disable-werror \
        || { echo "Error configuring binutils"; exit 1; }
  touch configured-binutils
fi

if [ ! -f built-binutils ]
then
  $MAKE || { echo "Error building binutils"; exit 1; }
  touch built-binutils
fi

if [ ! -f installed-binutils ]
then
  $MAKE install || { echo "Error installing binutils"; exit 1; }
  touch installed-binutils
fi


#---------------------------------------------------------------------------------
# install extra-files
#---------------------------------------------------------------------------------
cd $BUILDSCRIPTDIR

if [ ! -f installed-extra-files ]
then
  cp -vr extra-files/* $INSTALLDIR || { echo "Error installing extar-files"; exit 1; }
  touch installed-extra-files
fi


#---------------------------------------------------------------------------------
# build and install just the c compiler
#---------------------------------------------------------------------------------
mkdir -p $target/gcc
cd $target/gcc


if [ ! -f configured-gcc ]
then
  CFLAGS="$cflags" LDFLAGS="$ldflags -static" CFLAGS_FOR_TARGET="-O2 -fomit-frame-pointer" LDFLAGS_FOR_TARGET="" \
        ../../$GCC_SRCDIR/configure \
        --enable-languages=c,c++,objc \
        --enable-interwork --enable-multilib\
        --with-gcc --with-gnu-ld --with-gnu-as \
        --disable-dependency-tracking \
        --disable-shared --disable-threads --disable-win32-registry --disable-nls --disable-debug\
        --disable-libssp --disable-libgomp \
        --disable-libstdcxx-pch \
        --disable-initfini-array \
        --target=$target \
        --prefix=$prefix\
        --enable-lto $plugin_ld\
        --with-bugurl="http://code.google.com/p/m68k-atari-mint-elf/issues/list" --with-pkgversion="devkitMINT release 1" \
        || { echo "Error configuring gcc"; exit 1; }
  touch configured-gcc
fi

if [ ! -f built-gcc-stage1 ]
then
  $MAKE all-gcc || { echo "Error building gcc stage1"; exit 1; }
  touch built-gcc-stage1
fi

if [ ! -f installed-gcc-stage1 ]
then
  $MAKE install-gcc || { echo "Error installing gcc"; exit 1; }
  touch installed-gcc-stage1
#  rm -fr $INSTALLDIR/devkitMINT/$target/sys-include
fi

unset CFLAGS
cd $BUILDSCRIPTDIR
if [ 0 -ne 0 ]
then

mkdir -p $target/newlib
cd $target/newlib
NEWLIB_SRCDIR=newlib-1.20.0
if [ ! -f configured-newlib ]
then
 CFLAGS_FOR_TARGET="-DREENTRANT_SYSCALLS_PROVIDED -D__DEFAULT_UTF8__ -O2" ../../$NEWLIB_SRCDIR/configure \
        --disable-newlib-supplied-syscalls \
        --enable-newlib-mb \
        --enable-newlib-io-long-long \
        --target=$target \
        --prefix=$prefix \
        || { echo "Error configuring newlib"; exit 1; }
  touch configured-newlib
fi
exit;
if [ ! -f built-newlib ]
then
  $MAKE || { echo "Error building newlib"; exit 1; }
  touch built-newlib
fi

fi
#---------------------------------------------------------------------------------
# build and install mintlib
#---------------------------------------------------------------------------------
cd $BUILDSCRIPTDIR/$MINTLIB_SRCDIR
if [ ! -f installed-mintlib ]
then
  $MAKE CFLAGS="-O2" CROSS=yes MINTLIB_INSTALLDIR=$INSTALLDIR/devkitMINT/$target install || { echo "Error building mintlib"; exit 1; }
  touch installed-mintlib
fi

#---------------------------------------------------------------------------------
# build and install libcmini
#---------------------------------------------------------------------------------
cd $BUILDSCRIPTDIR/libcmini
if [ ! -f build-libcmini ]
then
  $MAKE MINTLIB_COMAPTIBLE=Y TESTS="" DEVKITMINT="" || { echo "Error building libcmini"; exit 1; }
  touch build-libcmini
fi

if [ ! -f installed-libcmini ]
then
  for f in . m68020-60 m5475; do
    cp -v $f/libcmini.a $INSTALLDIR/devkitMINT/$target/lib/$f/
    cp -v $f/mshort/libcmini.a $INSTALLDIR/devkitMINT/$target/lib/$f/mshort/
    # because mintlib no more supports -mshort we use libcmini as libc
    cp -v $f/mshort/libcmini.a $INSTALLDIR/devkitMINT/$target/lib/$f/mshort/libc.a

    cp -v $f/libiiomini.a $INSTALLDIR/devkitMINT/$target/lib/$f/
    cp -v $f/mshort/libiiomini.a $INSTALLDIR/devkitMINT/$target/lib/$f/mshort/
  done
  touch installed-libcmini
fi


#---------------------------------------------------------------------------------
# build and install portable math lib
#---------------------------------------------------------------------------------
cd $BUILDSCRIPTDIR/$PMLLIB_SRCDIR/pmlsrc

PMLINSTALL_DIR=$INSTALLDIR/devkitMINT/$target

if [ ! -f installed-pml ]
then
  if [ ! -f built-pml-68000 ]
  then
    sed_i "s:^\(CROSSDIR =\).*:\1 $PMLINSTALL_DIR:g" Makefile
    sed_i "s:^\(CROSSDIR =\).*:\1 $PMLINSTALL_DIR:g" Makefile.32
    sed_i "s:^\(CROSSDIR =\).*:\1 $PMLINSTALL_DIR:g" Makefile.16
    sed_i "s:^\(CC =\).*:\1 m68k-atari-mint-gcc:g" Makefile
    sed_i "s:^\(CC =\).*:\1 m68k-atari-mint-gcc:g" Makefile.32
    sed_i "s:^\(CC =\).*:\1 m68k-atari-mint-gcc:g" Makefile.16
    sed_i "s:^\(AR =\).*:\1 m68k-atari-mint-ar:g" Makefile
    sed_i "s:^\(AR =\).*:\1 m68k-atari-mint-ar:g" Makefile.32
    sed_i "s:^\(AR =\).*:\1 m68k-atari-mint-ar:g" Makefile.16

    # 1st pass for compiling m68000 libraries
    $MAKE WITH_SHORT_LIBS=1 clean
    sed_i "s: -m68020-60\| -mcpu=5475::g" Makefile.32
    sed_i "s: -m68020-60\| -mcpu=5475::g" Makefile.16
    sed_i "s:/m68020-60\|/m5475::g" Makefile
    $MAKE WITH_SHORT_LIBS=1 || { echo "Error building pml for m68000"; exit 1; }
    $MAKE install CROSSDIR=$PMLINSTALL_DIR WITH_SHORT_LIBS=1 || { echo "Error installing pml for m68000"; exit 1; }
    touch built-pml-68000
  fi
  if [ ! -f built-pml-68020 ]
  then
    # 2nd pass for compiling m68020-60 libraries
    $MAKE WITH_SHORT_LIBS=1 clean
    sed_i "s: -m68020-60\| -mcpu=5475::g" Makefile.32
    sed_i "s: -m68020-60\| -mcpu=5475::g" Makefile.16
    sed_i "s:/m68020-60\|/m5475::g" Makefile
    sed_i "s:^\(CFLAGS =.*\):\1 -m68020-60:g" Makefile.32
    sed_i "s:^\(CFLAGS =.*\):\1 -m68020-60:g" Makefile.16
    sed_i "s:^\(CROSSLIB =.*\):\1/m68020-60:g" Makefile
    $MAKE WITH_SHORT_LIBS=1 || { echo "Error building pml for m68020-60"; exit 1; }
    $MAKE install CROSSDIR=$PMLINSTALL_DIR WITH_SHORT_LIBS=1 || { echo "Error installing pml for m68020-60"; exit 1; }
    touch built-pml-68020
  fi
  if [ ! -f built-pml-m5475 ]
  then
    # 3rd pass for compiling ColdFire V4e libraries
    $MAKE WITH_SHORT_LIBS=1 clean
    sed_i "s: -m68020-60\| -mcpu=5475::g" Makefile.32
    sed_i "s: -m68020-60\| -mcpu=5475::g" Makefile.16
    sed_i "s:/m68020-60\|/m5475::g" Makefile
    sed_i "s:^\(CFLAGS =.*\):\1 -mcpu=5475:g" Makefile.32
    sed_i "s:^\(CFLAGS =.*\):\1 -mcpu=5475:g" Makefile.16
    sed_i "s:^\(CROSSLIB =.*\):\1/m5475:g" Makefile
    $MAKE WITH_SHORT_LIBS=1 || { echo "Error building pml for ColdFire V4e"; exit 1; }
    $MAKE install CROSSDIR=$PMLINSTALL_DIR WITH_SHORT_LIBS=1 || { echo "Error installing pml for ColdFire V4e"; exit 1; }
    touch built-pml-m5475
  fi
  touch installed-pml
fi

#---------------------------------------------------------------------------------
# build and install gemlib
#---------------------------------------------------------------------------------

cd $BUILDSCRIPTDIR/$GEMLIB_SRCDIR/gemlib

GEMLIBINSTALL_DIR=$INSTALLDIR/devkitMINT/$target

if [ ! -f installed-gemlib ]
then
  sed_i "s:^#CROSS = yes$:CROSS = yes:g" ../CONFIGVARS
  sed_i "s:^CROSS = no$:#CROSS = no:g" ../CONFIGVARS
  sed_i "s:^WITH_020_LIB =.*$:WITH_020_LIB = yes:g" ../CONFIGVARS
  sed_i "s:^WITH_V4E_LIB =.*$:WITH_V4E_LIB = yes:g" ../CONFIGVARS
  sed_i "s:^PREFIX=/usr/m68k-atari-mint$:PREFIX=$GEMLIBINSTALL_DIR:g" ../CONFIGVARS

  # hotfix
  sed_i "s:mt_event_mouse:mt_evnt_mouse:g" gem.h

  $MAKE install || { echo "Error building gemlib"; exit 1; }
  touch installed-gemlib
fi

#---------------------------------------------------------------------------------
# build and install the final compiler
#---------------------------------------------------------------------------------

cd $BUILDSCRIPTDIR/$target/gcc

if [ ! -f built-gcc-stage2 ]
then
  $MAKE all || { echo "Error building gcc stage2"; exit 1; }
  touch built-gcc-stage2
fi

if [ ! -f installed-gcc-stage2 ]
then
  $MAKE install || { echo "Error installing gcc stage2"; exit 1; }
  touch installed-gcc-stage2
fi

#---------------------------------------------------------------------------------
# build and install tools
#---------------------------------------------------------------------------------

cd $BUILDSCRIPTDIR/tools

if [ ! -f installed-tostool ]
then
  gcc -O2 -Wall -v tostool.c -o $prefix/bin/tostool.exe || { echo "Error installing tostool"; exit 1; }
  touch installed-tostool
fi

if [ ! -f installed-bin2s ]
then
  gcc -O2 -Wall -v bin2s.c -o $prefix/bin/bin2s.exe || { echo "Error installing bin2s"; exit 1; }
  touch installed-bin2s
fi

if [ ! -f installed-crt0_slb ]
then
  $prefix/bin/$target-gcc -v -c crt0.slb.s -o $prefix/$target/lib/crt0.slb.o || { echo "Error installing crt0.slb.o"; exit 1; }
  touch installed-crt0_slb
fi

#---------------------------------------------------------------------------------
# build and install the debugger
#---------------------------------------------------------------------------------
#exit;
mkdir -p $target/gdb
cd $target/gdb

PLATFORM=`uname -s`
if [ 0 -ne 0 ]
then
if [ ! -f configured-gdb ]
then
  CFLAGS="$cflags" LDFLAGS="$ldflags" ../../$GDB_SRCDIR/configure \
  --disable-nls --prefix=$prefix --target=$target --disable-werror \
  --disable-dependency-tracking \
  || { echo "Error configuring gdb"; exit 1; }
  touch configured-gdb
fi

if [ ! -f built-gdb ]
then
  $MAKE || { echo "Error building gdb"; exit 1; }
  touch built-gdb
fi

if [ ! -f installed-gdb ]
then
  $MAKE install || { echo "Error installing gdb"; exit 1; }
  touch installed-gdb
fi
fi
