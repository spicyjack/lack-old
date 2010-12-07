#!/bin/sh

# script to create the release files for a pigwidgeon release
# script will be run from the top level 'pigwidgeon' directory

# program locations
CAT=$(which cat)
SED=$(which sed)

## FUNC: check_filelist_envvar
## REQ:  $FILELIST - the filename of the output filelist file
## DESC: Check the $FILELIST environment variable.  Exits the script 
## DESC: with an error if the filelist variable is not set
function check_filelist_envvar {
    if [ -z $FILELIST ]; then
        echo "ERROR: FILELIST variable empty!"
        exit 1
    fi # if [ -z $FILELIST ]; then
} # function check_filelist_envvar

## FUNC: check_project_list_envvar
## ARG:  None
## DESC: Check for the $PROJECT_LIST variable.  Exits the script 
## DESC: with an error if the project list variable is not set
function check_project_list_envvar {
    if [ -z $PROJECT_LIST ]; then
        echo "ERROR: PROJECT_LIST variable empty!"
        exit 1
    fi # if [ -z $PROJECT_LIST ]; then
} # function check_project_list_envvar

## FUNC: check_temp_dir_envvar - Check the $TEMP_DIR environment variable
## ARG:  None
## DESC: exits the script with an error if the temporary (working) directory
## DESC: variable is not set
function check_temp_dir_envvar {
    if [ -z $TEMP_DIR ]; then
        echo "ERROR: TEMP_DIR variable empty!"
        exit 1
    fi # if [ -z $FILELIST ]; then
} # function check_temp_dir_envvar

## FUNC: check_base_file_exists
## ARG:  None
## DESC: Check for the $PROJECT_NAME.base.txt.  Exits the script 
## DESC: with an error if the project base file is missing.  
## DESC: The base file is a filelist with a specific set of files to be
## DESC: included with this project.
function check_base_file_exists {
    if [ ! -e $PROJECT_DIR/${PROJECT_NAME}.base.txt ]; then
        echo "ERROR: ${PROJECT_DIR}/${PROJECT_NAME}.base.txt file missing"
        exit 1
    fi # if [ $PROJECT_DIR/${PROJECT_NAME}.base.txt ]
} # function check_base_file_exists

## FUNC: create_initramfs_filelist
## ARG:  None
## DESC: Creates the initramfs filelist.  Writes the initramfs filelist to
## DESC: the $TEMP_DIR.  Requires that the $PROJECT_DIR and $PROJECT_NAME
## DESC: environment variables be set prior to calling this function
function create_project_filelist {
    if [ -e $PROJECT_DIR/kernel_configs/linux-image-${KERNEL_VER}.txt ]; then
        cat $PROJECT_DIR/${PROJECT_NAME}.base.txt \
            $PROJECT_DIR/kernel_configs/linux-image-${KERNEL_VER}.txt \
            > $TEMP_DIR/project-filelist.txt
    else
        echo "ERROR: linux-image-${KERNEL_VER}.txt file does not exist"
        echo "ERROR: in ${PROJECT_DIR}/kernel_configs directory"
        exit 1
    fi # if [ -e $PROJECT_DIR/kernel_configs/linux-image-${KERNEL_VER}.txt ]
} # function create_initramfs_filelist

## FUNC: create_hostname_file
## ARG:  None
## DESC: Create the hostname file in $TEMP_DIR
function create_hostname_file {
    echo $PROJECT_NAME > $TEMP_DIR/hostname
} # function check_filelist_envvar

## FUNC: create_standalone_init_script
## ARG:  None
## DESC: Creates the standalone version of the /init script that the Linux
## DESC: kernel runs once it loads the initramfs image into RAM.
## DESC: Performs a bunch of text substitutions via sed when the file
## DESC: is copied to $TEMP_DIR
function create_standalone_init_script {
    _create_init_script _init.sh
} # function create_standalone_init_script

## FUNC: create_initramfs_init_script - Create the /init script
## ARG:  None
## DESC: Creates the initramfs version of the /init script that the Linux
## DESC: kernel runs once it loads the initramfs image into RAM.
## DESC: This script calls Busybox /sbin/init at the tail end of the init
## DESC: process.  Performs a bunch of text substitutions via sed 
## DESC: when it copies the file to $TEMP_DIR.
function create_initramfs_init_script {
    _create_init_script _initramfs_init.sh
} # function create_initramfs_init_script

## FUNC: _create_standalone_init_script
## ARG:  path to the source init script
## DESC: Called by one of the other init creators.  Does the actual work of
## DESC: creating the script and processing any variable substitutions 
function _create_init_script {
    local INIT_SCRIPT=$1
    $CAT $BUILD_BASE/common/initscripts/$INIT_SCRIPT | $SED \
        "{
        s!:PROJECT_NAME:!${PROJECT_NAME}!g;
        s!:PROJECT_DIR:!${PROJECT_DIR}!g;
        s!:BUILD_BASE:!${BUILD_BASE}!g;
        s!:VERSION:!${KERNEL_VER}!g; 
        }" >> $TEMP_DIR/init.sh

    # add the init script to the filelist
    echo "file /init /${TEMP_DIR}/init.sh 0755 0 0" >> $TEMP_DIR/$FILELIST
} # function create_standalone_init_script

## FUNC: copy_ssl_pems
## ARG:  None
## DESC: Copy the *.pem files needed for SSL usage
## DESC: Exits if it can't find the correct files in the ~/stuff_tars
## DESC: directory.  
## REQ:  $PROJECT_NAME - name of the project, also usually the hostname
## REQ:  $TEMP_DIR - working directory
function copy_ssl_pem_files {
    if [ -e ~/stuff_tars/${PROJECT_NAME}.*key.pem.nopass ]; then
        cp ~/stuff_tars/${PROJECT_NAME}.*pem* $TEMP_DIR
    else
        echo "ERROR: missing pigwidgeon SSL keys in ~/stuff_tars"
        exit 1
    fi # if [ -e ~/stuff_tars/pigwidgeon.key.pem.nopass ]
} # function copy_ssl_pem_files

## FUNC: copy_busybox_binary
## ARG:  None
## REQ:  $TEMP_DIR
## DESC: Copies the Busybox binary to $TEMP_DIR
## DESC: Exits if it can't find the Busybox binary.
function copy_busybox_binary {
    if [ -e ~/busybox-*-x86 ]; then
        cp ~/busybox-*-x86 $TEMP_DIR
    else
        echo "ERROR: missing busybox binary in ~"
        exit 1
    fi # if [ -e ~/stuff_tars/busybox-* ]
} # function copy_busybox_binary

## FUNC: sedify_input_files
## ARG:  INPUT_FILES - a list of files to sedify
## REQ:  $TEMP_DIR - temporary directory
## REQ:  $RELEASE_VER - release version
## DESC: Enumerates over $INPUT_FILES, passes the files through a sed filter, 
## DESC: and writes them to $TEMP_DIR
function sedify_input_files {
    local INPUT_FILES="$*"
    if [ ! -z $INPUT_FILES ]; then
        echo "- Sedifying files..."
    fi # if [ ! -z $INPUT_FILES ]

    for SEDFILE in $(echo $INPUT_FILES);
    do
        FILEBASE=$(echo $SEDFILE | sed 's!.*/\(.*\)$!\1!')
        echo "  -> ${PROJECT_DIR}/${SEDFILE}"
        $CAT $PROJECT_DIR/$SEDFILE \
            | $SED "{
                s!:RELEASE_VER:!${RELEASE_VER}!g; 
                s!:KERNEL_VER:!${KERNEL_VER}!g;
                s!:RELEASE_VER:!${RELEASE_VER}!g;
                s!:LACK_PASS:!${LACK_PASS}!g;
            }" > $TEMP_DIR/$FILEBASE
    done
} # function ѕedify_input_files

# vi: set sw=4 ts=4 ft=sh:
# fin!
