#!/bin/sh

# $Id: _initscript_stub.sh,v 1.7 2009-07-23 22:05:47 brian Exp $
# Copyright (c)2007 Brian Manning <brian at portaboom dot com>

# PLEASE DO NOT E-MAIL THE AUTHOR ABOUT THIS SOFTWARE
# The proper venue for questions is the LACK mailing list at:
# http://groups.google.com/linuxack or <linuxack.googlegroups.com>

# picks up things like colorize()
if ! [ -e $LACK_FUNCTIONS ]; then
    LACK_FUNCTIONS="/etc/scripts/lack_functions.sh"
fi # if ! [ -e $LACK_FUNCTIONS ]
source $LACK_FUNCTIONS

ACTION=$1
BINARY=/bin/somebinary
[ -x "$BINARY" ] || exit 1
BASENAME=$(/usr/bin/basename $BINARY)
DESC="binary program"
BINARY_OPTS="-r -c"

case "$ACTION" in
  vars)
    # echo out what commandline variables are parsed by this script
    echo "${BASENAME}:"
    exit 0
  ;;
  start)
    colorize $S_TIP "${BASENAME}: Starting ${DESC}"
    $BINARY $BINARY_OPTS
    check_exit_status $? $BASENAME
    colorize_nl $S_SUCCESS "$SUCCESS"
    ;;
  stop)
    colorize $S_TIP "${BASENAME}: Stopping ${DESC}"
    ;;
  restart|force-reload)
     $0 stop
     $0 start
    ;;
  *)
    echo "Usage: $BASENAME {start|stop|restart|force-reload}" >&2
    exit 3
    ;;
esac

exit 0
# vi: set shiftwidth=4 tabstop=4 filetype=sh :
# конец!
