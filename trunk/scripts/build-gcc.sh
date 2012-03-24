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
cd $BUILDSCRIPTDIR

#---------------------------------------------------------------------------------
# included zlib has issues with multilib toolchain
#---------------------------------------------------------------------------------
rm -fr $GCC_SRCDIR/zlib

#---------------------------------------------------------------------------------
# build and install just the c compiler
#---------------------------------------------------------------------------------
mkdir -p $target/gcc
cd $target/gcc


if [ ! -f configured-gcc ]
then
#  cp -r $BUILDSCRIPTDIR/$NEWLIB_SRCDIR/newlib/libc/include $INSTALLDIR/devkitMINT/$target/sys-include
#        --disable-libmudflap
  CFLAGS="$cflags" LDFLAGS="$ldflags" CFLAGS_FOR_TARGET="-O2" LDFLAGS_FOR_TARGET="" ../../$GCC_SRCDIR/configure \
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
        --with-bugurl="http://wiki.devkitpro.org/index.php/Bug_Reports" --with-pkgversion="devkitMINT release 1" \
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
cd $target/../$MINTLIB_SRCDIR
if [ ! -f built-mintlib ]
then
  $MAKE CROSS=yes MINTLIB_INSTALLDIR=$INSTALLDIR/devkitMINT/$target install || { echo "Error building mintlib"; exit 1; }
  touch built-mintlib
fi

#---------------------------------------------------------------------------------
# build and install portable math lib
#---------------------------------------------------------------------------------
cd $BUILDSCRIPTDIR
#mkdir -p $target/pml
#echo $target/../$PMLLIB_SRCDIR/pmlsrc
cd $target/../$PMLLIB_SRCDIR/pmlsrc

#PMLINSTALL_DIR=$BUILDSCRIPTDIR/$target/pml
PMLINSTALL_DIR=$INSTALLDIR/devkitMINT/$target

if [ ! -f built-pml ]
then
  sed -i "s:^\(CROSSDIR =\).*:\1 $PMLINSTALL_DIR:g" Makefile Makefile.32 Makefile.16
  sed -i "s:^\(CC =\).*:\1 m68k-atari-mint-gcc:g" Makefile Makefile.32 Makefile.16
  sed -i "s:^\(AR =\).*:\1 m68k-atari-mint-ar:g" Makefile Makefile.32 Makefile.16
  sed -i "s:^\(CFLAGS =.*\):\1 -Wa,--register-prefix-optional:g" Makefile.32 Makefile.16

  # 1st pass for compiling m68000 libraries
	$MAKE WITH_SHORT_LIBS=1
	$MAKE install CROSSDIR=$PMLINSTALL_DIR WITH_SHORT_LIBS=1

  # 2nd pass for compiling m68020-60 libraries
  $MAKE clean
  sed -i "s:^\(CFLAGS =.*\):\1 -m68020-60:g" Makefile.32 Makefile.16
  sed -i "s:^\(CROSSLIB =.*\):\1/m68020-60:g" Makefile
  $MAKE WITH_SHORT_LIBS=1
	$MAKE install CROSSDIR=$PMLINSTALL_DIR WITH_SHORT_LIBS=1

  # 3rd pass for compiling ColdFire V4e libraries
  $MAKE clean
  sed -i "s:-m68020-60:-mcpu=5475:g" Makefile.32 Makefile.16
  sed -i "s:m68020-60:m5475:g" Makefile
  $MAKE WITH_SHORT_LIBS=1
	$MAKE install CROSSDIR=$PMLINSTALL_DIR WITH_SHORT_LIBS=1

#  $MAKE CROSS=yes MINTLIB_INSTALLDIR=$INSTALLDIR/devkitMINT/$target install || { echo "Error building mintlib"; exit 1; }
  touch built-pml
fi

#---------------------------------------------------------------------------------
# build and install the final compiler
#---------------------------------------------------------------------------------

cd $BUILDSCRIPTDIR
cd $target/gcc

if [ ! -f built-gcc-stage2 ]
then
  $MAKE || { echo "Error building gcc stage2"; exit 1; }
  touch built-gcc-stage2
fi

if [ ! -f installed-gcc-stage2 ]
then
  $MAKE install || { echo "Error installing gcc stage2"; exit 1; }
  touch installed-gcc-stage2
fi
exit;
cd $BUILDSCRIPTDIR

#---------------------------------------------------------------------------------
# build and install the debugger
#---------------------------------------------------------------------------------
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
