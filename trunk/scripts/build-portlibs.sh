

ZLIB="zlib-1.2.8.tar.gz"
ZLIB_SRCDIR="zlib-1.2.8"
LIBPNG="libpng-1.6.9.tar.gz"
LIBPNG_SRCDIR="libpng-1.6.9"
LIBFREETYPE="freetype-2.5.3.tar.bz2"
LIBFREETYPE_SRCDIR="freetype-2.5.3"



mkdir -p $BUILDSCRIPTDIR/portlibs
portlibs=$BUILDSCRIPTDIR/portlibs


#---------------------------------------------------------------------------------
# build and install zlib
#---------------------------------------------------------------------------------

cd $portlibs
if [ ! -f extracted_zlib ]
then
  echo "Extracting $ZLIB"
  tar -xzf $SRCDIR/$ZLIB || { echo "Error extracting "$ZLIB; exit 1; }
  touch extracted_zlib
fi

cd $portlibs/$ZLIB_SRCDIR

function install_zlib {

if [ ! -f ../install-zlib$3 ]
then
  CFLAGS="-fomit-frame-pointer -O3 $2" CHOST=m68k-atari-mint ./configure --static || { echo "Error configuring zlib"; exit 1; }
  $MAKE libz.a || { echo "Error make zlib"; exit 1; }
  $target-ranlib libz.a
  (cp -uv zlib.h $INSTALLDIR/libmint/include/ && cp -uv zconf.h $INSTALLDIR/libmint/include/zconf.h && \
               mkdir -p $INSTALLDIR/libmint/lib/$1 && cp -v libz.a $INSTALLDIR/libmint/lib/$1/) || { echo "Error installing zlib"; exit 1; }
  touch ../install-zlib$3
fi
}
install_zlib .
#install_zlib mshort -mshort -mshort
install_zlib m68020-60 -m68020-60 -m68020-60
#install_zlib m68020-60/mshort "-m68020-60 -mshort" -m68020-60-mshort
install_zlib m5475 -mcfv4e -m5475
#install_zlib m5475/mshort "-mcfv4e -mshort" -m5475-mshort


#---------------------------------------------------------------------------------
# build and install libpng
#---------------------------------------------------------------------------------

cd $portlibs
if [ ! -f extracted_libpng ]
then
  echo "Extracting $LIBPNG"
  tar -xzf $SRCDIR/$LIBPNG || { echo "Error extracting "$LIBPNG; exit 1; }
  touch extracted_libpng
fi

cd $portlibs/$LIBPNG_SRCDIR
if [ ! -f ../configured_libpng ]
then


  CFLAGS="-fomit-frame-pointer -O2" \
  CPPFLAGS=-I$INSTALLDIR/libmint/include \
  LDFLAGS="-L$INSTALLDIR/libmint/lib" \
  ./configure --disable-shared --enable-static --host=m68k-atari-mint --prefix=$INSTALLDIR/libmint || \
  { echo "Error configuring libpng"; exit 1; }
  touch ../configured_libpng
fi

if [ ! -f ../install_libpng ]
then
  $MAKE install || { echo "Error installing libpng"; exit 1; }
  touch ../install_libpng
fi

if [ ! -f ../install_libpng-m68020-60 ]
then
  $MAKE clean
  $MAKE LDFLAGS="-L$INSTALLDIR/libmint/lib/m68020-60" CFLAGS="-fomit-frame-pointer -O2 -m68020-60" || { echo "Error installing libpng"; exit 1; }
  target-mint-ranlib .libs/libpng16.a
  cp -v .libs/libpng16.a $INSTALLDIR/libmint/lib/m68020-60/
  cp -v .libs/libpng16.a $INSTALLDIR/libmint/lib/m68020-60/libpng.a
  touch ../install_libpng-m68020-60
fi

if [ ! -f ../install_libpng-m5475 ]
then
  $MAKE clean
  cpu="-mcpu=5475"
  $MAKE LDFLAGS="-L$INSTALLDIR/libmint/lib/m5475" CFLAGS="-fomit-frame-pointer -O2 $cpu" || { echo "Error installing libpng"; exit 1; }
  $target-ranlib .libs/libpng16.a
  cp -v .libs/libpng16.a $INSTALLDIR/libmint/lib/m5475/
  cp -v .libs/libpng16.a $INSTALLDIR/libmint/lib/m5475/libpng.a
  touch ../install_libpng-m5475
fi

#---------------------------------------------------------------------------------
# build and install freetype
#---------------------------------------------------------------------------------

if [ 11 -eq 1 ]
then

cd $BUILDSCRIPTDIR/portlibs
if [ ! -f extracted_libfreetype ]
then
  echo "Extracting $LIBFREETYPE"
  tar -xjf $SRCDIR/$LIBFREETYPE || { echo "Error extracting "$LIBFREETYPE; exit 1; }
  touch extracted_libfreetype
fi

cd $LIBFREETYPE_SRCDIR

CFLAGS="-fomit-frame-pointer -mshort" \
CPPFLAGS=-I$INSTALLDIR/libmint/include \
 LDFLAGS=-L$INSTALLDIR/libmint/lib \
./configure --disable-shared --enable-static --host=m68k-atari-mint --prefix=$INSTALLDIR/libmint || \
{ echo "Error configuring freetype"; exit 1; }

fi

