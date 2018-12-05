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
	MSYS* )
		echo
		echo
		echo "ERROR wrong uname $PLATFORM"
		echo
		echo "if MSYS2 start 'msys2_shell.cmd -ming332'"
		exit
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

if [ ! -f $builddir/_binutils-configured ]; then
	rm -fr * # force build & install
	CFLAGS=$cflags LDFLAGS=$ldflags ../../src/$BINUTILS_SRC/configure \
		--prefix=$prefix --target=$target --disable-nls --disable-dependency-tracking --disable-werror \
		|| { echo "Error configuring binutils"; exit 1; }
	touch $builddir/_binutils-configured
fi

if [ ! -f $builddir/_binutils-build ]; then
	rm -f $builddir/_binutils-installed # force install
	$MAKE || { echo "Error building binutils"; exit 1; }
	touch $builddir/_binutils-build
fi

if [ ! -f $builddir/_binutils-installed ]; then
	# dev-mode on
	# when reinstall then remove all ld's, strip's and force istall ld-hijacker and strip
#	for f in $prefix/bin/$target-ld* $prefix/bin/$target-strip* $prefix/$target/bin/ld* $prefix/$target/bin/strip*; do rm -fv $f; done
	rm -fv $prefix/bin/$target-ld* $prefix/bin/$target-strip* $prefix/$target/bin/ld* $prefix/$target/bin/strip*
	rm -f $builddir/_ld-hijacker-installed $builddir/_strip-hijacker-installed
	# dev-mode off

	$MAKE install || { echo "Error installing binutils"; exit 1; }
	touch $builddir/_binutils-installed
fi

#---------------------------------------------------------------------------------
# build and install tostool
#---------------------------------------------------------------------------------
cd $rootdir/tools

if [ ! -f $builddir/_tostool-installed ] || [ `ftime $prefix/bin/tostool$exe_ext` -lt `ftime tostool.c` ]; then
	echo "build tostool"
	gcc -O2 -Wall tostool.c -o $prefix/bin/tostool$exe_ext && strip $prefix/bin/tostool$exe_ext || { echo "Error building tostool"; exit 1; }
	echo "install tostool"
	link_or_copy $prefix/bin/tostool$exe_ext $prefix/bin/$target-tostool$exe_ext || { echo "Error installing $prefix/bin/$target-tostool$exe_ext"; exit 1; }
	link_or_copy $prefix/bin/tostool$exe_ext $prefix/$target/bin/tostool$exe_ext || { echo "Error installing $prefix/$target/bin/tostool$exe_ext"; exit 1; }
	touch $builddir/_tostool-installed
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
			if [ -f $elf ]; then
				echo revert $elf to $orig
				mv -f $elf $orig || { echo "Error reverting $elf to $orig"; exit 1; }
			fi
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

if [ ! -f $builddir/_ld-hijacker-build ] || [ `ftime ld-hijacker$exe_ext` -lt `ftime ld-hijacker.c` ]; then
	rm -f $builddir/_ld-hijacker-installed # force install
	echo "build ld-hijacker"
	gcc -O2 -Wall ld-hijacker.c -o ld-hijacker$exe_ext && strip ld-hijacker$exe_ext || { echo "Error building ld-hijacker"; exit 1; }
	touch $builddir/_ld-hijacker-build
fi

if [ ! -f $builddir/_ld-hijacker-installed ]; then
	echo "install ld-hijacker"
	hijack ld ld-hijacker$exe_ext ld-hijacker
	touch $builddir/_ld-hijacker-installed
fi

#---------------------------------------------------------------------------------
# build and install strip
#---------------------------------------------------------------------------------

cd $rootdir/tools

if [ ! -f $builddir/_strip-hijacker-build ] || [ ! -f strip-hijacker$exe_ext ]; then
	rm -f $builddir/_strip-hijacker-installed # force install
	echo "build strip-hijacker"
	echo "int main(){return 0;}" | gcc -xc -O2 -Wall -o strip-hijacker$exe_ext - && strip strip-hijacker$exe_ext || { echo "Error building strip-hijacker"; exit 1; }
	touch $builddir/_strip-hijacker-build
fi

if [ ! -f $builddir/_strip-hijacker-installed ]; then
	echo "install strip-hijacker"
	hijack strip strip-hijacker$exe_ext strip-hijacker
	touch $builddir/_strip-hijacker-installed
fi
#---------------------------------------------------------------------------------
# build and install GMP
#---------------------------------------------------------------------------------

if [ -d $srcdir/$GMP_SRC ]; then

	mkdir -p $builddir/gmp && cd $builddir/gmp || { echo "Can't change dir to $builddir/gmp"; exit 1; }

	if [ ! -f $builddir/_gmp-configured ]; then
		rm -fr config.log libtool config.h stamp-h1 gmp.h Makefile config.status config.m4
		rm -f $builddir/_gmp-build
		ABI=32 ../../src/$GMP_SRC/configure --disable-shared --prefix=$builddir/gmp/gmp || { echo "Error configuring gmp"; exit 1; }
		touch $builddir/_gmp-configured
	fi

	if [ ! -f $builddir/_gmp-build ]; then
		rm -f $builddir/_gmp-installed
		$MAKE || { echo "Error building gmp"; exit 1; }
		touch $builddir/_gmp-build
	fi

	if [ ! -f $builddir/_gmp-installed ]; then
		$MAKE install || { echo "Error installing gmp"; exit 1; }
		touch $builddir/_gmp-installed
	fi
	with_gmp="--with-gmp=$builddir/gmp/gmp"
	with_gmp_prefix="--with-gmp-prefix=$builddir/gmp/gmp"
fi

#---------------------------------------------------------------------------------
# build and install MPFR
#---------------------------------------------------------------------------------

if [ -d $srcdir/$MPFR_SRC ]; then

	mkdir -p $builddir/mpfr && cd $builddir/mpfr || { echo "Can't change dir to $builddir/mpfr"; exit 1; }

	if [ ! -f $builddir/_mpfr-configured ]; then
		rm -fr config.log libtool config.h stamp-h1 gmp.h Makefile config.status config.m4
		rm -f $builddir/_mpfr-build
		../../src/$MPFR_SRC/configure --disable-shared --prefix=$builddir/mpfr/mpfr $with_gmp || { echo "Error configuring mpfr"; exit 1; }
		touch $builddir/_mpfr-configured
	fi

	if [ ! -f $builddir/_mpfr-build ]; then
		rm -f $builddir/_mpfr-installed
		$MAKE || { echo "Error building mpfr"; exit 1; }
		touch $builddir/_mpfr-build
	fi

	if [ ! -f $builddir/_mpfr-installed ]; then
		$MAKE install || { echo "Error installing mpfr"; exit 1; }
		touch $builddir/_mpfr-installed
	fi
	with_mpfr="--with-mpfr=$builddir/mpfr/mpfr"
fi

#---------------------------------------------------------------------------------
# build and install MPC
#---------------------------------------------------------------------------------

if [ -d $srcdir/$MPC_SRC ]; then

	mkdir -p $builddir/mpc && cd $builddir/mpc || { echo "Can't change dir to $builddir/mpc"; exit 1; }

	if [ ! -f $builddir/_mpc-configured ]; then
		rm -fr config.log libtool config.h stamp-h1 gmp.h Makefile config.status config.m4
		rm -f $builddir/_mpc-build
		../../src/$MPC_SRC/configure --disable-shared --prefix=$builddir/mpc/mpc $with_gmp $with_mpfr || { echo "Error configuring mpc"; exit 1; }
		touch $builddir/_mpc-configured
	fi

	if [ ! -f $builddir/_mpc-build ]; then
		rm -f $builddir/_mpc-installed
		$MAKE || { echo "Error building mpc"; exit 1; }
		touch $builddir/_mpc-build
	fi

	if [ ! -f $builddir/_mpc-installed ]; then
		$MAKE install || { echo "Error installing mpc"; exit 1; }
		touch $builddir/_mpc-installed
	fi
	with_mpc="--with-mpc=$builddir/mpc/mpc"
fi

#---------------------------------------------------------------------------------
# build and install ISL
#---------------------------------------------------------------------------------

if [ -d $srcdir/$ISL_SRC ]; then

	mkdir -p $builddir/isl && cd $builddir/isl || { echo "Can't change dir to $builddir/isl"; exit 1; }

	if [ ! -f $builddir/_isl-configured ]; then
		rm -fr config.log libtool config.h stamp-h1 gmp.h Makefile config.status config.m4
		tm -f $builddir/_isl_build
		../../src/$ISL_SRC/configure --disable-shared --enable-static $with_gmp_prefix --prefix=$builddir/isl/isl || { echo "Error configuring isl"; exit 1; }
		touch $builddir/_isl-configured
	fi

	if [ ! -f $builddir/_isl-build ]; then
		rm -f $builddir/_isl-installed
		$MAKE || { echo "Error building isl"; exit 1; }
		touch $builddir/_isl-build
	fi

	if [ ! -f $builddir/_isl-installed ]; then
		$MAKE install || { echo "Error installing isl"; exit 1; }
		touch $builddir/_isl-installed
	fi
	with_isl="--with-isl=$builddir/isl/isl"
fi


#---------------------------------------------------------------------------------
# build and install ICONV
#---------------------------------------------------------------------------------

if [ -d $srcdir/$ICONV_SRC ]; then

	mkdir -p $builddir/iconv && cd $builddir/iconv || { echo "Can't change dir to $builddir/iconv"; exit 1; }

	if [ ! -f $builddir/_iconv-configured ]; then
		rm -fr config.log libtool config.h stamp-h1 gmp.h Makefile config.status config.m4
		rm -f $builddir/_iconv_build
		../../src/$ICONV_SRC/configure --disable-shared --enable-static --enable-extra-encodings --prefix=$builddir/iconv/iconv || { echo "Error configuring iconf"; exit 1; }
		touch $builddir/_iconv-configured
	fi

	if [ ! -f $builddir/_iconv-build ]; then
		rm -f $builddir/_iconv-installed
		$MAKE || { echo "Error building iconv"; exit 1; }
		touch $builddir/_iconv-build
	fi

	if [ ! -f $builddir/_iconv-installed ]; then
		$MAKE install || { echo "Error installing libiconv"; exit 1; }
		touch $builddir/_iconv-installed
	fi
	with_libiconv_prefix="--with-libiconv-prefix=$builddir/iconv/iconv"
fi

#---------------------------------------------------------------------------------
# create sysroot dirs
#---------------------------------------------------------------------------------
sysroot_includes="usr/include"
sysroot_libs="lib usr/lib"
sysroot_dir="$prefix/$target/../sysroot"

if [ ! -f $builddir/_sysroot-dirs-created ]; then
	echo "create sysroot dirs"
	for p in $sysroot_includes $sysroot_libs; do
		echo "mkdir -p $sysroot_dir/$p"
		mkdir -p $sysroot_dir/$p || { echo "Error can't create dir $sysroot_dir/$p"; exit 1; }
	done
	touch $builddir/_sysroot-dirs-created
fi
#---------------------------------------------------------------------------------
# build and install just the c compiler
#---------------------------------------------------------------------------------
cd $rootdir
mkdir -p $builddir/gcc && cd $builddir/gcc || { echo "Can't change dir to $builddir/gcc"; exit 1; }

if [ ! -f $builddir/_gcc-configured ]; then
	rm -fr *
	rm -f $builddir/_gcc-stage1-build
	#LDFLAGS="$ldflags -static -static-libgcc -static-libstdc++"
	#	--disable-shared --enable-linker-plugin-configure-flags=--enable-shared \
	CFLAGS="$cflags" CFLAGS_FOR_TARGET="-g -O2 -fomit-frame-pointer" CXXFLAGS_FOR_TARGET="-g -O2 -fomit-frame-pointer -ffunction-sections -fdata-sections" LDFLAGS_FOR_TARGET="" \
		../../src/$GCC_SRC/configure \
		--enable-languages=c,c++,objc \
		--enable-interwork --enable-multilib \
		--with-sysroot=$sysroot_dir \
		--with-gcc --with-gnu-ld --with-gnu-as \
		--disable-dependency-tracking \
		--enable-threads=posix --disable-win32-registry --disable-nls --disable-debug \
		--disable-libssp --disable-libgomp \
		--disable-libstdcxx-pch \
		--disable-initfini-array \
		--target=$target \
		--prefix=$prefix \
		--enable-lto \
		$with_gmp \
		$with_mpfr \
		$with_mpc \
		$with_isl \
		$with_libiconv_prefix \
		--with-bugurl="http://code.google.com/p/m68k-atari-mint-elf/issues/list" --with-pkgversion="devkitMINT by ardi release 3" || { echo "Error configuring gcc"; exit 1; }
	touch $builddir/_gcc-configured
fi

# configure stage 1
if [ ! -f $builddir/_gcc-stage1-configure ]; then
	rm -f $builddir/_gcc-stage1-build
	$MAKE configure-gcc || { echo "Error configuring gcc stage1"; exit 1; }
	touch $builddir/_gcc-stage1-configure
fi

# build stage 1
if [ ! -f $builddir/_gcc-stage1-build ]; then
	rm -f $builddir/_gcc-stage1-installed
#	touch ../../src/$GCC_SRC/gcc/genmultilib
	cd gcc
	# rm -f s-mlib multilib.h
	# build and patch multilib.h
	$MAKE multilib.h
	sed -E -i \
		-e "s:^\"\. (.*) \!msoft-float( .*):\"m68000 \1\2:" \
		-e "s:^\"(mshort|fastcall)(.*) \!msoft-float( .*):\"m68000/\1\2\3:" \
		-e "s:^\"mshort (.*):\"m68000 \1\"m68000/mshort \1:" \
		-e "s:^\"m68000 ([^;]*) mshort:\"m68000 \1 \!mshort:" \
		-e "s:^\"(fastcall.*):\"m68000/\1:" \
		multilib.h
	cd ..
	$MAKE all-gcc || { echo "Error building gcc stage1"; exit 1; }
# temporary disabled - always buld gcc
	touch $builddir/_gcc-stage1-build
fi


if [ ! -f $builddir/_gcc-stage1-installed ]; then
	$MAKE install-gcc || { echo "Error installing gcc"; exit 1; }
	touch $builddir/_gcc-stage1-installed
#  rm -fr $prefix/$target/sys-include
fi

if [ ! -f $builddir/_gcc-liblto_plugin-for-binutils-installed ]; then
	dlpath=$prefix/libexec/gcc/$target/`$target-gcc -dumpversion`
	dlname=`cat $dlpath/liblto_plugin.la | grep dlname | sed -E -e "s:^.*='(.*)'.*:\1:"`
	[ -f $dlpath/$dlname ] || { echo "Error $dlpath/$dlname not found"; exit 1; }
	mkdir -p $prefix/$target/lib/bfd-plugins || { echo "Error can't create dir $prefix/$target/lib/bfd-plugins"; exit 1; }
	link_or_copy $dlpath/$dlname $prefix/$target/lib/bfd-plugins || { echo "Error installing $dlname in $prefix/$target/lib/bfd-plugins"; exit 1; }
	mkdir -p $prefix/lib/bfd-plugins || { echo "Error can't create dir $prefix/lib/bfd-plugins"; exit 1; }
	link_or_copy $dlpath/$dlname $prefix/lib/bfd-plugins || { echo "Error installing $dlname in $prefix/lib/bfd-plugins"; exit 1; }
	touch $builddir/_gcc-liblto_plugin-for-binutils-installed
fi

#---------------------------------------------------------------------------------
# create multilib dirs
#---------------------------------------------------------------------------------
if [ ! -f $builddir/_multilib-dirs-created ]; then
	echo "create multilib dirs"
	for ml in `$prefix/bin/$target-gcc -print-multi-lib | sed -e "s/;.*$//"`; do
		echo "mkdir -p $prefix/$target/lib/$ml"
		mkdir -p $prefix/$target/lib/$ml || { echo "Error can't create dir $prefix/$target/lib/$ml"; exit 1; }
		for p in $sysroot_libs; do
			echo "mkdir -p $sysroot_dir/$p/$ml"
			mkdir -p $sysroot_dir/$p/$ml || { echo "Error can't create dir $sysroot_dir/$p/$ml"; exit 1; }
		done
	done
	touch $builddir/_multilib-dirs-created
fi
#---------------------------------------------------------------------------------
# install crt0 & faket libc
# for configuring libgcc crt0 and libc is needed
# but vor building mintlib aka libc -> libgcc is needed
# we build crt0 and a faked libc
#---------------------------------------------------------------------------------

if [ 0 -eq 1 ]; then

echo "create & install crt0"
	for ml in `$prefix/bin/$target-gcc -print-multi-lib`; do
		ml_path=`echo $ml | sed -e "s/;.*$//"`
		ml_opt=`echo $ml | sed -e "s/^.*;//" | sed -e "s/@/ -/g"`
		CMD1="$prefix/bin/$target-gcc $ml_opt -c $srcdir/$MINTLIB_SRC/startup/crt0.S -o $prefix/$target/lib/$ml_path/crt0.o"
		CMD2="$prefix/bin/$target-gcc $ml_opt -c $srcdir/$MINTLIB_SRC/startup/crt0.S -o $prefix/$target/lib/$ml_path/gcrt0.o"
		echo "$CMD1 && $CMD2"
		$CMD1 && $CMD2 || { echo "Error installing crt0.o for $ml_opt"; exit 1; }
	done

fi

#---------------------------------------------------------------------------------
# install mintlib header
#---------------------------------------------------------------------------------
cd $srcdir/$MINTLIB_SRC || { echo "Can't change dir to $srcdir/$MINTLIB_SRC"; exit 1; }

if [ ! -f $builddir/_mintlib-header-installed ]; then
	echo "install mintlib header files"
	$MAKE CROSS=yes prefix=$prefix/$target install-include-recursive || { echo "Error Can't install mintlib header"; exit 1; }
	cd include
	$MAKE CROSS=yes prefix=$prefix/$target install-include-recursive || { echo "Error Can't install mintlib header"; exit 1; }
	touch $builddir/_mintlib-header-installed
fi


#---------------------------------------------------------------------------------
# install extra-files  pthread.h needed by libgcc
#---------------------------------------------------------------------------------
cd $rootdir

if [ ! -f $builddir/_extra-files-installed ]; then
	echo "install extra-files"
	cp -vr extra-files/* $INSTALLDIR || { echo "Error installing extar-files"; exit 1; }
	touch $builddir/_extra-files-installed
fi


#---------------------------------------------------------------------------------
# now build libgcc because needed by mintlib for building zic etc.
#---------------------------------------------------------------------------------

cd $builddir/gcc || { echo "Can't change dir to $builddir/gcc"; exit 1; }

if [ ! -f $builddir/_libgcc-build ]; then
	rm -f $builddir/_libgcc-installed
	$MAKE all-target-libgcc || { echo "Error building libgcc"; exit 1; }
	touch $builddir/_libgcc-build
fi
if [ ! -f $builddir/_libgcc-installed ]; then
	$MAKE install-target-libgcc || { echo "Error installing libgcc"; exit 1; }
	touch $builddir/_libgcc-installed
fi

unset CFLAGS
#---------------------------------------------------------------------------------
# build and install mintlib
#---------------------------------------------------------------------------------
if [ 0 -eq 1 ]; then # temporary disabled

cd $srcdir/$MINTLIB_SRC

if [ ! -f includepath ]; then
	$MAKE -C lib CROSS=yes ../includepath || { echo "Error fixup includepath"; exit 1; }
	cat includepath | sed -r -e 's/\\/\//g' -e 's/^([^:]+):/\/\1/' > includepath.sed && mv -f includepath.sed includepath || { echo "Error fixup includepath"; exit 1; }
fi

if [ ! -f _mintlib-build ]; then
	$MAKE CFLAGS="-O2 -std=gnu89 -fomit-frame-pointer -ffunction-sections -fdata-sections -Wno-nonnull-compare" CROSS=yes prefix=$prefix/$target || { echo "Error building mintlib"; exit 1; }
	touch _mintlib-build
fi

if [ ! -f _mintlib-installed ]; then
	$MAKE CFLAGS="-O2" CROSS=yes prefix=$prefix/$target install || { echo "Error building mintlib"; exit 1; }
	touch _mintlib-installed
fi

if [ ! -f _crt0-mcpu-5475-installed ]; then
# we can't link m68k object files with coldfire object files
# we need an extra crt0.c for coldfire
	echo "install crt0.o for mcpu=5475"
	$target-gcc -c startup/crt0.S -mcpu=5475 -o $prefix/$target/lib/m5475/crt0.o && $target-gcc -mcpu=5475 -DGCRT0 -c startup/crt0.S -o $prefix/$target/lib/m5475/gcrt0.o || { echo "Error installing crt0.o for mcpu=5475"; exit 1; }
	touch _crt0-mcpu-5475-installed
fi

fi

#---------------------------------------------------------------------------------
# build and install libcmini
#---------------------------------------------------------------------------------

cd $srcdir/libcmini
if [ ! -f $builddir/_libcmini-build ]; then
	rm -f $builddir/_libcmini-installed
	$MAKE STDIO_WITH_LONG_LONG=yes TESTS="" CFLAGS="-Wall -O2 -fomit-frame-pointer -flto -ffat-lto-objects" PREFIX_FOR_LIB=$prefix/$target/lib PREFIX_FOR_INCLUDE=$prefix/$target/include/libcmini || { echo "Error building libcmini"; exit 1; }
	touch $builddir/_libcmini-build
fi

if [ ! -f $builddir/_libcmini-installed ]; then
	$MAKE STDIO_WITH_LONG_LONG=yes TESTS="" INSTALLDIR_FOR_LIB=$prefix/$target/lib INSTALLDIR_FOR_INCLUDE=$prefix/$target/include/libcmini || { echo "Error building libcmini"; exit 1; }
#	for f in . m68020-60 m5475; do
#		cp -v $f/libcmini.a $prefix/$target/lib/$f/
#		cp -v $f/mshort/libcmini.a $prefix/$target/lib/$f/mshort/
#		# because mintlib no more supports -mshort we use libcmini as libc
#		cp -v $f/mshort/libcmini.a $prefix/$target/lib/$f/mshort/libc.a

#		cp -v $f/libiiomini.a $prefix/$target/lib/$f/
#		cp -v $f/mshort/libiiomini.a $prefix/$target/lib/$f/mshort/
#	done
	touch $builddir/_libcmini-installed
fi
exit;

#---------------------------------------------------------------------------------
# build and install portable math lib
#---------------------------------------------------------------------------------
if [ 1 -eq 0 ]; then
cd $srcdir/$PMLLIB_SRC/pmlsrc


if [ ! -f _pml-installed ]; then
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
	touch _pml-installed
fi
fi


#---------------------------------------------------------------------------------
# build and install fdlibm
#---------------------------------------------------------------------------------
cd $srcdir/$FDLIBM_SRC || { echo "Can't change dir to $srcdir/$FDLIBM_SRC"; exit 1; }
if [ ! -f _fdlibm-build ]; then
	CC=m68k-atari-mint-gcc AR=m68k-atari-mint-ar RANLIB=m68k-atari-mint-ranlib ./configure --prefix=$prefix/$target || { echo "Can't configure fdlibm"; exit 1; }
	$MAKE CROSS=yes || { echo "Can't build fdlibm"; exit 1; }
	touch _fdlibm-build
fi
if [ ! -f _fdlibm-installed ]; then
	$MAKE install || { echo "Can't install fdlibm"; exit 1; }
	touch _fdlibm-installed
fi

#---------------------------------------------------------------------------------
# build and install gemlib
#---------------------------------------------------------------------------------

cd $srcdir/$GEMLIB_SRC

GEMLIBINSTALL_DIR=$prefix/$target

if [ ! -f _gemlib-installed ]; then
	# hotfix
	sed_i "s:mt_event_mouse:mt_evnt_mouse:g" gemlib/gem.h

	$MAKE OPTS="-O2 -fomit-frame-pointer" WARN="-Wall -Wextra -Wno-strict-aliasing" CROSS=yes PREFIX=$prefix/$target install || { echo "Error building gemlib"; exit 1; }
	touch _gemlib-installed
fi

#---------------------------------------------------------------------------------
# build and install the final compiler
#---------------------------------------------------------------------------------

cd $builddir/gcc

if [ ! -f _gcc-stage2-build ]; then
	rm -f _gcc-stage2-installed # force install
	$MAKE all || { echo "Error building gcc stage2"; exit 1; }
	touch _gcc-stage2-build
fi

if [ ! -f _gcc-stage2-installed ]; then
	$MAKE install || { echo "Error installing gcc stage2"; exit 1; }
	touch _gcc-stage2-installed
fi

#---------------------------------------------------------------------------------
# build and install tools
#---------------------------------------------------------------------------------

cd $rootdir/tools

if [ ! -f _bin2s-installed ]; then
	cmd="gcc -O2 -Wall bin2s.c -o $prefix/bin/bin2s.exe"
	echo $cmd
	$cmd || { echo "Error installing bin2s"; exit 1; }
	touch _bin2s-installed
fi
exit

if [ ! -f _crt0_slb-installed ]; then
	echo "install crt0.slb.o"
	$target-gcc -c crt0.slb.s -o $prefix/$target/lib/crt0.slb.o && $target-gcc -mcpu=5475 -c crt0.slb.s -o $prefix/$target/lib/m5475/crt0.slb.o || { echo "Error installing crt0.slb.o"; exit 1; }
	touch _crt0_slb-installed
fi

#---------------------------------------------------------------------------------
# build and install the debugger
#---------------------------------------------------------------------------------
exit;
mkdir -p $target/gdb
cd $target/gdb

PLATFORM=`uname -s`
if [ 0 -ne 0 ]
then
if [ ! -f _gdb-configured ]
then
  CFLAGS="$cflags" LDFLAGS="$ldflags" ../../$GDB_SRCDIR/configure \
  --disable-nls --prefix=$prefix --target=$target --disable-werror \
  --disable-dependency-tracking \
  || { echo "Error configuring gdb"; exit 1; }
  touch _gdb-configured
fi

if [ ! -f built-gdb ]
then
  $MAKE || { echo "Error building gdb"; exit 1; }
  touch built-gdb
fi

if [ ! -f _gdb-installed ]
then
  $MAKE install || { echo "Error installing gdb"; exit 1; }
  touch _gdb-installed
fi
fi
