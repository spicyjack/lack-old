#!/bin/sh

# script for making an ISO filesystem, for CD burning

VERSION="2009.7"
OUTPUT_DIR=/opt/sourcecode/ISO_Projects/
INPUT_DIR=$OUTPUT_DIR/blank-mbr
RELEASE_DATE=$(/bin/date "+%d%b%Y-%H.%M.%S")
BANNER="/tmp/blank-mbr.banner.txt"

if [ ! -e $BANNER ]; then
    echo "ERROR: file ${BANNER} not found!"
    exit 1
fi
cat $BANNER | sed "{ s!:RELEASE_DATE:!${VERSION} ${RELEASE_DATE}!g; }" \
    > $INPUT_DIR/isolinux/banner.txt

MKISOFS=$(which mkisofs)

$MKISOFS -f -r -J -v \
-A "Partition Table Nuker! - ${RELEASE_DATE}" \
-publisher "http://code.google.com/p/antlinux" \
-p "Brian Manning" \
-V "MBR_BLANKER-$VERSION" \
-c isolinux/boot.cat \
-b isolinux/isolinux.bin \
-no-emul-boot -boot-load-size 4 -boot-info-table \
-o blank-mbr.$VERSION.x86.iso \
$INPUT_DIR
