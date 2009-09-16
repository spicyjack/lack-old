#!/bin/sh

# script to start X as user 'demo', with some extra housekeeping stuff

HOME_DIR="/home/demo"
STARTX="/usr/bin/startx"

# see if we even want to run X
if [ $(/bin/grep -c nox /proc/cmdline) -eq 0 ]; then
    # yep, run X; now do we want a normal or debug session?
    if [ $(/bin/grep -c DEBUG /proc/cmdline) -gt 0 ]; then
        # normal session
        cat /home/demo/xsession | sed "s/^#\(exec xterm.*\)$/\1/" \
            > $HOME_DIR/.xsession
    else
        # debug session
        cat /home/demo/xsession | sed "s/^#\(exec perl.*\)$/\1/" \
            > $HOME_DIR/.xsession
    fi
    # set the xsession file to be executable
    #chmod 755 $HOME_DIR/.xsession
    /bin/su -s /bin/sh -c "$STARTX" demo
else
    # nope, don't run x; just sleep for a day, as /sbin/init will keep
    # restarting this script if it exits
    sleep 86400
fi

exit 0
