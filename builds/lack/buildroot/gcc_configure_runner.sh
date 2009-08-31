#!/bin/sh
CROSS=`basename "$PWD" | cut -d- -f3-99`
# gcc source directory
SRC=../`basename "$PWD" .obj-$CROSS`
NAME=`cd $SRC;pwd`
NAME=`basename "$NAME" .obj-$CROSS`-$CROSS
# install prefix
if [ -z $INSTALL_PREFIX ]; then
    echo "ERROR: missing INSTALL_PREFIX environment variable"
    exit 1
fi
# target install directory
STATIC_TARGET=$INSTALL_PREFIX/stow/$NAME
# target cross-compilation install directory
CROSS_TARGET=$INSTALL_PREFIX/cross

$SRC/configure \
--prefix=$STATIC                                \
--exec-prefix=$STATIC                           \
--bindir=$STATIC/bin                            \
--sbindir=$STATIC/sbin                          \
--libexecdir=$STATIC/libexec                    \
--datadir=$STATIC/share                         \
--sysconfdir=/etc                               \
--sharedstatedir=$STATIC/var/com                \
--localstatedir=$STATIC/var                     \
--libdir=$STATIC/lib                            \
--includedir=$STATIC/include                    \
--infodir=$STATIC/info                          \
--mandir=$STATIC/man                            \
--disable-nls                                   \
--with-local-prefix=/usr/local                  \
--with-slibdir=$STATIC/lib                      \
--target=$CROSS                                 \
--with-gnu-ld                                   \
--with-ld="/usr/bin/$CROSS-ld"                  \
--with-gnu-as                                   \
--with-as="/usr/bin/$CROSS-as"                  \
--with-sysroot=$CROSS_TARGET/$CROSS                \
--enable-languages="c"                          \
--disable-shared                                \
--disable-threads                               \
--disable-tls                                   \
--disable-multilib                              \
--disable-decimal-float                         \
--disable-libgomp                               \
--disable-libssp                                \
--disable-libmudflap                            \
--without-headers                               \
--with-newlib                                   \
--with-gmp                                      \
2>&1 | tee -a "$0.log"

