#!/bin/sh
# run from inside the .obj-i486-linux-uclibc inside the binutils source dir
# install prefix
if [ -z $INSTALL_PREFIX ]; then
    echo "ERROR: missing INSTALL_PREFIX environment variable"
    exit 1
fi
SRC=..
# what's our current directory name?
CROSS=`basename "$PWD"`
# remove the .obj at the end
CROSS="${CROSS#.obj-}"
NAME=`cd $SRC;pwd`
# the full name of the install directory
NAME=`basename "$NAME"`-$CROSS

# target install directory
STATIC_TARGET=$INSTALL_PREFIX/$NAME
# target cross-compilation install directory
CROSS_TARGET=$INSTALL_PREFIX/cross

$SRC/configure \
--prefix=$STATIC_TARGET                        \
--exec-prefix=$STATIC_TARGET                   \
--bindir=/usr/bin                       \
--sbindir=/usr/sbin                     \
--libexecdir=$STATIC_TARGET/libexec            \
--datadir=$STATIC_TARGET/share                 \
--sysconfdir=/etc                       \
--sharedstatedir=$STATIC_TARGET/var/com        \
--localstatedir=$STATIC_TARGET/var             \
--libdir=/usr/lib                       \
--includedir=/usr/include               \
--infodir=/usr/info                     \
--mandir=/usr/man                       \
--oldincludedir=/usr/include            \
--target=$CROSS                         \
--with-sysroot=$CROSS_TARGET/$CROSS        \
--disable-rpath                         \
--disable-nls                           \
2>&1 | tee -a "$0.log"

