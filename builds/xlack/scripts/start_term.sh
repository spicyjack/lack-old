#!/bin/sh

# script to start a terminal window
# FIXME mrxvt is not currently working; break it in the xlack image too
MRXVT="/usr/bin/nomrxvt"
XTERM="/usr/bin/xterm +sb"

    # launch mrxvt if it's available
    if [ -x $MRXVT ]; then
        $MRXVT -geometry +0-0 &
    else
        $XTERM -geometry +0-0 &
    fi
    TERM_PID=$!
    touch /tmp/terminal.$TERM_PID.pid
    # loop waiting for the terminal to exit
    while /bin/true;
    do
        sleep 1
        # the whole TERM_PID directory goes away when the process exits
        if [ ! -e /proc/$TERM_PID/cmdline ]; then
            break
        fi
    done

    # remove the 'PID' file
    rm /tmp/terminal.$TERM_PID.pid

    exit 0
