#!/bin/sh

# script to set up a machine with the basics

# TODO 
# - set up linuxlogo by sed'ing /etc/inittab and doing 'telinit q'
# - set up lode-lat1u-16 font in /etc/console-tools/config
# - add nice header blocks in between sections
# - split up sections into either shell functions or separate files that can be
# run sysvinit style

PACKAGE_LIST="cvs linuxlogo screen stow sudo ssh vim vim-scripts wget"
RC_TARBALL_FILE="rcfiles.tar"
SPLASHSCREEN_FILE="sunspot_swedish-640x480.xpm.gz"
DEMO_URL="http://files.antlinux.com/linux/demo/"
TEMPDIR=/tmp/machine_setup
GRUB_DIR=/boot/grub

# external programs
APTITUDE=$(which aptitude)
WGET=$(which wget)
TAR=$(which tar)
CP=$(which cp)
CHMOD=$(which chmod)
MV=$(which mv)

# first, make sure we have an up-to-date package list
$APTITUDE update
$APTITUDE --assume-yes upgrade 

# install the packages needed to run a basic system
$APTITUDE install $PACKAGE_LIST

# create a working directory and go to it
mkdir -p $TEMPDIR
cd $TEMPDIR

# get the .rcfiles tarball and install
if [ ! -f $RC_TARBALL_FILE ]; then
	$WGET $DEMO_URL/$RC_TARBALL_FILE
fi
$TAR -xvf $RC_TARBALL_FILE
$CP -av .bashrc .vimrc .dir_colors ~
$MKDIR ~/.ssh
$CHMOD 700 ~/.ssh
$CP .ssh/authorized_keys ~/.ssh
$MV lode-lat1u-16.psf /usr/share/consolefonts

# get the splashscreen image and install
cd $GRUB_DIR
if [ ! -f $SPLASHSCREEN_FILE ]; then
	$WGET $DEMO_URL/$SPLASHSCREEN_FILE
fi

if [ ! -h splash.xpm.gz ]; then
	ln -s $SPLASHSCREEN_FILE splash.xpm.gz
fi 

# go home and exit
cd ~
exit 0
