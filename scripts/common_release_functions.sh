#!/bin/sh

# Copyright (c)2010 by Brian Manning <brian at portaboom dot com>
# License: GPL v2 (see licence blurb at the bottom of the file)
# Get support and more info about this script at:
# http://code.google.com/p/lack/
# http://groups.google.com/group/linuxack|linuxack@googlegroups.com

# DO NOT CONTACT THE AUTHOR DIRECTLY; use the mailing list please

# A set of shell functions that help build LACK releases.

# FIXME
# - go through portaboom's initramfs.cfg and pull out commonly used code

# program locations
CAT=$(which cat)
SED=$(which sed)
GIT=$(which git)

## FUNC: say
## ARG: the MESSAGE to be written on STDOUT or to $LOGFILE
## ENV: VERBOSE, the verbosity level of the script
## ENV: LOGFILE; if set, writes to that logfile
## DESC: Check if $VERBOSE is set, and if so, write MESSAGE to STDOUT
function say {
    local MESSAGE=$1
    if [ $VERBOSE -gt 0 ]; then
        if [ "x${LOGFILE}" != "x" ]; then
            echo $MESSAGE >> $LOGFILE
        else
            echo $MESSAGE
        fi # if [ "x${LOGFILE}" != "x" ]
    fi
} # function say

## FUNC: warn
## ARG: the message to be written to STDERR
## DESC: Write MESSAGE to STDERR
function warn {
    local MESSAGE=$1
    echo $MESSAGE >&2
} # function warn

## FUNC: check_return_status
## ARG:  Name of the function we're checking the return status of
## ARG:  Returned exit status code of that function
## DESC: Verifies the function exited with an exit status code (0), and
## DESC: exits the script if any other status code is found.
function check_return_status {
    local MESSAGE=$1
    local EXIT_STATUS=$2

    if [ $EXIT_STATUS -gt 0 ]; then
        echo "ERROR: '${MESSAGE}' returned an exit code of ${EXIT_STATUS}"
        exit 1
    fi # if [ $STATUS_CODE -gt 0 ]
} # function check_return_status

## FUNC: check_empty_envvar
## ARG:  VAR_NAME - Human-readable name of the variable to check
## ARG:  ENV_VAR - The environment variable to check
## RET:  Returns a '0' if the ENV_VAR is *NOT* empty
## ERR:  Returns a '1' if ENV_VAR is empty ("x$ENV_VAR" = "x")
## DESC: Checks if an environment variable has data or is empty
function check_empty_envvar {
    local VAR_NAME=$1
    local ENV_VAR=$2
    if [ "x${ENV_VAR}" = "x" ]; then
        echo "ERROR: ${VAR_NAME} variable empty!"
        return 1
    fi # if [ -z $FILELIST ]; then
    return 0
} # function check_filelist_envvar

## FUNC: check_base_file_exists
## ARG:  None
## ENV:  PROJECT_DIR, project directory
## ENV:  PROJECT_NAME, the project's name
## RET:  '0' if ${PROJECT_DIR}/${PROJECT_NAME}.base.txt exists
## ERR:  '1' if ${PROJECT_DIR}/${PROJECT_NAME}.base.txt does not exist
## DESC: Check for the $PROJECT_NAME.base.txt.  Exits the script
## DESC: with an error if the project base file is missing.
## DESC: The base file is a filelist with a specific set of files to be
## DESC: included with this project.
function check_base_file_exists {
    if [ ! -e $PROJECT_DIR/${PROJECT_NAME}.base.txt ]; then
        echo "ERROR: ${PROJECT_DIR}/${PROJECT_NAME}.base.txt file missing"
        return 1
    fi # if [ $PROJECT_DIR/${PROJECT_NAME}.base.txt ]
    return 0
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
        return 1
    fi # if [ -e $PROJECT_DIR/kernel_configs/linux-image-${KERNEL_VER}.txt ]
    return 0
} # function create_initramfs_filelist

## FUNC: create_hostname_file
## ARG:  None
## ENV:  PROJECT_NAME - the name of the project; used as the hostname
## ENV:  TEMP_DIR - temp working directory for creating the initramfs image
## RET:  '0' for successfully creating the 'hostname' file in TEMP_DIR
## ERR:  '1' if a there was a problem creating the hostname file
## DESC: Create the hostname file in $TEMP_DIR
function create_hostname_file {
    echo $PROJECT_NAME > $TEMP_DIR/hostname
    if [ $? -gt 0 ]; then
        # return an error
        return 1
    else
        # return success
        return 0
    fi
} # function create_hostname_file

## FUNC: create_standalone_init_script
## ARG:  None
## ENV:  See '_create_init_script' for any required environment variables
## RET:  See '_create_init_script' for the return value
## ERR:  See '_create_init_script' for any error values
## DESC: Creates the standalone version of the /init script that the Linux
## DESC: kernel runs once it loads the initramfs image into RAM.
## DESC: Performs a bunch of text substitutions via sed when the file
## DESC: is copied to $TEMP_DIR
function create_standalone_init_script {
    _create_init_script _init.sh
} # function create_standalone_init_script

## FUNC: create_initramfs_init_script - Create the /init script
## ARG:  None
## ENV:  See '_create_init_script' for any required environment variables
## RET:  See '_create_init_script' for the return value
## ERR:  See '_create_init_script' for any error values
## DESC: Creates the initramfs version of the /init script that the Linux
## DESC: kernel runs once it loads the initramfs image into RAM.
## DESC: This script calls Busybox /sbin/init at the tail end of the init
## DESC: process.  Performs a bunch of text substitutions via sed
## DESC: when it copies the file to $TEMP_DIR.
function create_initramfs_init_script {
    _create_init_script _initramfs_init.sh
} # function create_initramfs_init_script

## FUNC: _create_init_script
## ARG:  path to the source init script
## ENV:  BUILD_BASE - base directory for the LACK scripts
## ENV:  PROJECT_DIR - base directory for the project
## ENV:  PROJECT_NAME - the name of the project
## ENV:  KERNEL_VER - kernel version, used for issue/syslinux screens
## ENV:  TEMP_DIR - temporary directory used to build the initramfs image
## ENV:  FILELIST - the filelist passed to 'gen_init_cpio'
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
    check_return_status "Creating the init script in TEMP_DIR" $?
    # add the init script to the filelist
    echo "file /init /${TEMP_DIR}/init.sh 0755 0 0" >> $TEMP_DIR/$FILELIST
    check_return_status "Creating the init script in TEMP_DIR" $?
    return 0
} # function _create_init_script

## FUNC: copy_host_ssl_pem_files
## ARG:  None
## ENV:  PROJECT_NAME - the name of the project
## ENV:  TEMP_DIR - temporary directory used to build the initramfs image
## RET:  '0' if the SSL PEM files were copied to TEMP_DIR successfully
## ERR:  '1' if copying the SSL PEM files failed
## DESC: Copy the *.pem files needed for SSL usage
function copy_host_ssl_pem_files {
    if [ -e ~/hostkeys/${PROJECT_NAME}.*key.pem.nopass ]; then
        cp ~/hostkeys/${PROJECT_NAME}.*pem* $TEMP_DIR
    else
        echo "ERROR: missing ${PROJECT_NAME} SSL keys in ~/hostkeys"
        return 1
    fi # if [ -e ~/hostkeys/${PROJECT_NAME}.*key.pem.nopass ]
    return 0
} # function copy_host_ssl_pem_files

## FUNC: copy_lack_ssl_pem_file
## ARG:  None
## ENV:  TEMP_DIR - temporary directory used to build the initramfs image
## RET:  '0' if the SSL PEM files were copied to TEMP_DIR successfully
## ERR:  '1' if copying the SSL PEM files failed
## DESC: Copy the LACK SSL PEM files needed for SSL usage
function copy_lack_ssl_pem_file {
    if [ -e ~/hostkeys/lack.googlecode.com.key-cert.pem ]; then
        cp ~/hostkeys/lack.googlecode.com.key-cert.pem \
            $TEMP_DIR/certificate.pem
    else
        echo "ERROR: missing LACK SSL key/cert file in ${HOME}/hostkeys"
        return 1
    fi # if [ -e ~/hostkeys/lack.googlecode.com.key-cert.pem ]
    return 0
} # function copy_host_ssl_pem_file

## FUNC: copy_busybox_binary
## ARG:  None
## ENV:  TEMP_DIR - temporary directory used to build the initramfs image
## RET:  '0' if busybox was copied to TEMP_DIR successfully
## ERR:  '1' if copying busybox failed
## DESC: Copies the Busybox binary to $TEMP_DIR
## DESC: Exits if it can't find the Busybox binary.
function copy_busybox_binary {
    if [ -e ~/busybox-*-x86 ]; then
        BUSYBOX_BIN=$(ls ~/busybox-*-x86)
        echo "Copying Busybox binary '${BUSYBOX_BIN}' to ${TEMP_DIR}"
        cp $BUSYBOX_BIN $TEMP_DIR
    else
        echo "ERROR: missing busybox binary in ~"
        return 1
    fi # if [ -e ~/hostkeys/busybox-* ]
    return 0
} # function copy_busybox_binary

## FUNC: sedify_input_files
## ARG:  INPUT_FILES - a list of files to sedify
## ENV:  $TEMP_DIR - temporary directory
## ENV:  $RELEASE_VER - release version
## DESC: Enumerates over $INPUT_FILES, passes the files through a sed filter,
## DESC: and writes them to $TEMP_DIR
function sedify_input_files {
    local INPUT_FILES="$*"
    if [ "x${INPUT_FILES}" != "x" ]; then
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
        check_return_status "Run /bin/sed on ${SEDFILE}" $?
    done
} # function ѕedify_input_files

## FUNC: sync_perl_gtk2_source
## ARG:  PERL_GTK2_SRC - directory to check for Perl-Gtk2 source
## ENV:  $TEMP_DIR - temporary directory
## ENV:  $RELEASE_VER - release version
## DESC: Enumerates over $INPUT_FILES, passes the files through a sed filter,
## DESC: and writes them to $TEMP_DIR
function sync_perl_gtk2_source {
    local PERL_GTK2_SRC=$1
    # do we need to clone the perl-Gtk2 repo?
    if [ ! -d $PERL_GTK2_SRC ]; then
        if [ -z $GIT ]; then
            echo "ERROR: 'git' command not found!"
            echo "ERROR: git is required to sync perl-Gtk2 examples"
            return 1
        fi # if [ -z $GIT ]
        # don't create a directory for gtk2-perl source; git will do this for
        # us
        echo "Cloning perl-Gtk2 source for 'examples' and 'gtk-demo'..."
        git clone git://git.gnome.org/perl-Gtk2 $PERL_GTK2_SRC
        check_return_status "Running 'git clone' for Perl-Gtk2 source" $?
    else
        echo "- Running 'git pull' on perl-Gtk2 source..."
        cd $PERL_GTK2_SRC
        git pull
        check_return_status "Running 'git pull' for Perl-Gtk2 source" $?
    fi # if [ ! -d "/tmp/gtk2-perl-examples" ];
    return 0
} # function sync_perl_gtk2_source

# *begin license blurb*
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; version 2 dated June, 1991.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program;  if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111, USA.

# vi: set sw=4 ts=4 ft=sh:
# fin!
