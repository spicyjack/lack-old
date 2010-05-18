#!/bin/sh
. ./installink.sh

NAME=`basename "$PWD"`
VER=-`echo $NAME | cut -d '-' -f 2-99`
NAME=`echo $NAME | cut -d '-' -f 1`
CROSS=`basename $PWD | cut -d '-' -f 3-99`
INSTALL_PREFIX="/home/cross"
# install prefix
if [ -z $INSTALL_PREFIX ]; then
    echo "ERROR: missing INSTALL_PREFIX environment variable"
    exit 1
fi
# target install directory
STATIC_TARGET=$INSTALL_PREFIX/stow/$NAME$VER
# target cross-compilation install directory
CROSS_TARGET=$INSTALL_PREFIX/cross

test "${STATIC_TARGET%$CROSS}" = "$STATIC_TARGET" && { 
    echo 'Wrong $CROSS in '"$0"; exit 1; 
}

# Strip executables anywhere in the tree
# grep guards against matching files like *.o, *.so* etc
strip `find -perm +111 -type f | grep '/[a-z0-9]*$' | xargs`
# symlink binaries
link_samename_strip /usr/bin                "$STATIC_TARGET/bin/*"
# symlink libs
link_samename /opt/cross/$CROSS/lib         "$STATIC_TARGET/$CROSS/lib/*"
# symlink includes
link_samename /opt/cross/$CROSS/include/c++ "$STATIC_TARGET/$CROSS/include/c++/*"
