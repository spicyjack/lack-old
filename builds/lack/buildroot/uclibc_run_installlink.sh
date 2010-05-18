#!/bin/sh
. ./installink.sh

NAME=`basename "$PWD"`
VER=-`echo $NAME | cut -d '-' -f 2-99`
NAME=`echo $NAME | cut -d '-' -f 1`
INSTALL_PREFIX="/home/cross"
# install prefix
if [ -z $INSTALL_PREFIX ]; then
    echo "ERROR: missing INSTALL_PREFIX environment variable"
    exit 1
fi
# target install directory
STATIC_TARGET=$INSTALL_PREFIX/stow/$NAME
# target cross-compilation install directory
CROSS_TARGET=$INSTALL_PREFIX/cross
CROSS=`echo $NAME$VER | cut -d- -f3-99`
ARCH=`echo $NAME$VER | cut -d- -f3 | sed -e 's/i.86/i386/'`

mkdir -p $CROSS_TARGET/$CROSS/lib
mkdir -p $CROSS_TARGET/$CROSS/include
# symlink libs
link_samename $CROSS_TARGET/$CROSS/lib     "$STATIC_TARGET/$ARCH/usr/lib/*"
# symlink includes
link_samename $CROSS_TARGET/$CROSS/include "$STATIC_TARGET/$ARCH/usr/include/*"
