#!/bin/sh

# script for making an ISO filesystem, for CD burning

VERSION="2009.5"
INPUT_DIR=/opt/sourcecode/blank_mbr_iso
#cp $0 $INPUT_DIR/isolinux/mkisoimg.sh
RELEASE_DATE=$(/bin/date +%d%b%Y | tr -d '\n')

MKISOFS=$(which mkisofs)

$MKISOFS -r -J -v \
-A "Partition Table Nuker! - ${RELEASE_DATE}" \
-publisher "http://code.google.com/p/psas" \
-p "Brian Manning" \
-V "MBR_BLANKER-$RELEASE_DATE" \
-c isolinux/boot.cat \
-b isolinux/isolinux.bin \
-no-emul-boot -boot-load-size 4 -boot-info-table \
-o blank_mbr.$RELEASE_DATE.iso \
$INPUT_DIR

# -A Specifies  a  text string that will be written into
#	the volume header.  This should describe the appli-
#	cation that will be on the disc.
# -J Generate Joliet directory records  in  addition  to
#	regular iso9660 file names.
# -o is the name  of  the  file  to  which  the  iso9660
#	filesystem  image should be written.
#  -v Verbose execution.
# -r     This  is like the -R option, but file ownership and
# modes are set to more useful values.
# -R     Generate  SUSP  and RR records using the Rock Ridge
# protocol to  further  describe  the  files  on  the
# iso9660 filesystem.
# -T     Generate  a file TRANS.TBL in each directory on the
# CDROM, which can be used on non-Rock Ridge  capable
# systems  to  help establish the correct file names.
# -b boot_image
# Specifies  the  path and filename of the boot image
# to be used when making an "El Torito" bootable  CD.
# -c boot_catalog
# Specifies the path and filename of the boot catalog
# to  be used when making an "El Torito" bootable CD.
# This file will be  created  bymkisofs  in  the  source filesystem,
#  so be sure the specified filename does not conflict with an exist-
#  ing  file,  as it will be quietly overwritten!

# -r -T -v | Rock Ridge, Trans.Tbl, and verbose	 
# -A | Application name
# -P | Publisher ID
# -p | Person responsible
# -x | exclude file/directory
# -b | boot image is boot.img
# -c | catalog file created	
# -o | ISO image to create
# directory or file to create it from	 

