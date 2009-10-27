#!/bin/sh

# script to create the release files for XXXX release;
# script will be run from the top level project directory

# program locations
CAT=$(which cat)
SED=$(which sed)

OUTPUT_DIR="/tmp"
# any files in this list get enumerated over and the substitutions below are
# performed on them
INPUT_FILES="issue.${PROJECT_NAME}"

# verify the base file exists
if [ ! -e $PROJECT_DIR/${PROJECT_NAME}.base.txt ]; then
    echo "ERROR: ${PROJECT_DIR}/${PROJECT_NAME}.base.txt file does not exist"
    exit 1
fi # if [ $PROJECT_DIR/${PROJECT_NAME}.base.txt ]

### create the initramfs filelist
if [ -e $PROJECT_DIR/kernel_configs/linux-image-$1.txt ]; then
    cat $PROJECT_DIR/${PROJECT_NAME}.base.txt \
        $PROJECT_DIR/kernel_configs/linux-image-$1.txt \
        > $PROJECT_DIR/initramfs-filelist.txt
else
    echo "make_release_files.sh: linux-image-$1.txt file does not exist"
    echo "make_release_files.sh: in ${PROJECT_DIR}/kernel_configs directory"
    exit 1
fi

### create the hostname file
echo "${PROJECT_NAME}" > $OUTPUT_DIR/hostname.${PROJECT_NAME}

# build the file with the correct substitutions performed
# below variables are set in the initramfs.cfg file
for SEDFILE in $(echo $INPUT_FILES);
do
    $CAT $PROJECT_DIR/etcfiles/$SEDFILE \
        | $SED "{
            s!:KERNEL_VER:!${KERNEL_VER}!g;
            s!:RELEASE_VER:!${RELEASE_VER}!g;
            s!:DEMO_PASS:!${DEMO_PASS}!g;
            }" \
    > $OUTPUT_DIR/$SEDFILE
done

# vi: set sw=4 ts=4 paste:
