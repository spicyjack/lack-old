#!/bin/sh
# run from inside the .obj-i486-linux-uclibc inside the binutils source dir
# install prefix
if [ -z $INSTALL_PREFIX ]; then
    echo "ERROR: missing INSTALL_PREFIX environment variable"
    exit 1
fi
SRC=..
CROSS=`basename "$PWD"`
CROSS="${CROSS#.obj-}"
NAME=`cd $SRC;pwd`
# the full name of the install directory
NAME=`basename "$NAME"`-$CROSS

# target install directory
STATIC_TARGET=$INSTALL_PREFIX/$NAME
# target cross-compilation install directory
CROSS_TARGET=$INSTALL_PREFIX/cross

time sudo make \
prefix=$STATIC_TARGET                          \
exec-prefix=$STATIC_TARGET                     \
bindir=$STATIC_TARGET/bin                      \
sbindir=$STATIC_TARGET/sbin                    \
libexecdir=$STATIC_TARGET/libexec              \
datadir=$STATIC_TARGET/share                   \
sysconfdir=$STATIC_TARGET/var_template/etc     \
sharedstatedir=$STATIC_TARGET/var_template/com \
localstatedir=$STATIC_TARGET/var_template      \
libdir=$STATIC_TARGET/lib                      \
includedir=$STATIC_TARGET/include              \
infodir=$STATIC_TARGET/info                    \
mandir=$STATIC_TARGET/man                      \
install 2>&1 | tee -a "$0.log"

