#!/bin/bash

# script to dump a bunch of information about the system for debugging

# get the hostname if it's available
if [ -e /etc/hostname ]; then
    HOSTNAME=$(cat /etc/hostname)
else
    HOSTNAME="unknown_host"
fi

if [ -x "/bin/date" ]; then
    DATE_STR=$(date +%d%b%Y.%H%M)
else
    DATE_STR="unknown_date"
fi

OUT_FILE="/tmp/debug.${HOSTNAME}.${DATE_STR}.txt"
echo "===== Debugging information: ${DATE_STR} =====" > $OUT_FILE
echo >> $OUT_FILE

    ### disk information ###
    CDROM_DEV=$(/sbin/udevadm info --query=name --name=cdrom)
    for DISK in sda sdb sdc sdd sde sdf sdg hda hdb hdc hdd;
    do
        if [ "x${DISK}" = "x${CDROM_DEV}" ]; then
            # skip querying the CD ROM device
            continue
        fi
        if [ -b /dev/${DISK} ]; then
            VENDOR=$(cat /sys/block/${DISK}/device/vendor)
            MODEL=$(cat /sys/block/${DISK}/device/model)
            echo "### Disk vendor/model: ${VENDOR} - ${MODEL} ###" >> $OUT_FILE
            echo "--- fdisk: ${DISK} ---" >> $OUT_FILE
            /sbin/fdisk -l /dev/${DISK} >> $OUT_FILE
            /bin/echo >> $OUT_FILE
        fi
    done

    echo "### partition information ###" >> $OUT_FILE
    cat /proc/partitions | awk '{ print $4 }' \
        | grep -E "hd.[1-9]$|sd.[1-9]$" >> $OUT_FILE
    /bin/echo >> $OUT_FILE

    echo "### disk usage information ###" >> $OUT_FILE
    for MOUNT in $(cat /proc/mounts | grep -E '^/dev|^none' \
        | awk '{ print $2 }' | sort);
    do
        /bin/df $MOUNT | grep -v "Filesystem" >> $OUT_FILE
    done
    /bin/echo >> $OUT_FILE

    echo "### network information ###" >> $OUT_FILE
    /sbin/ifconfig -a >> $OUT_FILE
    /bin/echo >> $OUT_FILE
    /sbin/route -n >> $OUT_FILE
    /bin/echo >> $OUT_FILE

    if [ -x /usr/bin/dpkg ]; then
        echo "### package listing ###" >> $OUT_FILE
        #/usr/bin/dpkg -l >> $OUT_FILE
        cd /var/lib/dpkg/info/
        /bin/ls *.list | /bin/sed 's/\.list//' | sort >> $OUT_FILE
    fi

    if [ -x /sbin/lsmod ]; then
        echo "### Loaded kernel modules ###" >> $OUT_FILE
        # output the header first
        /sbin/lsmod | grep "^Module" >> $OUT_FILE 2>&1 
        # then sort everything else and output it after the header
        /sbin/lsmod | grep -v "^Module" | sort >> $OUT_FILE 2>&1
        /bin/echo >> $OUT_FILE
    fi

    if [ -x /usr/bin/lshw ]; then
        echo "### Hardware information ###" >> $OUT_FILE
        /usr/bin/lshw >> $OUT_FILE 2>&1
        /bin/echo >> $OUT_FILE
    fi

    if [ -x /usr/bin/lspci ]; then
        echo "### PCI bus information ###" >> $OUT_FILE
        /usr/bin/lspci -v >> $OUT_FILE 2>&1
        /bin/echo >> $OUT_FILE
    fi

    if [ -x /usr/sbin/lsusb ]; then
        echo "### USB bus information ###" >> $OUT_FILE
        /usr/sbin/lsusb -v >> $OUT_FILE 2>&1
        /bin/echo >> $OUT_FILE
    fi
