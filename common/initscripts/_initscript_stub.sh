#! /bin/sh

# $Id: _initscript_stub.sh,v 1.7 2009-07-23 22:05:47 brian Exp $
# Copyright (c)2007 Brian Manning <elspicyjack at gmail dot com>

# picks up things like colorize()
source $ANT_FUNCTIONS

PATH=/sbin:/bin  # No remote fs at start
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
    cmd_status $?
    colorize_nl $S_SUCCESS "$SUCCESS"
	;;
  stop)
	PATH=/bin:/sbin:/usr/bin:/usr/sbin
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

:
