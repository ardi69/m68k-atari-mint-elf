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
		exe_ext=".exe"
		;;
esac

# breaks windows restriction sed -i
function sed_i {
	if [ ! -f $2.backup ]; then
		cp $2 $2.backup
	fi
	sed $1 $2 > $2.seded && mv -f $2.seded $2
}

function link_or_copy() {
	ln -f $1 $2 || cp -f $1 $2
}
function ftime() {
	stat -c %Y $1 2>/dev/null || echo 0
}

#---------------------------------------------------------------------------------
# build and install binutils
#---------------------------------------------------------------------------------

mkdir -p $builddir/binutils && cd $builddir/binutils || { echo "Can't change dir to $builddir/binutils"; exit 1; }

if [ ! -f configured-binutils ]; then
	rm -fr * # force build & install
	CFLAGS=$cflags LDFLAGS=$ldflags ../../src/$BINUTILS_SRC/configure \
		--prefix=$prefix --target=$target --disable-nls --disable-dependency-tracking --disable-werror \
		|| { echo "Error configuring binutils"; exit 1; }
	touch configured-binutils
fi

if [ ! -f build-binutils ]; then
	rm -f installed-binutils # force install
	$MAKE || { echo "Error building binutils"; exit 1; }
	touch build-binutils
fi

if [ ! -f installed-binutils ]; then
	# dev-mode on
	# when reinstall then remove all ld's, strip's and force istall ld-hijacker and strip
	for f in $prefix/bin/$target-ld* $prefix/bin/$target-strip* $prefix/$target/bin/ld* $prefix/$target/bin/strip*; do rm -f $f; done
	rm -f $rootdir/tools/installed-ld-hijacker $rootdir/tools/installed-strip
	# dev-mode off

	$MAKE install || { echo "Error installing binutils"; exit 1; }
	touch installed-binutils
fi

#---------------------------------------------------------------------------------
# install extra-files
#---------------------------------------------------------------------------------
cd $rootdir

if [ ! -f installed-extra-files ]; then
	cp -vr extra-files/* $INSTALLDIR || { echo "Error installing extar-files"; exit 1; }
	touch installed-extra-files
fi

#---------------------------------------------------------------------------------
# build and install tostool
#---------------------------------------------------------------------------------
cd $rootdir/tools

if [ ! -f installed-tostool ] || [ `ftime $prefix/bin/tostool$exe_ext` -lt `ftime tostool.c` ]; then
	echo "build tostool"
	gcc -O2 -Wall tostool.c -o $prefix/bin/tostool$exe_ext && strip $prefix/bin/tostool$exe_ext || { echo "Error building tostool"; exit 1; }
	echo "install tostool"
	link_or_copy $prefix/bin/tostool$exe_ext $prefix/bin/$target-tostool$exe_ext || { echo "Error installing $prefix/bin/$target-tostool$exe_ext"; exit 1; }
	link_or_copy $prefix/bin/tostool$exe_ext $prefix/$target/bin/tostool$exe_ext || { echo "Error installing $prefix/$target/bin/tostool$exe_ext"; exit 1; }
	touch installed-tostool
fi


#---------------------------------------------------------------------------------
# function hijack
#---------------------------------------------------------------------------------

function hijack() {
	# dev-mode on
	# when reinstall then revert all $1.elf's
	for orig in $prefix/bin/$target-$1* $prefix/$target/bin/$1*; do
		case `basename $orig` in
		*elf*);;
		*)	elf=`dirname $orig`/`basename $orig $exe_ext`.elf$exe_ext
			echo revert $elf to $orig
			if [ -f $elf ]; then mv -f $elf $orig || { echo "Error reverting $elf to $orig"; exit 1; }; fi
			;;
		esac
	done
	# dev-mode off

	link_src=
	for orig in $prefix/bin/$target-$1* $prefix/$target/bin/$1*; do
		echo hijack $orig
		elf=`dirname $orig`/`basename $orig $exe_ext`.elf$exe_ext
		mv $orig $elf || { echo "Error installing $3 (can't move $orig to $elf)"; exit 1; }
		if [ -z $link_src ]; then
			link_src=$orig
			cp $2 $orig || { echo "Error installing $3 (can't copy $2 to $orig)"; exit 1; }
		else
			link_or_copy $link_src $orig || { echo "Error installing $3 (can't link $link_src to $orig)"; exit 1; }
		fi
	done
}


#---------------------------------------------------------------------------------
# build and install ld-hijacker
#---------------------------------------------------------------------------------

cd $rootdir/tools

if [ ! -f build-ld-hijacker ] || [ `ftime ld-hijacker$exe_ext` -lt `ftime ld-hijacker.c` ]; then
	rm -f installed-ld-hijacker # force install
	echo "build ld-hijacker"
	gcc -O2 -Wall ld-hijacker.c -o ld-hijacker$exe_ext && strip ld-hijacker$exe_ext || { echo "Error building ld-hijacker"; exit 1; }
	touch build-ld-hijacker
fi

if [ ! -f installed-ld-hijacker ]; then
	hijack ld ld-hijacker$exe_ext ld-hijacker
	touch installed-ld-hijacker
fi

#---------------------------------------------------------------------------------
# build and install strip
#---------------------------------------------------------------------------------

cd $rootdir/tools

if [ ! -f build-strip-hijacker ]; then
	rm -f installed-strip-hijacker # force install
	echo "build strip-hijacker"
	echo "int main(){return 0;}" | gcc -xc -O2 -Wall -o strip-hijacker$exe_ext - && strip strip-hijacker$exe_ext || { echo "Error building strip-hijacker"; exit 1; }
	touch build-strip-hijacker
fi

if [ ! -f installed-strip-hijacker ]; then
	hijack strip strip-hijacker$exe_ext strip-hijacker
	touch installed-strip-hijacker
fi
#---------------------------------------------------------------------------------
# build and install GMP if needed
#---------------------------------------------------------------------------------

if [ -d $srcdir/$GMP_SRC ]; then

	mkdir -p $builddir/gmp && cd $builddir/gmp || { echo "Can't change dir to $builddir/gmp"; exit 1; }

	if [ ! -f configured-gmp ]; then
		rm -fr config.log libtool config.h stamp-h1 gmp.h Makefile config.status config.m4
		ABI=32 ../../src/$GMP_SRC/configure --disable-shared --prefix=$builddir/gmp || { echo "Error configuring gmp"; exit 1; }
		touch configured-gmp
	fi

	if [ ! -f build-gmp ]; then
		rm -f installed-gmp
		$MAKE || { echo "Error building gmp"; exit 1; }
		touch build-gmp
	fi

	if [ ! -f installed-gmp ]; then
		$MAKE install || { echo "Error installing gmp"; exit 1; }
		touch installed-gmp
	fi
	with_gmp="--with-gmp=$builddir/gmp"
fi

#---------------------------------------------------------------------------------
# build and install MPFR
#---------------------------------------------------------------------------------

if [ -d $srcdir/$MPFR_SRC ]; then

	mkdir -p $builddir/mpfr && cd $builddir/mpfr || { echo "Can't change dir to $builddir/mpfr"; exit 1; }

	if [ ! -f configured-mpfr ]; then
#		rm -fr config.log libtool config.h stamp-h1 gmp.h Makefile config.status config.m4
		../../src/$MPFR_SRC/configure --disable-shared --prefix=$builddir/mpfr $with_gmp || { echo "Error configuring mpfr"; exit 1; }
		touch configured-mpfr
	fi

	if [ ! -f build-mpfr ]; then
		rm -f installed-mpfr
		$MAKE || { echo "Error building mpfr"; exit 1; }
		touch build-mpfr
	fi

	if [ ! -f installed-mpfr ]; then
		$MAKE install || { echo "Error installing mpfr"; exit 1; }
		touch installed-mpfr
	fi
	with_mpfr="--with-mpfr=$builddir/mpfr"
fi

#---------------------------------------------------------------------------------
# build and install MPC
#---------------------------------------------------------------------------------

if [ -d $srcdir/$MPC_SRC ]; then

	mkdir -p $builddir/mpc && cd $builddir/mpc || { echo "Can't change dir to $builddir/mpc"; exit 1; }

	if [ ! -f configured-mpc ]; then
#		rm -fr config.log libtool config.h stamp-h1 gmp.h Makefile config.status config.m4
		../../src/$MPC_SRC/configure --disable-shared --prefix=$builddir/mpc $with_gmp $with_mpfr || { echo "Error configuring mpc"; exit 1; }
		touch configured-mpc
	fi

	if [ ! -f build-mpc ]; then
		rm -f installed-mpc
		$MAKE || { echo "Error building mpc"; exit 1; }
		touch build-mpc
	fi

	if [ ! -f installed-mpc ]; then
		$MAKE install || { echo "Error installing mpc"; exit 1; }
		touch installed-mpc
	fi
	with_mpc="--with-mpc=$builddir/mpc"
fi

#---------------------------------------------------------------------------------
# build and install just the c compiler
#---------------------------------------------------------------------------------
cd $rootdir
mkdir -p $builddir/gcc && cd $builddir/gcc || { echo "Can't change dir to $builddir/gcc"; exit 1; }

if [ ! -f configured-gcc ]; then
	rm -fr *
#	CFLAGS="$cflags" LDFLAGS="$ldflags -static" CFLAGS_FOR_TARGET="-O2" LDFLAGS_FOR_TARGET="" \
#		../../../gcc-working/configure \
	# can't use  -fomit-frame-pointer --> complile error on Coldfire with -mshort ???
	CFLAGS="$cflags" LDFLAGS="$ldflags -static" CFLAGS_FOR_TARGET="-O2" LDFLAGS_FOR_TARGET="" \
		../../src/$GCC_SRC/configure \
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
		$with_gmp \
		$with_mpfr \
		$with_mpc \
		--with-bugurl="http://code.google.com/p/m68k-atari-mint-elf/issues/list" --with-pkgversion="devkitMINT release 2" || { echo "Error configuring gcc"; exit 1; }
	touch configured-gcc
fi

if [ ! -f build-gcc-stage1 ]; then
	rm -f installed-gcc-stage1
	$MAKE all-gcc || { echo "Error building gcc stage1"; exit 1; }
	touch build-gcc-stage1
fi

if [ ! -f installed-gcc-stage1 ]; then
	$MAKE install-gcc || { echo "Error installing gcc"; exit 1; }
	touch installed-gcc-stage1
#  rm -fr $prefix/$target/sys-include
fi

# now build libgcc because needed by mintlib for building zic etc.
if [ ! -f build-libgcc ]; then
	$MAKE all-target-libgcc || { echo "Error building libgcc"; exit 1; }
	touch build-libgcc
fi
if [ ! -f installed-libgcc ]; then
	$MAKE install-target-libgcc || { echo "Error installing libgcc"; exit 1; }
	touch installed-libgcc
fi

unset CFLAGS
#---------------------------------------------------------------------------------
# build and install mintlib
#---------------------------------------------------------------------------------
cd $srcdir/$MINTLIB_SRC

if [ ! -f fixup-icludepath ]; then
	$MAKE -C lib CROSS=yes ../includepath || { echo "Error fixup includepath"; exit 1; }
	cat includepath | sed -r -e 's/\\/\//g' -e 's/^([^:]+):/\/\1/' > includepath.sed && mv -f includepath.sed includepath || { echo "Error fixup includepath"; exit 1; }
	touch fixup-icludepath
fi

if [ ! -f installed-mintlib ]; then
	$MAKE CFLAGS="-O2" CROSS=yes prefix=$prefix/$target install || { echo "Error building mintlib"; exit 1; }
	touch installed-mintlib
fi

#---------------------------------------------------------------------------------
# build and install libcmini
#---------------------------------------------------------------------------------

if [ 1 -eq 0 ]; then
cd $rootdir/libcmini
if [ ! -f build-libcmini ]; then
	$MAKE MINTLIB_COMAPTIBLE=Y TESTS="" DEVKITMINT="" || { echo "Error building libcmini"; exit 1; }
	touch build-libcmini
fi

if [ ! -f installed-libcmini ]; then
	for f in . m68020-60 m5475; do
		cp -v $f/libcmini.a $prefix/$target/lib/$f/
		cp -v $f/mshort/libcmini.a $prefix/$target/lib/$f/mshort/
		# because mintlib no more supports -mshort we use libcmini as libc
		cp -v $f/mshort/libcmini.a $prefix/$target/lib/$f/mshort/libc.a

		cp -v $f/libiiomini.a $prefix/$target/lib/$f/
		cp -v $f/mshort/libiiomini.a $prefix/$target/lib/$f/mshort/
	done
	touch installed-libcmini
fi
fi

#---------------------------------------------------------------------------------
# build and install portable math lib
#---------------------------------------------------------------------------------
cd $srcdir/$PMLLIB_SRC/pmlsrc


if [ ! -f installed-pml ]; then
	PMLINSTALL_DIR=$prefix/$target
	if [ ! -f built-pml-68000 ]; then
		$MAKE WITH_SHORT_LIBS=1 clean
		$MAKE WITH_SHORT_LIBS=1 CROSSDIR=$PMLINSTALL_DIR AR=$target-ar CC=$target-gcc install || { echo "Error installing pml for m68000"; exit 1; }
		touch built-pml-68000
	fi

	if [ ! -f built-pml-68020 ]; then
		$MAKE WITH_SHORT_LIBS=1 clean
		$MAKE WITH_SHORT_LIBS=1 CROSSDIR=$PMLINSTALL_DIR AR=$target-ar CC=$target-gcc CPU="-m68020-60" CROSSLIB=$PMLINSTALL_DIR/lib/m68020-60 install || { echo "Error installing pml for m68020-60"; exit 1; }
		touch built-pml-68020
	fi
	if [ ! -f built-pml-m5475 ]; then
		$MAKE WITH_SHORT_LIBS=1 clean
		$MAKE WITH_SHORT_LIBS=1 CROSSDIR=$PMLINSTALL_DIR AR=$target-ar CC=$target-gcc CPU="-mcpu=5475" CROSSLIB=$PMLINSTALL_DIR/lib/m5475 install || { echo "Error installing pml for ColdFire V4e"; exit 1; }
		touch built-pml-m5475
	fi
	touch installed-pml
fi

if [ 0 -ne 0 ]; then
	cd $rootdir
	mkdir -p $builddir/fdlibm && cd $builddir/fdlibm || { echo "Can't change dir to $builddir/fdlibm"; exit 1; }

# RANLIB=m68k-atari-mint-ranlib CC=m68k-atari-mint-gcc AR=m68k-atari-mint-ar ../../src/$FDLIBM_SRC/configure --prefix=$prefix/$target
#

fi

#---------------------------------------------------------------------------------
# build and install gemlib
#---------------------------------------------------------------------------------

cd $srcdir/$GEMLIB_SRC

GEMLIBINSTALL_DIR=$prefix/$target

if [ ! -f installed-gemlib ]; then
	# hotfix
	sed_i "s:mt_event_mouse:mt_evnt_mouse:g" gemlib/gem.h

	$MAKE OPTS="-O2" CROSS=yes PREFIX=$prefix/$target install || { echo "Error building gemlib"; exit 1; }
	touch installed-gemlib
fi

#---------------------------------------------------------------------------------
# build and install the final compiler
#---------------------------------------------------------------------------------

cd $builddir/gcc

if [ ! -f build-gcc-stage2 ]; then
	rm -v installed-gcc-stage2 # force install
	$MAKE all || { echo "Error building gcc stage2"; exit 1; }
	touch build-gcc-stage2
fi

if [ ! -f installed-gcc-stage2 ]
then
	$MAKE install || { echo "Error installing gcc stage2"; exit 1; }
	touch installed-gcc-stage2
fi

#---------------------------------------------------------------------------------
# build and install tools
#---------------------------------------------------------------------------------

cd $rootdir/tools

if [ ! -f installed-bin2s ]; then
	cmd="gcc -O2 -Wall bin2s.c -o $prefix/bin/bin2s.exe"
	echo $cmd
	$cmd || { echo "Error installing bin2s"; exit 1; }
	touch installed-bin2s
fi

if [ ! -f installed-crt0_slb ]; then
	cmd="$target-gcc -c crt0.slb.s -o $prefix/$target/lib/crt0.slb.o"
	echo $cmd
	$cmd || { echo "Error installing crt0.slb.o"; exit 1; }
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
