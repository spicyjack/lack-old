#!/bin/sh

# script to create the release files for a Propaganda release
# script will be run from the top level 'propaganda' directory

# program locations
CAT=$(which cat)
SED=$(which sed)

OUTPUT_DIR="/tmp"
INPUT_DIR="etcfiles"
# any files in this list get enumerated over and the substitutions below are
# performed on them

### create the initramfs filelist
# FIXME this is hardcoded; BAD BAD BAD
cat blank-mbr_base.txt \
    $PROJECT_DIR/kernel_configs/linux-image-$1.txt \
    > initramfs-filelist.txt

### create the hostname file
echo "blank-mbr" > $OUTPUT_DIR/hostname.blank-mbr
