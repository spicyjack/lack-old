#!/bin/sh

if [ -d "/usr/src/linux" ]; then
    time /usr/src/linux/usr/gen_init_cpio \
    /home/brian/cvs/antlinux/builds/antlinux/initramfs-hello.txt \
    | gzip -c -9 > /boot/initramfs-hello.cpio.gz
else
    echo "Huh.  /usr/src/linux doesn't exist.  Exiting...."
    exit 1
fi
