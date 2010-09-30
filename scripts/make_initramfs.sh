#!/bin/sh

# $Id: make_initramfs.sh,v 1.106 2009-08-10 08:38:58 brian Exp $
# Copyright (c)2006 Brian Manning <elspicyjack at gmail dot com>
# License: GPL v2 (see licence blurb at the bottom of the file)
# Get support and more info about this script at:
# http://groups.google.com/group/project-naranja
# DO NOT CONTACT THE AUTHOR DIRECTLY; use the mailing list please

# script to generate initramfs images based on lists of files you pass to it;
# the script compiles many small lists into one large list, and then feeds
# that to 'gen_init_cpio', which creates the initramfs file

# TODO
# - fall back to cpio/afio if gen_cpio_image doesn't exist
# - add detection of 'requirements' in the recipe files so that dependencies
# can be detected and added to the initramfs image as needed; run the
# 'dependencies' list through uniq to filter duplicates
# - add a 'dependencies list' option which would go through all of the recipe
# files and list the dependencies for each file in order to build a master list
# of dependencies

# external programs used
TRUE=$(which true)
GETOPT=$(which getopt)
MV=$(which mv)
CAT=$(which cat)
RM=$(which rm)
MKTEMP=$(which mktemp)
GZIP=$(which gzip)
SED=$(which sed)
TOUCH=$(which touch)
DATE=$(which date)
RFC_2822_DATE=$(${DATE} --rfc-2822)

# the name of this script
SCRIPTNAME=$(basename $0)
# some defaults
QUIET=1 # 0 = no output, 1 = some output, 2 = noisy
# 0 = don't hardlink, 1 hardlink
HARDLINK_INITRD=0 # don't hardlink the initramfs to the initrd file
# this is the top level directory; all of the paths created below start from
# this directory and then work down the directory tree
BUILD_BASE="/home/demo/src/lack-hg"
# the list of files output and fed to gen_init_cpio
FILELIST="initramfs-filelist.txt"

# helper functions

# set the script parameters from initramfs.cfg or a user-specified file
function set_vars() 
{
    local PROJECT_DIR=$1
    # $1 is the name of the build to set up for
    # verify the initramfs.cfg file exists
    if [ ! -e $PROJECT_DIR/initramfs.cfg ]; then
        echo "ERROR: initramfs.cfg file not found;"
        echo "Checked ${PROJECT_DIR}"
        exit 1
    fi
   
    # verify a project name was used; we need one to know which initramfs
    # package file to go get
    if [ $VARSFILE ]; then
        if [ -e $VARSFILE ]; then
            # source in the environment variables; this could be a potential
            # hazard if the sourced file contains malicious scripting
            source $VARSFILE
        else 
            echo "ERROR: --varsfile $VARSFILE does not exist in $PWD"
            exit 1
        fi # if [ -e $VARSFILE ];
    else 
        source $PROJECT_DIR/initramfs.cfg
    fi # if [ $VARSFILE ];
} # function set_vars

# check the status of the last run command; run a shell if it's anything but 0
cmd_status () {
    COMMAND=$1
    STATUS=$2
    if [ $STATUS -ne 0 ]; then
        echo "Command '${COMMAND}' failed with status code: ${STATUS}"
        exit 1 
    fi  
} # cmd_status

# find the first filename that hasn't already been taken
function find_first_free_filename()
{
    SEARCHDIR=$1
    TESTNAME=$2
    FILE_COUNTER=1
    FILE_DATE=$(TZ=GMT date +%Y.%j | tr -d '\n')
    while [ -f $SEARCHDIR/$TESTNAME.$FILE_DATE.$FILE_COUNTER.cpio.gz ];
    do
        echo "Exists: $SEARCHDIR/$TESTNAME.$FILE_DATE.$FILE_COUNTER.cpio.gz"
        # increment the file counter in order to try and find a free filename
        FILE_COUNTER=$(($FILE_COUNTER + 1))
    done
    echo "- Output file: $SEARCHDIR/$TESTNAME.$FILE_DATE.$FILE_COUNTER.cpio.gz"

    OUTPUT_FILE=$SEARCHDIR/$TESTNAME.$FILE_DATE.$FILE_COUNTER.cpio.gz
} # function find_first_free_filename()

# cat the source file, filter it with sed, then append it to the destination
function sedify () 
{
    local SOURCE_FILE=$1
    local DEST_FILE=$2

    $CAT $SOURCE_FILE | $SED \
        "{
        s!:PROJECT_NAME:!${PROJECT_NAME}!g;
        s!:PROJECT_DIR:!${PROJECT_DIR}!g;
        s!:BUILD_BASE:!${BUILD_BASE}!g;
        s!:VERSION:!${KERNEL_VER}!g; 
        s!:TEMP_DIR:!${TEMP_DIR}!g; 
        }" >> $DEST_FILE
} # function sedify ()

function show_vars() 
{
    echo "variables:"
    echo "BUILD_BASE=${BUILD_BASE}"
    echo "KERNEL_VER=${KERNEL_VER}"
    echo "PROJECT_NAME=${PROJECT_NAME}"
    echo "PROJECT_DIR=${PROJECT_DIR}"
    echo "PACKAGES='${PACKAGES}'"
    echo "OUTPUT_FILE=${OUTPUT_FILE}"
} # function show_vars()

function show_help () {
cat <<-EOF

  $SCRIPTNAME [options] --base --project

  -or-

  $SCRIPTNAME [options] --base --project-dir

  SCRIPT OPTIONS
  -b|--base         Base directory for project files and recipes
  -d|--project-dir  Base directory for the project files, if different from
                    --base option 
  -p|--project      Name of the project to build an initramfs image for
                    This is usually the project's subdirectory underneath
                    the --base directory

  -h|--help         Displays script options 
  -e|--examples     Displays examples of script usage
  -H|--longhelp     Displays script options, environment vars and examples 
  -n|--dry-run      Builds filelists but does not run 'gen_init_cpio'

  -f|--varsfile     File to read in to set script environment variables
  -s|--showvars     List variables set in the --project stanza
  -o|--output       Filename to write the initramfs image to
  -q|--quiet        No script output (unless an error occurs)
  -l|--hardlink     Create hardlink from 'initrd' to initramfs file
  -k|--keepfiles    Don't delete the created initramfs filelist/init.sh script
EOF
} # function show_help ()

function show_longhelp () {
cat <<-EOF

    The '--varsfile' option should specify a shell script with specific
    environment variables set; since it's a shell script that's sourced by
    this script, it could be a *POTENTIAL* *SECURITY* *HAZARD*.  
    
    The script needs the following environment variables defined (either
    inside the script itself, or in an external file that gets sourced with
    --varsfile) in order to function correctly:

    BUILD_BASE: 
        the path containing the project files and recipe files; set globally
        above, but can be overridden on a per-project basis
    KERNEL_VER: 
        the kernel version number, used in specifying the kernel module
        directory to add kernel modules from, as well as being part of the
        name of the output initramfs file (initramfs-KERNEL_VER.cpio.gz)
    PROJECT_NAME: 
        directory to append to BUILD_BASE in order to find initramfs filelist,
        project configuration file and support scripts
    PROJECT_DIR: directory to look in for initramfs filelist, project
        configuration file and support scripts
    PACKAGES: 
        a quoted, whitespace-separated list of packages to include in the
        final initramfs image; each package's recipe is used when building the
        initramfs image.  The list can span multiple lines without using a
        backslash '\\' character, as long as the entire list is enclosed in
        quotes.  The packages should be listed in order that you want them to
        appear in the ramdisk image.
    OUTPUT_FILE: 
        file to write the initramfs image to
EOF
} # function show_longhelp () 

function show_examples () {
cat <<-EOF

    Normal usage:

    # project directory is underneath base directory
    sh $SCRIPTNAME --base /path/to/base --project projectname

    # project directory somewhere else on the disk
    sh $SCRIPTNAME --base /path/to/base --project-dir /path/to/project/dir

    Output all of the important environment variables for a profile; you
    can edit these and then use them in place of a built-in profile;

    sh make_initramfs.sh --project projectname --showvars > projectvars.txt

    Now use edit this environment variables file, and then use it to generate
    an initramfs image:

    sh make_initramfs.sh --varsfile projectvars.txt --nohardlink --keepfiles

EOF
} # function show_examples () 

### BEGIN SCRIPT ###
# run getopt
TEMP=$(${GETOPT} -o hHenp:d:f:sb:o:qlk \
--long help,longhelp,examples,dry-run,project:,project-dir: \
--long varsfile:,showvars,base:,output:,quiet,hardlink \
--long keeplist,keepfiles,keep \
-n "${SCRIPTNAME}" -- "$@")
cmd_status $GETOPT $?

# Note the quotes around `$TEMP': they are essential!
# read in the $TEMP variable
eval set -- "$TEMP"

# ERRORLOOP is used to see if getopt has looped too many times
ERRORLOOP=1

# read in command line options and set appropriate environment variables
# if you change the below switches to something else, make sure you change the
# getopts call(s) above
while $TRUE; do
    case "$1" in
        -h|--help) # show the script options
            show_help # short options
            echo
            echo -n "Use '--longhelp' to see more help options, including "
            echo "environment variables. "
            echo "Use '--examples' to see examples of script execution"
            echo
            exit 0;;
        -H|--longhelp) # show the script options
            show_help # short options
            show_longhelp # environment variables
            show_examples # examples of script usage
            exit 0;;
        -e|--examples) # show the script options
            show_examples # short options
            echo -n "Use '--longhelp' to see all help options, including "
            echo "environment variables "
            exit 0;;
		-p|--project|--profile) # name of the project to use when 
            # creating an initramfs image 
			PROJECT_NAME=$2
            ERRORLOOP=$(($ERRORLOOP - 1));
            shift 2
	    	;; # --project
        -n|--dry-run) # don't create the initramfs image, only filelists
        	DRY_RUN=1
            ERRORLOOP=$(($ERRORLOOP - 1));
            shift
		    ;; # --dryrun
        -f|--varsfile) # read in environment variables from this file
            VARSFILE=$2
            ERRORLOOP=$(($ERRORLOOP - 1));
            shift 2
		    ;; # --verbose
        -s|--showvars) # list variables after reading them in
        	SHOWVARS=1
            ERRORLOOP=$(($ERRORLOOP - 1));
            shift
		    ;; # --quiet
		-b|--base) # base directory for project files and recipes
			BUILD_BASE=$2
            ERRORLOOP=$(($ERRORLOOP - 1));
            shift 2
    		;; # --base
		-d|--project-dir) # project directory, outside of the base dir above
			PROJECT_DIR=$2
            ERRORLOOP=$(($ERRORLOOP - 1));
            shift 2
    		;; # --project-dir
		-o|--output) # filename to write the initramfs file to; defaults to 
            # /boot/initramfs-$KERNEL_VER.cpio.gz if not specified
			OUTPUT_FILE=$2
            export OUTPUT_FILE
            ERRORLOOP=$(($ERRORLOOP - 1));
            shift 2
	    	;; # --output
        -q|--quiet) # don't output anything (unless there's an error)
        	QUIET=0
            ERRORLOOP=$(($ERRORLOOP - 1));
            shift
		    ;; # --quiet
        -l|--hardlink) # hardlink the new initramfs file to initrd for the
                    # update-grub script to work properly
        	HARDLINK_INITRD=1
            ERRORLOOP=$(($ERRORLOOP - 1));
            shift
		    ;; # --initrd
        -k|--keepfiles|--keeplist|--keep) # keep the initramfs file list 
        	KEEP_TEMP_DIR=1
            ERRORLOOP=$(($ERRORLOOP - 1));
            shift
		    ;; # --keep
        --) shift
            break
		    ;; # --
    esac
    # exit if we loop across getopts too many times
    ERRORLOOP=$(($ERRORLOOP + 1))
    if [ $ERRORLOOP -gt 4 ]; then
        echo "ERROR: too many getopts passes;" >&2
        echo "Maybe you have a getopt option with no branch?" >&2
        exit 1
    fi # if [ $ERROR_LOOP -gt 3 ];

done

# see if we just list variables and then exit
if [ $SHOWVARS ]; then
    show_vars
    exit 0
fi # if [ $SHOWVARS ]; then

# can't set both $PROJECT and $PROJECT_DIR
if [ "x$PROJECT_NAME" != "x" -a "x$PROJECT_DIR" != "x" ]; then
    echo "ERROR: can't set --project and --project-dir at the same time"
    exit 1
fi 

# verify the build directory exists
# the variable is hardcoded at the top of this script
echo -n "- Checking for build base directory (${BUILD_BASE}); "
if [ ! -d $BUILD_BASE ]; then
    echo "ERROR: build base directory doesn't exist"
    echo "(${BUILD_BASE})"
    exit 1
fi
echo "found!"

# if the project directory was used, see if it exists
if [ "x$PROJECT_DIR" != "x" ]; then
    echo -n "- Checking for project directory; "

    if [ ! -d $PROJECT_DIR ]; then
        echo "ERROR: --project-dir specified, but $PROJECT_DIR does not exist"
        exit 1
    fi # if [ ! -d $PROJECT_DIR ]
    echo "found!"
    echo "  Project directory: ${PROJECT_DIR}"
fi # if [ "x$PROJECT_DIR" != "x" ]

# if the project name was used, see if it exists
if [ "x$PROJECT_NAME" != "x" ]; then
    echo -n "- Checking for project '${PROJECT_DIR}' in base dir; "
    if [ ! -d $BUILD_BASE/builds/$PROJECT_NAME ]; then
        echo "ERROR: --project specified, but project directory "
        echo "ERROR: $BUILD_BASE/builds/$PROJECT_NAME does not exist"
        exit 1
    fi # if [ ! -d $BUILD_BASE/builds/$PROJECT_NAME ]
    echo "found!"
    # the project directory was passed in and it's valid
    # set it
    PROJECT_DIR=$BUILD_BASE/builds/$PROJECT_NAME
fi


# no sense in running if gen_init_cpio doesn't exist
if [ ! $DRY_RUN ]; then
    echo -n "- Checking for gen_init_cpio file; "
    # set up an error flag
    GENINITCPIO_ERROR=0
    if [ ! -e "/usr/src/linux/usr/gen_init_cpio" ]; then
        echo "Huh. gen_init_cpio doesn't exist"
        GENINITCPIO_ERROR=1
    elif [ ! -x "/usr/src/linux/usr/gen_init_cpio" ]; then
        echo "Huh. gen_init_cpio is not executable (mode 755)"
        GENINITCPIO_ERROR=1
    fi # if [ ! -x "/usr/src/linux/usr/gen_init_cpio" ]

    if [ $GENINITCPIO_ERROR -eq 1 ]; then
        echo "  (Please check gen_init_cpio file in /usr/src/linux/usr)" >&2
        echo "Can't build initramfs image... Exiting." >&2 
        exit 1
    fi # if [ $GENINITCPIO_ERROR -eq 1 ]
    echo "found!"
fi # if [ ! $DRY_RUN ]; then

# create a temp directory
TEMP_DIR=$(${MKTEMP} -d /tmp/tmp-initramfs.XXXXX) 
echo "- Created temporary directory '${TEMP_DIR}'"

### EXPORTS
# export things that were set up either in getopts or hardcoded into this
# script
export BUILD_BASE PROJECT_DIR TEMP_DIR FILELIST

# SOURCE! call set_vars to source the project file 
set_vars $PROJECT_DIR

# verify the output file can be written to
# $OUTPUT_FILE was either set in a profile or using --output
if [ "x$OUTPUT_FILE" != "x" ]; then
    $TOUCH $OUTPUT_FILE
    cmd_status $TOUCH $?
else 
    echo "=-=-=-=-=-=-=-=-=-=-=-=-=-="
    echo "ERROR: output file not set"
    echo "=-=-=-=-=-=-=-=-=-=-=-=-=-="
    echo
    show_vars
    exit 1
fi # if [ -n $OUTPUT_FILE ]

# create the project /init script and put it in the temporary directory
echo "# Begin $FILELIST; to make changes to this list, " >> $TEMP_DIR/$FILELIST
echo "# edit the source .txt file." >> $TEMP_DIR/$FILELIST
echo "# Filelist generated on $RFC_2822_DATE" >> $TEMP_DIR/$FILELIST
echo "# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=" >> $TEMP_DIR/$FILELIST

# create the new init.sh script, which will be appended to
# moved to the individual project files; some projects don't need the full
# init script, since they run from ramdisk instead (don't need stop scripts,
# switch_root, and need to exec /init)

#$TOUCH /$TEMP_DIR/init.sh
#sedify $BUILD_BASE/common/initscripts/_init.sh $TEMP_DIR/init.sh
# add the init script to the filelist
#echo "file /init /${TEMP_DIR}/init.sh 0755 0 0" >> $TEMP_DIR/$FILELIST

# copy all the desired recipie files first
for RECIPE in $(echo ${PACKAGES});
do
    # verify the recipe file exists
    # check in $PROJECT_DIR first; note this works even if $PROJECT_DIR is not
    # defined; if it's not defined, it will fail, and the check in $BUILD_BASE
    # will then be done
    if [ -r $PROJECT_DIR/recipes/$RECIPE.txt ]; then
        # project-specific recpie exists
        RECIPE_DIR="$PROJECT_DIR/recipes"
    else 
        if [ -r $BUILD_BASE/recipes/$RECIPE.txt ]; then
            # recipe exists in LACK recipes directory
            RECIPE_DIR="$BUILD_BASE/recipes"
        else
            # nope; delete the output file and exit
            echo "ERROR: ${RECIPE}.txt file does not exist in"
            echo "${BUILD_BASE}/recipes (common) directory or"
            echo "${PROJECT_DIR}/recipes (project-specific) directory"
            echo "- Deleting output file ${OUTPUT_FILE}"
            rm $OUTPUT_FILE
            if [ -z $KEEP_TEMP_DIR ]; then
                echo "- Deleting temporary directory ${TEMP_DIR}"
                rm -rf $TEMP_DIR
            fi # if [ -z $KEEP_TEMP_DIR ]
            exit 1
        fi
    fi # if [ -r $PROJECT_DIR/recipes/$RECIPE.txt ]
    # then do some searching and replacing; write the output file to FILELIST
    sedify $RECIPE_DIR/$RECIPE.txt $TEMP_DIR/$FILELIST
done 

# verify the initramfs recipe file exists
echo -n "- Checking for $FILELIST file in project directory; "
if [ ! -r $PROJECT_DIR/$FILELIST ]; 
then
    # nope; delete the output file and exit
    echo "ERROR: $FILELIST file does not exist in"
    echo "${PROJECT_DIR} directory"
    rm -rf $TEMP_DIR
    exit 1
fi
echo "found!"
echo "  ${PROJECT_DIR}/$FILELIST"


# then grab the project specific file, which should have the kernel modules
# and do some searching and replacing
sedify $PROJECT_DIR/$FILELIST $TEMP_DIR/$FILELIST

# include the list of files that we just generated as part of the initramfs
# image for future reference and debugging/troubleshooting
echo -n "file /boot/${FILELIST}.gz " \
    >> $TEMP_DIR/$FILELIST
echo "${TEMP_DIR}/${FILELIST}.gz 0644 0 0" >> $TEMP_DIR/$FILELIST

# compress the file list
$GZIP -c -9 $TEMP_DIR/$FILELIST > ${TEMP_DIR}/${FILELIST}.gz

# generate the initramfs image
if [ $QUIET -gt 0 ]; then
    EXTRA_CMDS="time "
fi

if [ $DRY_RUN ]; then
    # remove the empty initramfs file that was created earlier with 'touch'
    # leave both filelists (compressed and uncompressed)
    echo "- Deleting $OUTPUT_FILE,"
    echo "  as --dry-run should not create this file"
    rm $OUTPUT_FILE
    PERL_SCRIPT=$(cat <<'EOPS'
        my $counter = 0;
        while ( <> ) {
            $counter++;
            # skip comment lines
            next if ( $_ =~ /^#/ );
            next if ( $_ =~ /^$/ );
            chomp($_);
            # split the line up into fields
            @line = split(q( ), $_);
            if ( $line[0] eq q(dir) ) {
                # $line[1] should be the name of the directory
                print qq(WARN: missing directory : ) . $line[1] 
                    . qq(, line $counter\n)
                    unless ( -d $line[1] );
            } elsif ( $line[0] eq q(file) ) {
                print qq(WARN: missing file: ) . $line[2] 
                    . qq(, line $counter\n)
                    unless ( -e $line[2] );
            } elsif ( $line[0] eq q(slink) ) {
                print qq(WARN: missing symlink source: ) 
                    . $line[2] . qq(, line $counter\n)
                    unless ( -e $line[2] );
            } else {
                print qq(WARN: unknown filetype: ) . $line[0] 
                    . qq(, line: $counter\n);
            } # if ( $line[0] eq q(dir) )
        } # while ( <> )
EOPS)
    echo "Running perl script on $TEMP_DIR/$FILELIST"
    cat $TEMP_DIR/$FILELIST | perl -e "$PERL_SCRIPT" 

    # barks if the file is missing
    echo "- initramfs output directory is: ${TEMP_DIR}"
    echo "  Please delete it manually"
else
    # run the gen_init_cpio command, output to $OUTPUT_FILE
    eval $EXTRA_CMDS /usr/src/linux/usr/gen_init_cpio $TEMP_DIR/$FILELIST \
        | $GZIP -c -9 > $OUTPUT_FILE      
    if [ -z $KEEP_TEMP_DIR ]; then
        rm -rf $TEMP_DIR
    else 
        echo "initramfs temporary directory is: ${TEMP_DIR}"
        echo "Please delete it manually"
    fi # if [ -z $KEEP_TEMP_DIR ]; then
    if [ $HARDLINK_INITRD -gt 0 ]; then
        echo "Hardlinking $OUTPUT_FILE to initrd file"
        if [ -r /boot/initrd-$KERNEL_VER.gz ]; then
            rm /boot/initrd-$KERNEL_VER.gz
        fi #if [ -r /boot/initrd-$KERNEL_VER.gz ]
        ln $OUTPUT_FILE /boot/initrd-$KERNEL_VER.gz
    fi # if [ $HARDLINK_INITRD -gt 0 ]
fi # if [ $DRY_RUN ];

# if we got here, everything worked
exit 0

# *begin licence blurb*
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place, Suite 330, Boston, MA  02111-1307 USA

# vi: set sw=4 ts=4:
# end of line
