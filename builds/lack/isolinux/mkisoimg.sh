#!/bin/sh

# script for making an ISO filesystem, for CD burning

VERSION="2009.7"
OUTPUT_DIR=/opt/sourcecode/ISO_Projects/
INPUT_DIR=$OUTPUT_DIR/lack
RELEASE_DATE=$(/bin/date "+%d%b%Y-%H.%M.%S")
BANNER="/tmp/lack.banner.txt"

if [ ! -e $BANNER ]; then
    echo "ERROR: file ${BANNER} not found!"
    exit 1
fi
cat $BANNER | sed "{ s!:RELEASE_VER:!${VERSION} ${RELEASE_DATE}!g; }" \
    > $INPUT_DIR/isolinux/banner.txt

MKISOFS=$(which mkisofs)

$MKISOFS -f -r -J -v \
-A "LACK CD Tester - ${RELEASE_DATE}" \
-publisher "http://code.google.com/p/lack" \
-p "Brian Manning" \
-V "LACK-$VERSION" \
-c isolinux/boot.cat \
-b isolinux/isolinux.bin \
-no-emul-boot -boot-load-size 4 -boot-info-table \
-o lack.$VERSION.x86.iso \
$INPUT_DIR
