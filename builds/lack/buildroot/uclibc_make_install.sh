#!/bin/sh
{
    make install || exit 1
    make install_kernel_headers || exit 1
} 2>&1 | tee -a "$0.log"


