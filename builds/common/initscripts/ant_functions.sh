#!/bin/sh

# $Id: ant_functions.sh,v 1.8 2009-08-01 07:06:37 brian Exp $
# Copyright (c)2004 Brian Manning <elspicyjack at gmail dot com> 

# Essential functions for booting/running an Antlinux install

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA 

# TODO
# - detect whether or not we should be using ANSI color strings or not
# - add a logger using tee, or just write the message to a file somewhere;
# - maybe parse the console kernel boot argument to see if a serial console was
# specified

# initialize some variable defaults
PATH="${PATH}:/bin:/sbin:/usr/bin:/usr/sbin"
# this should already be set by the time this script is called; if it's not
# exported somewhere else, then uncomment the next line
#BB="/bin/busybox"

# color control strings
START="["
END="m"

# some common message strings
SUCCESS=" success."
FAILED=" failed."

# text attributes
NONE=0; BOLD=1; NORM=2; BLINK=5; INVERSE=7; CONCEALED=8

# background colors
B_BLK=40; B_RED=41; B_GRN=42; B_YLW=43
B_BLU=44; B_MAG=45; B_CYN=46; B_WHT=47

# foreground colors
F_BLK=30; F_RED=31; F_GRN=32; F_YLW=33
F_BLU=34; F_MAG=35; F_CYN=36; F_WHT=37

# some shortcuts
S_SUCCESS="${BOLD};${F_GRN};${B_BLK}"
S_FAILURE="${BOLD};${F_RED};${B_BLK}"
S_INFO="${F_BLK};${B_CYN}"
S_TIP="${BOLD};${F_BLU};${B_BLK}"
T_SUCCESS="${BOLD};${F_WHT};${B_GRN}"
T_FAILURE="${BLINK};${F_YLW};${B_RED}"
T_INFO="${INVERSE};${F_WHT};${B_BLU}"
T_TIP="${CONCEALED};${F_BLK};${B_WHT}"

colorize () {
# colorize some text; $1 == color tag(s), $2 == text to colorize
	$BB echo -n "${START}${1}${END}${2}${START};${NONE}${END}"
} # colorize()

colorize_nl () {
# same as colorize(), but with a newline added at the end
    colorize "${1}" "${2}"
    $BB echo
} # colorize_nl() 

pause_prompt () {
# function to pause script execution and prompt for user input to continue
    if [ "x${PAUSE_PROMPT}" != "x" ]; then
        echo -n " -PAUSED-  Hit <ENTER> to continue..."
        read ANSWER
    fi # if [ "x${PAUSE_SCRIPT}" != "x" ]; then 
} # function script_pause ()

cmd_status () {
# check the status of the last run command; run a shell if it's anything but 0
    STATUS=$1
    COMMAND=$2
    if [ "x$COMMAND" == "x" ]; then COMMAND="unknown"; fi
    if [ $STATUS -ne 0 ]; then
        echo
        colorize $S_FAILURE "Command '$COMMAND' failed with status code: "
        colorize_nl $S_INFO ">${STATUS}<"
        # removed the 'case' statement here, exec'ing the console from this
        # script was lame
        want_shell
    fi
} # cmd_status

want_shell () {
# run a shell (only if $DEBUG is set)
    if [ $DEBUG ]; then
        colorize $S_INFO "Execute debug shell? [Y/n] "
        read ANSWER
        if [ "x${ANSWER}" != "xn" -a "x${ANSWER}" != "xN" ]; then
            $BB stty sane
            $BB echo; $BB echo
            colorize_nl $S_SUCCESS "Running /bin/sh (NetBSD ash Shell)"
            exec /bin/sh 
            exit 1 # shouldn't get here
        fi # if [ "${ANSWER}" = "y" -o "${ANSWER}" = "Y" ];
    fi # if [ $DEBUG ]
} # want_shell()

file_parse () {
# parse a file $1, looking for search string found in $2
    PARSE_FILE=$1
    SEARCH_STRING=$2
    # reset the parsed flag; must do this here instead of inside the for loop,
    # or PARSED will get overwritten with each failure, which could happen
    # after the successful grep
    PARSED=''
    if [ $DEBUG ]; then 
        $BB echo "-> file_parse - searching file ${PARSE_FILE}"
        $BB echo "-> file_parse - for search string '${SEARCH_STRING}'";
    fi # if [ $DEBUG ]

    for LINE in $(${BB} cat ${PARSE_FILE}); do
        if [ $DEBUG ]; then $BB echo "  - searching string '${LINE}'"; fi
        $BB echo $LINE | $BB grep "^${SEARCH_STRING}=" > /dev/null
        if [ $? -eq 0 ]; then
            if [ $DEBUG ]; then
                $BB echo "-> found ${SEARCH_STRING} for ${LINE}"; 
            fi # if [ $DEBUG ]
            PARSED=$(${BB} expr "${LINE}" : '.*=\(.*\)')
            if [ $DEBUG ]; then $BB echo "-> setting PARSED to '${PARSED}'"; fi
            break
        fi  
    done
    if [ $DEBUG ]; then echo "-> parsed string is ${PARSED}"; fi
} # cmdline_parse()

get_kernel_version () {
# grab the kernel version and export it into the environment as shell
# variables
    colorize $TIP "- Determining Linux Kernel Version Number"; echo
    # run uname, cut off everything after the '-' dash character
    KERNEL_VER_STRING=$(/bin/uname -r | /usr/bin/cut -d'-' -f 1)
    # find the major version with cut
    KERNEL_MAJOR=$(/bin/echo $KERNEL_VER_STRING | /usr/bin/cut -d'.' -f 1)
    # find the patchlevel with cut
    KERNEL_MINOR=$(/bin/echo $KERNEL_VER_STRING | /usr/bin/cut -d'.' -f 2)
    # find the sublevel with cut
    KERNEL_PATCH_VERSION=$(/bin/echo $KERNEL_VER_STRING \
        | /usr/bin/cut -d'.' -f 3)
} # get_kernel_version()

write_child_pid () {
# write a PID file for scripts/programs that don't make their own
    CHILD_BINARY=$1
    CHILD_PID=$2
    echo $CHILD_PID > /var/run/${CHILD_BINARY}.pid
} # write_child_pid()

get_pid () {
# grab a program's PID file; use this after starting the program
    BINARY=$1
    CHILD_PID=$(/bin/ps | /bin/grep ${BINARY} | /bin/grep -v grep \
        | /usr/bin/awk '{print $1}')
} # get_pid () 

get_hostname () {
# get the hostname from the file set in the initramfs image
    if [ -e "/etc/hostname" ]; then
        HOSTNAME=$(/bin/cat /etc/hostname | /usr/bin/tr -d '\n')
    else 
        colorize_nl $S_FAILURE "ERROR: missing '/etc⁄hostname' file"
    fi
} # get_hostname () 
