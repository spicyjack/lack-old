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
# - WORKDIR
# - OUTPUT_DIR
#
# Actions:
# - Write a manifest file of some kind
#   - package version
#   - package date
#   - packaged by
#   - checksums?

# FIXME
# - we know the name of the package.... generate a nicer header that includes
# the current date and package name

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
function cmd_status () {
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

function show_examples {
cat <<'EOU'
    EXAMPLE OF SCRIPT USAGE:

    ${SCRIPTNAME} --package binutils > binutils.txt

    ${SCRIPTNAME} --directory /tmp/somedirectory > somepackage.txt

    ${SCRIPTNAME} --directory /tmp/somedirectory \
        --regex 's!/some/path!/other/path!g' > somepackage.txt
EOU
} # function show_examples

### SCRIPT SETUP ###
# BSD's getopt is simpler than the GNU getopt; we need to detect it
OSDETECT=$($UNAME -s)
if [ ${OSDETECT} == "Darwin" ]; then
    # this is the BSD part
    echo "WARNING: BSD OS Detected; long switches will not work here..."
    TEMP=$(/usr/bin/getopt hvd:g:p:r:u:sa $*)
elif [ ${OSDETECT} == "Linux" ]; then
    # and this is the GNU part
    TEMP=$(/usr/bin/getopt -o hvepdlqfcso:w:u:g:rkax: \
        --long help,verbose,examples \
        --long package,directory,list \
        --long squashfs,filelist,cpio,single,output:,workdir: \
        --long uid:,gid:,all-root \
        --long skip-exclude,append,regex: \
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

# read in command line options and set appropriate environment variables
# if you change the below switches to something else, make sure you change the
# getopts call(s) above
while true ; do
    case "$1" in
        -h|--help) # show the script options
        cat <<-EOF

    ${SCRIPTNAME} [options]

    HELP OPTIONS
    -h|--help           Displays this help message
    -v|--verbose        Nice pretty output messages
    -e|--examples       Show examples of script usage

    INPUT TYPES
    -p|--package        Package names to query for a list of files
    -d|--directory      Directories containing files to package
    -l|--list           Filelists used with 'gen_init_cpio' program

    OUTPUT OPTIONS
    -q|--squashfs       Output squashfs package(s)
    -f|--filelist       Output filelist(s)
    -c|--cpio           Create a CPIO file (via gen_init_cpio)
    -s|--single         Whatever output type, only write one of that type
    -o|--output         Output filename (for --single) or directory 
    -w|--workdir        Working directory to use for copying/storing files

    MISC. OPTIONS
    -u|--uid            Use this UID for all files output
    -g|--gid            Use this GID for all files output
    -r|--all-root       Use UID/GID 0 for all files output
    -k|--skip-exclude   Skip excluding files in the output
    -a|--append         Append to an existing file, don't create a new file
    -x|--regex          Apply the regular expression to destination file
    NOTE: Long switches do not work with BSD systems (GNU extension)

EOF
        exit 0;;
        -v|--verbose) # output pretty messages
            VERBOSE=1
            shift
            ;;
        -e|--examples) # show usage examples
            show_examples
            exit 0
            ;;

        ### Input options ###
        -d|--directory) # use directories of files as input
            INPUT_OPT="directory"
            shift 1
            ;;
        -p|--package) # use package names for input
            INPUT_OPT="package"
            shift 1
            ;;
        -l|--list) # use lists of packages for input
            INPUT_OPT="filelist"
            shift 1
            ;;

        ### OUTPUT OPTIONS ###
        -q|--squashfs) # make squashfs file(s)
            OUTPUT_OPT="squashfs"
            shift 1
            ;;
        -f|--filelist) # make filelist(s)
            OUTPUT_OPT="filelist"
            shift 1
            ;;
        -c|--cpio) # make cpio file(s)
            OUTPUT_OPT="cpio"
            shift 1
            ;;
        -s|--single) 
            # make one large file instead of multiple files for each
            # filelist/directory/package
            OUTPUT_OPT="cpio"
            shift 1
            ;;
        -o|--output) # working directory
            OUTPUT_ARG=$2
            shift 2
            ;;
        -w|--workdir) # working directory
            WORKDIR=$2
            shift 2
            ;;

        ### MISC OPTIONS ###
        -u|--uid) # user ID to use when creating squashfs files/filelists
            FUID=$2
            shift 2
            ;;
        -g|--gid) # group ID to use when creating squashfs files/filelists
            FGID=$2
            shift 2
            ;;
        -a|--all-root) # make all files owned by and grouped by root
            FGID=0
            FUID=0
            ALL_ROOT=1
            shift 1
            ;;
        -s|--skip|--skip-exclude) # skip excluding of files using grep
            SKIP_EXCLUDE=1
            shift
            ;;
        -a|--append) # don't print the header, it's not needed
            APPEND=1
            shift
            ;;
        -r|--regex) # use a regex to substitute strings in filelists
            REGEX=$2
            shift 2
            ;;        
        --) shift   
            # everything after here should be a filelist file,
            # directory names or package names
            break
            ;;
        *) # something we didn't expect; warn the user
            echo "ERROR: unknown option '$1'"
            echo "ERROR: use --help to list script options"
            exit 1
    esac
done

if [ -z $@ ]; then
    echo "ERROR: no packages/directories/filelists to process"
    echo "ERROR: use the --help switch to see script options"
    exit 1
fi # if [ -z $@ ]; then  

### SCRIPT MAIN LOOP ###
# loop across the arguments listed after the double-dashes '--'
for ARG in $@; 
do
    # depending on what the input type will be is what actions we will take
    case "$INPUT_OPT" in
        package)
            OUTPUT=$(/usr/bin/dpkg -L ${ARG} | sort )
            cmd_status "dpkg -L ${ARG}" $?
            ;;
        directory)
            OUTPUT=$(/usr/bin/find ${ARG} -type f | sort)
            cmd_status "find ${ARG} -type f" $?
            ;;
        filelist)
            OUTPUT=$(/usr/bin/find ${ARG} -type f | sort)
            cmd_status "find ${ARG} -type f" $?
            ;;
        *) # unknown argument 
            echo "ERROR: must use --list|--directory|--package arguments"
            echo "ERROR: to specify what the input to this script is"
            exit 1
            ;;
    esac # case "$INPUT_OPT"

    if [ "x$OUTPUT" == "x" ]; then
        echo "ERROR: OUTPUT variable empty;"
        echo "ERROR: Perhaps you didn't specify an output type???"
        exit 1
    fi # if [ -z $OUTPUT ]; then 

    ### no output type specified ###
    if [ "x${OUTPUT_OPT}" == "x" ]; then
        echo "ERROR: must use --squashfs|--filelist|--cpio arguments"
        echo "ERROR: to specify what the output of this script will be"
        exit 1
    ### filelist output ###
    elif [ $OUTPUT_OPT == "filelist" ]; then
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
            # this makes it easy to use case to decide what to write to the
            # output file
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

            # check if this is the kernel; we don't need to package it up in
            # the initramfs file
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
                "regular file") 
                    echo "file $TARGET $SOURCE $PERMS $FUID $FGID"
                    ;;
                "directory") 
                    echo "dir $SOURCE $PERMS $FUID $FGID"
                    ;;
                "symbolic link")
                    TARGET=$($READLINK -f $SOURCE | $TR -d '\n')
                    echo "slink $SOURCE $TARGET $PERMS $FUID $FGID"
                    ;;
            esac
        done # for LINE in $(echo $OUTPUT);

        # print the vim tag at the bottom so the recipes are formatted nicely
        # when you edit them
        echo "# vi: set shiftwidth=4 tabstop=4 paste:"
    ### squashfs output ###
    elif [ $OUTPUT_OPT == "squashfs" ]; then
        if [ "x$WORKDIR" == "x" ]; then
            echo "ERROR: --workdir argument needs to be used with --squashfs"
            exit 1
        fi
        if [ ! -d $WORKDIR ]; then
            echo "ERROR: WORKDIR ${WORKDIR} doesn't exist"
            exit 1
        fi # if [ ! -d $WORKDIR ]
        for LINE in $(echo $OUTPUT);
        do
            # skip missing files and/or directories
            if [ ! -e $LINE ]; then
                continue
            fi
            # this makes it easy to use case to decide what to write to the
            # output file
            FILE_TYPE=$($STAT --printf "%F" $LINE)
            # AUG == access rights in octal, FUID, FGID
            STAT_AUG=$($STAT --printf "%a %u %g" $LINE)
            PERMS=$(echo $STAT_AUG | awk '{print $1}')

            # munge the target filename if required
            SOURCE=$LINE
            if [ "x$REGEX" != "x" ]; then
                TARGET=$(echo $LINE | $SED $REGEX)
            else
                TARGET=$LINE
            fi # if [ -n $REGEX ]

            case "$FILE_TYPE" in
                "regular file") 
                    echo "copying ${TARGET} to ${WORKDIR}${TARGET}"
                    #cp $TARGET "${WORKDIR}${TARGET}"
                    ;;
                "directory") 
                    #mkdir -p $WORKDIR/$TARGET
                    if [ $TARGET != "./" ]; then
                        echo "making directory ${WORKDIR}${TARGET}"
                    fi # if [ $TARGET != "./" ]
                    ;;
                "symbolic link")
                    TARGET=$($READLINK -f $SOURCE | $TR -d '\n')
                    echo "creating symlink: ${SOURCE} ${WORKDIR}${TARGET}"
                    #ln -s $SOURCE $WORKDIR/$TARGET
                    ;;
            esac
        done # for LINE in $(echo $OUTPUT);

        exit 0
    elif [ $OUTPUT_OPT == "cpio" ]; then
        : 
    else
        echo "ERROR: unknown output type; OUTPUT_OPT is '${OUTPUT_OPT}'"
        exit 1
    fi # if [ $OUTPUT_OPT == "filelist" ]; then 
    
done # for $ARG in $@; 

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
