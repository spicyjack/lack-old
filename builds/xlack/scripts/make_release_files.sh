#!/bin/sh

# script to create the release files for XXXX release;
# script will be run from the top level project directory

# program locations
CAT=$(which cat)
SED=$(which sed)

if [ -z $FILELIST ]; then 
    echo "ERROR: FILELIST variable empty!"
    exit 1
fi # if [ -z $FILELIST ]; then
if [ -z $TEMPDIR ]; then 
    echo "ERROR: TEMPDIR variable empty!"
    exit 1
fi # if [ -z $FILELIST ]; then

# any files in this list get enumerated over and the substitutions below are
# performed on them
INPUT_FILES="issue.${PROJECT_NAME} issue.${PROJECT_NAME}.nogetty"

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
echo "${PROJECT_NAME}" > $TEMPDIR/hostname

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
    > $TEMPDIR/$SEDFILE
done

# create the new init.sh script, which will be appended to
#$TOUCH $TEMPDIR/init.sh
$CAT $BUILD_BASE/common/initscripts/_initramfs_init.sh | $SED \
    "{
    s!:PROJECT_NAME:!${PROJECT_NAME}!g;
    s!:PROJECT_DIR:!${PROJECT_DIR}!g;
    s!:BUILD_BASE:!${BUILD_BASE}!g;
    s!:VERSION:!${KERNEL_VER}!g; 
    }" >> $TEMPDIR/init.sh

# add the init script to the filelist
echo "file /init /${TEMPDIR}/init.sh 0755 0 0" >> $TEMPDIR/$FILELIST

# vi: set sw=4 ts=4 paste:
