#!/bin/sh
time make "$@" 2>&1 | tee -a "$0.log"
