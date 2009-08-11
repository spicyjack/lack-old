#!/bin/sh
CROSS=`basename "$PWD" | cut -d- -f3-99`
# install prefix
if [ -z $INSTALL_PREFIX ]; then
    echo "ERROR: missing INSTALL_PREFIX environment variable"
    exit 1
fi
# target install directory
STATIC_TARGET=$INSTALL_PREFIX/stow/$NAME
INSTALL_PREFIX=/usr/local
# target install directory
STATIC_TARGET=$INSTALL_PREFIX/stow/$NAME
# target cross-compilation install directory
CROSS_TARGET=$INSTALL_PREFIX/cross

# "The directory that should contain system headers does not exist:
# # /usr/cross/foobar/usr/include"
mkdir -p $CROSS_TARGET/$CROSS/usr/include

time make "$@" 2>&1 | tee -a "$0.log"
