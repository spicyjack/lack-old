#!/bin/sh
make ARCH=i386 CROSS_COMPILE=i486-linux-uclibc- defconfig 2>&1 \
    | tee -a "$0.log"
ln -s asm-x86 include/asm
make ARCH=i386 CROSS_COMPILE=i486-linux-uclibc- headers_install 2>&1 \
    | tee -a "$0.log"

