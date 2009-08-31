#!/bin/sh

# script to create the release files for a antlinux release
# script will be run from the top level 'antlinux' directory

# program locations
CAT=$(which cat)
SED=$(which sed)

OUTPUT_DIR="/tmp"
INPUT_DIR="isolinux"
# any files in this list get enumerated over and the substitutions below are
# performed on them
INPUT_FILES="banner.txt"

### create the initramfs filelist
if [ -e antlinux_base.txt -a -e ./kernel_configs/linux-image-$1.txt ]; then
    cat antlinux_base.txt ./kernel_configs/linux-image-$1.txt \
        > initramfs-filelist.txt
fi

### create the hostname file
echo "antlinux" > $OUTPUT_DIR/hostname.antlinux

### create the issue file
RELEASE_DATE=$(/bin/date "+%d%b%Y-%H.%M.%S"  | tr -d '\n')

# now build the file with the correct substitutions performed
#for SEDFILE in $(echo $INPUT_FILES);
#do
#    if [ ! -e $INPUT_DIR/$SEDFILE ]; then
#        echo "ERROR: file $INPUT_DIR/$SEDFILE not found!"
#        exit 1
#    fi
#    $CAT $INPUT_DIR/$SEDFILE \
#        | $SED "{
#            s!:RELEASE_DATE:!${RELEASE_DATE}!g; 
#            }" \
#    > $OUTPUT_DIR/$SEDFILE
#done

