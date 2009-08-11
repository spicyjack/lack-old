#!/bin/sh

# script to create the release files for XXXX release;
# script will be run from the top level project directory

# program locations
CAT=$(which cat)
SED=$(which sed)

OUTPUT_DIR="/tmp"
INPUT_DIR="etcfiles"
# any files in this list get enumerated over and the substitutions below are
# performed on them

### create the initramfs filelist
# FIXME this is hardcoded; BAD BAD BAD
cat template_base.txt \
    $BUILD_BASE/builds/template/kernel_configs/linux-image-$1.txt \
    > initramfs-template.txt

### create the hostname file
echo "template" > $OUTPUT_DIR/hostname.template
