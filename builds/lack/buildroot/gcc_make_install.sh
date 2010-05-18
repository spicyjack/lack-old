#!/bin/sh
CROSS=`basename "$PWD" | cut -d- -f3-99`
SRC=../`basename "$PWD" .obj-$CROSS`
NAME=`cd $SRC;pwd`
NAME=`basename "$NAME" .obj-$CROSS`-$CROSS
INSTALL_PREFIX="/home/cross"
# install prefix
if [ -z $INSTALL_PREFIX ]; then
    echo "ERROR: missing INSTALL_PREFIX environment variable"
    echo "INSTALL_PREFIX is $INSTALL_PREFIX"
    exit 1
fi
# target install directory
STATIC_TARGET=$INSTALL_PREFIX/stow/$NAME
# target cross-compilation install directory
CROSS_TARGET=$INSTALL_PREFIX/cross

time make -k \
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
