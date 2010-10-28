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
#STATIC_TARGET=$INSTALL_PREFIX/stow/$NAME$VER
echo "Creating links from ${INSTALL_PREFIX}/${NAME}${VER}"
STATIC_TARGET=$INSTALL_PREFIX/$NAME$VER
# target cross-compilation install directory
CROSS_TARGET=$INSTALL_PREFIX/cross

test "${STATIC_TARGET%$CROSS}" = "$STATIC_TARGET" && { 
    echo 'Wrong $CROSS in '"$0"; exit 1; 
}

mkdir -p $CROSS_TARGET/$CROSS/bin
mkdir -p $CROSS_TARGET/$CROSS/lib
# Don't want to deal with pairs of usr/bin/ and bin/, usr/lib/ and lib/
# in /usr/cross/$CROSS. This seems to be the easiest fix:
ln -s . $CROSS_TARGET/$CROSS/usr

# Do we really want to install tclsh8.4 and wish8.4 though? What are those btw?
link_samename_strip     /usr/bin                "$STATIC_TARGET/bin/*"
link_samename_strip     $CROSS_TARGET/$CROSS/bin   "$STATIC_TARGET/$CROSS/bin/*"
# elf2flt.ld and ldscripts/*. Actually seems to work just fine
# without ldscripts/* symlinked, but elf2flt does insist.
link_samename           $CROSS_TARGET/$CROSS/lib   "$STATIC_TARGET/$CROSS/lib/*"

