#!/bin/sh

# $Id: _init.sh,v 1.53 2009-08-01 05:57:33 brian Exp $
# Copyright (c)2003 Brian Manning (elspicyjack at gmail dot com)
# License terms at the bottom of this file

# System bootstrapping script.  This script will
# 1) boot the system
# 2) Run the symlinked scripts in /etc/boot in SYSV init order
# 3) The scripts in /etc/boot are supposed to do things like mount encrypted
# volumes or mount the root partition from an LVM volume (if LVM volume is
# passed in from /proc/cmdline)
# 4) The call to switch_root that is run at the end of this script should
# transfer control to the /sbin/init binary found on that freshly-mounted
# filesystem. 

# begin busybox setup; from here on down, you need to use the full path to
# busybox, along with the name of the module you want to run, as the busybox
# symlinks don't exist (yet)

# also, if you add binaries to the image that would live in the same place as a
# busybox applet (example, losetup binary and losetup busybox applet), then you
# need to use the full path to the binary in any script called from here, as
# the busybox applet will be run if there is no path to the binary

# TODO 
# - detect if the script output is going to a serial console or not, and adjust
# calls to colorize() accordingly
# - create a script parameter called $LOG_COMMAND, and have $LOG_COMMAND be
# either the 'tee' command or a cat command; this will allow the script to
# print the command output to the screen or a logfile and the screen at the
# same time

## EXPORTS 
# set a serial port for use in the subscripts for writing output so users
# connected to serial console can see what's happening
# FIXME sed/awk this out of /proc/cmdline, the 'console' tags
export SERIAL_PORT="/dev/ttyS0"
# log file to write messages to
export BOOT_LOG="/var/log/boot.log"
# common functions used by all scripts
export ANT_FUNCTIONS="/etc/ant_functions.sh"
# path to busybox
export BB="/bin/busybox"

# source the functions script.  this is where colorize(), cmd_status(),
# want_shell() and file_parse() is coming from
source $ANT_FUNCTIONS

# show the header first
$BB clear
colorize_nl $S_INFO "=== Begin :PROJECT_NAME: /init script: PID is ${$} ==="

# run some of the init scripts by hand to set up the runtime environment
$BB sh /etc/init.d/loadfont start
$BB sh /etc/init.d/remount_rootfs start
$BB sh /etc/init.d/bb_install start
$BB sh /etc/init.d/procfs start
$BB sh /etc/init.d/sysfs start
$BB sh /etc/init.d/udev start
# do these by hand, otherwise we won't get the chance to pause running scripts
# later (no keyboard to pause with)
# FIXME have some way to detect whether these should be run by hand at the
# beginning or not; maybe a debug script that calls all of these?
# if [ $DEBUG ]; then
#   run all of the below init scripts
#$BB sh /etc/init.d/makedevs start
$BB sh /etc/init.d/syslogd start
$BB sh /etc/init.d/klogd start
#$BB sh /etc/init.d/usb_modules start

# now that procfs is mounted, we can actually parse /proc/cmdline
file_parse "/proc/cmdline" "DEBUG"
export DEBUG=$PARSED
if [ "x$DEBUG" != "x" ]; then
    echo "= DEBUG environment variable exists and is not empty;"
    echo "= Prompts will be given at different times to allow"
    echo "= for halting the startup process in order to drop to a shell."
    echo "= Boot process will log to /var/log/debugboot.log."
    echo "(DEBUG=${DEBUG})"
    want_shell
fi # if [ "x$DEBUG" != "x" ];

# do we want to stop in between scripts?
file_parse "/proc/cmdline" "pause"
export PAUSE_PROMPT=$PARSED

# this will run all of the start scripts in order
# HINT: if you want to run init here, instead of exec'ing switch_root below,
# then add bbinit to your initscript list in your <project>_base.txt file
for INITSCRIPT in /etc/start/*; do
    if [ "x$DEBUG" = "x" ]; then
    	# no debugging, the default
    	sh $INITSCRIPT start 2>>$BOOT_LOG
    else
    	# debugging, turn on sh -x
        colorize_nl $S_TIP "- Running 'sh -x $INITSCRIPT start'"
    	sh -x $INITSCRIPT start 2>&1 >> /var/log/debugboot.log
    fi	
    cmd_status $? $INITSCRIPT
    # was a pause asked for?
    pause_prompt
done

# we can't run bbinit as it's own script without exec'ing it
file_parse "/proc/cmdline" "run" # returns any parsed data as $PARSED
RUN_PROG=$PARSED
if [ "x$RUN_PROG" != "x" ]; then
    colorize_nl $S_TIP "init: all scripts in /etc/start have been run"
    colorize_nl $S_TIP "init: 'run=???' requested on the command line"
    colorize_nl $S_TIP "init: exec()'ing 'run_program' script"
    exec /etc/init.d/run_program start
else
    colorize_nl $S_TIP "init: 'run=' parameter not specified on command line;"
    colorize_nl $S_TIP "init: continuing with the boot process"
fi

# this will run all of the stop scripts in order to prep before exec'ing the
# system's init binary
for INITSCRIPT in /etc/stop/*; do
    sh $INITSCRIPT stop
    cmd_status $? $INITSCRIPT
done

colorize_nl $S_INFO "=== End :PROJECT_NAME: /init script ==="
colorize_nl $S_TIP "- Running switch_root from initramfs ${PWD}"

# one more last chance to pause and view output
pause_prompt # pause=X on /proc/cmdline
want_shell # DEBUG=X on /proc/cmdline

# switch_root will delete all of the files in the root filesystem, then mount
# the correct root filesystem where the old root filesystem used to be
# needs the exec() call to inherit the PID of 1
exec switch_root -c /dev/console /mnt/rootvol /sbin/init
# we lost busybox builtins when we unmounted /proc; do this the long way
if [ $? -gt 0 ]; then
    colorize_nl $S_FAILURE "switch_root failed!"
    # call cmd_status with a status code that will cause the script to exit to
    # a shell; don't prompt the user, once we go past here, we'll get a kernel
    # panic
    cmd_status 2 "switch_root"
fi

### begin license
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place, Suite 330, Boston, MA  02111-1307 USA

# end of line
