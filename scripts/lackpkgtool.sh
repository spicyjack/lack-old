#!/bin/sh

# lackpkgtool.sh
# Copyright (c)2010 by Brian Manning
# Licensed under the GNU GPL v2; see the bottom of this file for the blurb
#
# script that queries a packaging system for a list of files which can then be
# hacked up to make a filelist for use with gen_init_cpio

# TODO
# Inputs:
# - one or more debian packages or gen_init_cpio filelists; multiple
#   packages or filelists need to be passed in after double-dashes '--';
#   use $* to pick them up
#   - multiple packages can be written to individual files or a single file,
#   select via command line switch (--single/--multiple?)
#   - http://www.shelldorado.com/goodcoding/cmdargs.html
# - one or more filelists for converting into squashfs and/or cpio files
#
# Outputs:
# - one or more filelists
# - one or more squashfs packages
#
# Arguments:
# - TEMPDIR
# - OUTPUT_DIR
#
# Actions:
# - Write a manifest file of some kind
#   - package version
#   - package date
#   - packaged by
#   - checksums?

# verify we're not running under dash
if [ -z $BASH_VERSION ]; then
#if [ $(readlink /bin/sh | grep -c dash) -gt 0 ]; then
    # execute this script under bash instead
    echo "WARNING: this script doesn't run under dash..." >&2
    echo "WARNING: execute this script with /bin/bash" >&2
    exit 1
fi # if [ $(readlink /bin/sh | grep -c dash) -gt 0 ]

# external programs used
TRUE=$(which true)
GETOPT=$(which getopt)
DPKG=$(which dpkg)
MV=$(which mv)
CAT=$(which cat)
RM=$(which rm)
TR=$(which tr)
MKTEMP=$(which mktemp)
READLINK=$(which readlink)
GZIP=$(which gzip)
SED=$(which sed)
SCRIPTNAME=$(basename $0)
STAT=$(which stat)
UNAME=$(which uname)
TOUCH=$(which touch)

# local variables
VERBOSE=0
# pattern of strings to exclude
EXCLUDE="share/doc|/man|/info|bug"
EXCLUDE="${EXCLUDE}|^/\.$|^/boot$|^/usr$|^/usr/share$|^/lib$|^/lib/modules$"

### FUNCTIONS ###
# check the status of the last run command; run a shell if it's anything but 0
cmd_status () {
    COMMAND=$1
    STATUS=$2
    if [ $STATUS -ne 0 ]; then
        echo "Command '${COMMAND}' failed with status code: ${STATUS}"
        exit 1
    fi
} # cmd_status

dump_header () {

# FIXME
# we know the name of the package.... generate a nicer header that includes
# the current date and package name
cat <<'EOHD'
# $Id: generate_recipe.sh,v 1.8 2009-07-31 23:47:23 brian Exp $
# description: example package with comments
# depends: _base otherpackage1 otherpackage2
# helpcommand: /usr/bin/somebin --help
# versioncommand: /usr/bin/somebin --version
# examplecommand: /usr/bin/somebin -x -y -z 10
#
# dir <name> <mode> <uid> <gid>
# file <name> <source> <mode> <uid> <gid>
# slink <new name> <original file> <mode> <uid> <gid>
#
EOHD

} # dump_header

### MAIN SCRIPT ###

### SCRIPT SETUP ###
# BSD's getopt is simpler than the GNU getopt; we need to detect it
OSDETECT=$($UNAME -s)
if [ ${OSDETECT} == "Darwin" ]; then
    # this is the BSD part
    echo "WARNING: BSD OS Detected; long switches will not work here..."
    TEMP=$(/usr/bin/getopt hvd:g:p:r:u:sa $*)
elif [ ${OSDETECT} == "Linux" ]; then
    # and this is the GNU part
    TEMP=$(/usr/bin/getopt -o hvd:g:p:r:u:sa \
        --long help,verbose,directory:,package:,regex:,skip-exclude,append \
        --long gid:,uid: \
        -n "${SCRIPTNAME}" -- "$@")
else
    echo "Error: Unknown OS Type.  I don't know how to call"
    echo "'getopts' correctly for this operating system.  Exiting..."
    exit 1
fi

# if getopts exited with an error code, then exit the script
#if [ $? -ne 0 -o $# -eq 0 ] ; then
if [ $? != 0 ] ; then
    echo "Run '${SCRIPTNAME} --help' to see script options" >&2
    exit 1
fi

# Note the quotes around `$TEMP': they are essential!
# read in the $TEMP variable
eval set -- "$TEMP"

# set a counter for how many times getopts is run; if the loop counter gets too
# big, that means there was a problem with the getopts call; exit before you
# run into an endless loop
ERRORLOOP=1

# read in command line options and set appropriate environment variables
# if you change the below switches to something else, make sure you change the
# getopts call(s) above
while true ; do
    case "$1" in
        -h|--help) # show the script options
        cat <<-EOF

    ${SCRIPTNAME} [options]

    SCRIPT OPTIONS
    -h|--help           Displays this help message
    -v|--verbose        Nice pretty output messages
    -p|--package        Package to query for a list of files
    -d|--directory      Directory containing files to package
    -s|--skip-exclude   Skip excluding files in the output
    -a|--append         Append the library files, don't generate a header
    -r|--regex          Apply the regular expression to destination file
    NOTE: Long switches do not work with BSD systems (GNU extension)

    EXAMPLE USAGE:

    ${SCRIPTNAME} --package binutils > binutils.txt

    ${SCRIPTNAME} --directory /tmp/somedirectory > somepackage.txt

    ${SCRIPTNAME} --directory /tmp/somedirectory \
        --regex 's!/some/path!/other/path!g' > somepackage.txt

EOF
        exit 0;;
        -v|--verbose) # output pretty messages
            VERBOSE=1
            ERRORLOOP=$(($ERRORLOOP - 1));
            shift
            ;;
        -u|--uid)
            FUID=$2
            ERRORLOOP=$(($ERRORLOOP - 1));
            shift 2
            ;;
        -g|--gid)
            FGID=$2
            ERRORLOOP=$(($ERRORLOOP - 1));
            shift 2
            ;;
        -d|--directory)
            PACKAGE_DIR=$2
            ERRORLOOP=$(($ERRORLOOP - 1));
            shift 2
            ;;
        -p|--package)
            PACKAGE_NAME=$2
            ERRORLOOP=$(($ERRORLOOP - 1));
            shift 2
            ;;
        -r|--regex)
            REGEX=$2
            ERRORLOOP=$(($ERRORLOOP - 1));
            shift 2
            ;;
        -s|--skip|--skip-exclude) # skip excluding of files using grep
            SKIP_EXCLUDE=1
            ERRORLOOP=$(($ERRORLOOP - 1));
            shift
            ;;
        -a|--append) # don't print the header, it's not needed
            APPEND=1
            ERRORLOOP=$(($ERRORLOOP - 1));
            shift
            ;;
        --) shift
            break
            ;;
    esac
    # exit if we loop across getopts too many times
    ERRORLOOP=$(($ERRORLOOP + 1))
    if [ $ERRORLOOP -gt 4 ]; then
        echo "ERROR: too many getopts passes;" >&2
        echo "Maybe you have a getopt option with no branch?" >&2
        exit 1
    fi # if [ $ERROR_LOOP -gt 3 ];
done

if [ "x$PACKAGE_NAME" == "x" -a "x$PACKAGE_DIR" == "x" ]; then
    echo "ERROR: must pass in a package name via --package"
    echo "ERROR: or a directory name via --directory"
    echo "Run '${SCRIPTNAME} --help' to see script options"
    exit 1
fi

if [ -n $PACKAGE_NAME -a -n $PACKAGE_DIR ]; then
    echo "ERROR: must pass either --package or --directory arguments, not both"
    echo "Run '${SCRIPTNAME} --help' to see script options"
    exit 1
fi

### SCRIPT MAIN LOOP ###
    if [ ! -z $PACKAGE_NAME ]; then
        OUTPUT=$(/usr/bin/dpkg -L $PACKAGE_NAME | sort )
        cmd_status "dpkg" $?
    elif [ ! -z $PACKAGE_DIR ]; then
        OUTPUT=$(/usr/bin/find $PACKAGE_DIR -type f | sort)
        cmd_status "find $PACKAGE_DIR -type f" $?
    fi # if [ ! -z $PACKAGE_NAME ]

    # print the recipe header
    if [ "x$APPEND" == "x" ]; then
        dump_header
    fi
    echo "# ${PACKAGE_NAME}"

    for LINE in $(echo $OUTPUT);
    do
        # check to see if we are skipping excludes
        if [ "x${SKIP_EXCLUDE}" == x ]; then
            # run through the exclusions list
            if [ $(echo $LINE | grep -cE "${EXCLUDE}") -gt 0 ]; then
                continue
            fi
        fi # if [ "x${SKIP_EXCLUDE}" = x ]
        # skip missing files and/or directories
        if [ ! -e $LINE ]; then
            continue
        fi
        # this makes it easy to use case to decide what to write to the output
        # file
        FILE_TYPE=$($STAT --printf "%F" $LINE)
        # AUG == access rights in octal, FUID, FGID
        STAT_AUG=$($STAT --printf "%a %u %g" $LINE)
        PERMS=$(echo $STAT_AUG | awk '{print $1}')
        # munge the userid/groupid bits
        if [ -z $FUID ]; then
            FUID=$(echo $STAT_AUG | awk '{print $2}')
        fi

        if [ -z $FGID ]; then
            FGID=$(echo $STAT_AUG | awk '{print $3}')
        fi

        # check if this is the kernel; we don't need to package it up in the
        # initramfs file
        if [ $(echo $LINE | grep -c "vmlinuz") -gt 0 ]; then
            echo "#file $LINE $LINE $STAT_AUG"
            continue
        fi

        # munge the target filename if required
        SOURCE=$LINE
        if [ "x$REGEX" != "x" ]; then
            TARGET=$(echo $LINE | $SED $REGEX)
        else
            TARGET=$LINE
        fi # if [ -n $REGEX ]

        case "$FILE_TYPE" in
            "regular file") echo "file $TARGET $SOURCE $PERMS $FUID $FGID";;
            "directory") echo "dir $SOURCE $PERMS $FUID $FGID";;
            "symbolic link")
                TARGET=$($READLINK -f $SOURCE | $TR -d '\n')
                echo "slink $SOURCE $TARGET $PERMS $FUID $FGID"
            ;;
        esac
    done # for LINE in $(echo $OUTPUT);

    # print the vim tag at the bottom so the recipes are formatted nicely when
    # you edit them
    echo "# vi: set shiftwidth=4 tabstop=4 paste:"

    # exit with the happy
    exit 0

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

# vi: set filetype=sh shiftwidth=4 tabstop=4:
# eof
