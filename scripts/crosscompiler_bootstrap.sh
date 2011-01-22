#!/bin/sh
# crosscompiler_bootstrap.sh
# Most of this was taken from Denys Vlasenko's example at:
# http://busybox.net/~vda/HOWTO/i486-linux-uclibc/
# Changes to the original scripts are Copyright (c)2011 Brian Manning
# brian at portaboom dot com

# Notes:
# - problems building binutils-2.18
# http://anonir.wordpress.com/2010/02/05/linux-from-scratch-troubleshooting/

    # source common_release_functions.sh, so that just in case there's a
    # conflict with duplicate environment variables, the variables set after
    # sourcing common_release_functions.sh take precedence
    SCRIPT_DIR=$(dirname $0)
    echo "- SCRIPT_DIR is ${SCRIPT_DIR}"
    echo "- Checking for ${SCRIPT_DIR}/common_release_functions.sh"
    if [ -r ${SCRIPT_DIR}/common_release_functions.sh ]; then
        source ${SCRIPT_DIR}/common_release_functions.sh
    else
        echo "ERROR: can't find 'lack_functions.sh' script"
        echo "My name is: $0"
        exit 1
    fi # if [ -r ${SCRIPT_DIR}/lack_functions.sh ]

    # things we need to get from other places
    BASE_URL="http://xaoc.qualcomm.com/bb_xcomp"
    BINUTILS_VER="2.18"
    BINUTILS_FILE="binutils-${BINUTILS_VER}.tar.bz2"
    GCC_VER="4.3.1"
    GCC_FILE="gcc-${GCC_VER}.tar.bz2"
    UCLIBC_FILE="uclibc-20080607.svn.tar.bz2"
    BUSYBOX_FILE="busybox-20080607.svn.tar.bz2"

    # things used by this script
    #STATIC_DIR="/local/app"

    # locations of binaries used by this script
    TRUE=$(which true)
    GETOPT=$(which getopt)
    MV=$(which mv)
    CAT=$(which cat)
    RM=$(which rm)
    MKTEMP=$(which mktemp)
    GZIP=$(which gzip)
    SED=$(which sed)
    TOUCH=$(which touch)
    DATE=$(which date)
    RFC_2822_DATE=$(${DATE} --rfc-2822)

### BEGIN SCRIPT FUNCTIONS ###

## FUNC: link
function link() {
    echo "Making $1 -> $2..."
    local answer=""
    test ! -L "$1" -a -d "$1" && {
    # Asked to make /a/b/c/d -> somewhere, but d exists and is a dir?!
    echo -n " $1 is a directory! I am confused.
I will create a symlink INSIDE it. Probably this isn't what you want.
Press <Enter>/[S]kip/Ctrl-C: ";
    read answer
    }
    test "$answer" != s -a "$answer" != S && {
    ln -sfn "$2" "$1" || { echo -n " failed. Press <Enter>: "; read junk; }
    }
}

function make_stub() {
    echo "Making $1 -> $2..."
    rm -f "$1"
    # messy, isn't it? :-)
    echo  >"$1" "#!/bin/sh"
    echo >>"$1" "cd '$(dirname  \"$2\")'"
    # above:     cd '/path to/exec img'"
    echo >>"$1" "exec './$(basename \"$2\")'" '"$@"'
    # above:     exec './executable name' "$@"
    chmod a+x "$1"
}

function make_stub_abs() {
    echo "Making $1 -> $2..."
    rm -f "$1"
    echo  >"$1" "#!/bin/sh"
    echo >>"$1" "exec '$2'" "$@"
    chmod a+x "$1"
}

function make_stub_samename() {
    for fn in $2; do
        if test -e "$fn"; then
        bn=$(basename "$fn")
        mkdir -p "$1" 2>/dev/null
        make_stub "$1/$bn" "$fn"
    fi
    done
}

function make_stub_samename_abs() {
    for fn in $2; do
        if test -e "$fn"; then
        bn=$(basename "$fn")
        mkdir -p "$1" 2>/dev/null
        make_stub_abs "$1/$bn" "$fn"
    fi
    done
}

function link_samename() {
    for fn in $2; do
        if test -e "$fn"; then
        bn=$(basename "$fn")
        mkdir -p "$1" 2>/dev/null
        link "$1/$bn" "$fn"
    fi
    done
}

function link_samename_strip() {
    strip $2
    for fn in $2; do
        if test -e "$fn"; then
        bn=$(basename "$fn")
        mkdir -p "$1" 2>/dev/null
        link "$1/$bn" "$fn"
    fi
    done
}

function link_samename_r() {
    for fn in $2; do
        if test -e "$fn"; then
        bn=$(basename "$fn")
        if test -f "$fn"; then
            # File: Make link with the same name in $1
        mkdir -p "$1" 2>/dev/null
            link "$1/$bn" "$fn"
        elif test -d "$fn"; then
            # Dir: Descent into subdirs
        mkdir -p "$1" 2>/dev/null
            link_samename_r "$1/$bn" "$fn/*"
        fi
    fi
    done
}

function link_samename_r_strip() {
    strip $2
    for fn in $2; do
    bn=$(basename "$fn")
    if test -f "$fn"; then
        # File: Make link with the same name in $1
        mkdir -p "$1" 2>/dev/null
        link "$1/$bn" "$fn"
    elif test -d "$fn"; then
        # Dir: Descent into subdirs
        mkdir -p "$1" 2>/dev/null
        link_samename_r_strip "$1/$bn" "$fn/*"
    fi
    done
}

function link_samename_r_gz() {
    gzip -9 $2
    for fn in $2; do
        if test -e "$fn"; then
        bn=$(basename "$fn")
        if test -f "$fn"; then
            # File: Make link with the same name in $1
        mkdir -p "$1" 2>/dev/null
            link "$1/$bn" "$fn"
        elif test -d "$fn"; then
            # Dir: Descent into subdirs
        mkdir -p "$1" 2>/dev/null
            link_samename_r_gz "$1/$bn" "$fn/*"
        fi
    fi
    done
}

# usage: link_man_r_gz /usr/man /path/to/man
function link_man_r_gz() {
    # we'll work relative to /path/to/man
    ( cd "$2" || exit 1
    # process all manpages (gzip 'em)
    for a in *.[0123456789]; do
    if test -L "$a"; then
        link=$(linkname "$a")
        base=${link%.[0123456789]}
        if test "$link" != "$base"; then
        echo "Replacing link $a->$link by $a.gz->$link.gz"
        link "$a.gz" "$link.gz"
        rm "$a"
        else
        echo -n "Strange link: $a->$link. Ignored. Press <Enter>:"
        read junk
        continue
        fi
        elif test ! -e "$a"; then # this catches 'no *.n files here'
        break
    elif test -f "$a"; then
        rm "$a.gz"
        gzip -9 "$a"
    elif test -d "$a"; then
        continue
    else
        echo -n "Strange object: $a. Ignored. Press <Enter>:"
        read junk
        continue
    fi
    done
    # link all existing .gz
    for a in *.[0123456789].gz; do
        if test ! -e "$a"; then break; fi
    mkdir -p "$1" 2>/dev/null
    link "$1/$a" "$(pwd)/$a"
    done
    # for each dir: descend into
    for a in *; do
        if test ! -e "$a"; then break; fi
    if test -d "$a"; then
        mkdir -p "$1" 2>/dev/null
            link_man_r_gz "$1/$a" "$(pwd)/$a"
    fi
    done
    )
}

## FUNC: make_tempdir
function make_tempdir () {
    local START_DIR=$1

    if [ -e $START_DIR/stamp.tempdir ]; then
        BB_TEMP_DIR=$START_DIR
        echo "- Reusing temporary directory '${BB_TEMP_DIR}'"
    else
        # create a temp directory
        export BB_TEMP_DIR=$(${MKTEMP} -d ${START_DIR}/bb_temp_dir.XXXXX)
        check_exit_status $? "Creating temporary directory in ${START_DIR}"
        echo "- Created temporary directory '${BB_TEMP_DIR}'"
        touch ${BB_TEMP_DIR}/stamp.tempdir
    fi
    export BB_TEMP_DIR
} # make_tempdir ()

## FUNC: sudo_update_timestamp
function sudo_update_timestamp() {
    echo "SUDO access is usually required for installing cross-compile tools"
    echo "Will now run the command 'sudo -v' to update SUDO timestamp."
    echo "Please type your SUDO password when prompted,"
    echo "or hit Ctrl-C if you are unsure you want to run this script;"
    sudo -v
} # function sudo_stamp

## FUNC: generic_make
function generic_make () {
    local SRC_DIR=$1
    echo "======= generic_make =======" >> $BB_BUILD_LOG
    echo "changing directory to ${SRC_DIR}" >> $BB_BUILD_LOG
    cd $SRC_DIR
    make "$@" 2>&1 | tee -a $BB_BUILD_LOG
} # function generic_make

## FUNC: binutils_configure
function binutils_configure () {
    TOPLEVEL_DIR=$PWD
    echo "======= binutils_configure =======" >> $BB_BUILD_LOG
    echo "toplevel directory is ${TOPLEVEL_DIR}" >> $BB_BUILD_LOG
    if ! [ -d "binutils-${BINUTILS_VER}" ]; then
        wget -a $BB_BUILD_LOG $BASE_URL/$BINUTILS_FILE
        tar -jxvf $BINUTILS_FILE | tee -a $BB_BUILD_LOG
    fi
    echo "changing directory to binutils-${BINUTILS_VER}" >> $BB_BUILD_LOG
    cd binutils-${BINUTILS_VER}
    # if the .obj directory exists, we've been here before; don't run
    # configure
    if ! [ -e ${BB_TEMP_DIR}/stamp.binutils.configure ]; then
        mkdir .obj-i486-linux-uclibc
        cd .obj-i486-linux-uclibc
        # run configure
        SRC=..
        CROSS=$(basename "$PWD")
        # removes .obj- from the front of $CROSS
        CROSS="${CROSS#.obj-}"
        # the name of the output directory?
        NAME=$(cd $SRC;pwd)
        NAME=$(basename "$NAME")-$CROSS
        echo "- NAME is ${NAME}"
        STATIC_DIR=/local/app/$NAME
        echo "- Running ./configure for binutils" >> $BB_BUILD_LOG
        $SRC/configure \
            --prefix=$STATIC_DIR \
            --exec-prefix=$STATIC_DIR \
            --bindir=/usr/bin \
            --sbindir=/usr/sbin \
            --libexecdir=$STATIC_DIR/libexec \
            --datadir=$STATIC_DIR/share \
            --sysconfdir=/etc \
            --sharedstatedir=$STATIC_DIR/var/com \
            --localstatedir=$STATIC_DIR/var \
            --libdir=/usr/lib \
            --includedir=/usr/include \
            --infodir=/usr/info \
            --mandir=/usr/man \
            \
            --oldincludedir=/usr/include \
            --target=$CROSS \
            --with-sysroot=/usr/cross/$CROSS \
            --disable-rpath \
            --disable-nls \
            --enable-werror=no \
            2>&1 | tee -a $BB_BUILD_LOG
    else
        if [ -d .obj-i486-linux-uclibc ]; then
            cd .obj-i486-linux-uclibc
        else
            echo "ERROR: binutils stampfile exists, but directory"
            echo "ERROR: .obj-i486-linux-uclibc does not exist"
            exit 1
        fi # if [ -d .obj-i486-linux-uclibc ]
    fi # if ! [ -d .obj-i486-linux-uclibc ]
    touch ${BB_TEMP_DIR}/stamp.binutils.configure
    cd $TOPLEVEL_DIR
} # function binutils_configure

## FUNC: binutils_make_install
function binutils_make_install() {
    TOPLEVEL_DIR=$PWD
    echo "toplevel directory is ${TOPLEVEL_DIR}" >> $BB_BUILD_LOG
    if ! [ -e ${BB_TEMP_DIR}/stamp.binutils.make.install ]; then
        SRC=..
        CROSS=$(basename "$PWD")
        CROSS="${CROSS#.obj-}"
        NAME=$(cd $SRC;pwd)
        NAME=$(basename "$NAME")-$CROSS
        STATIC=/local/app/$NAME
        sudo make \
        prefix=$STATIC \
        exec-prefix=$STATIC \
        bindir=$STATIC/bin \
        sbindir=$STATIC/sbin \
        libexecdir=$STATIC/libexec \
        datadir=$STATIC/share \
        sysconfdir=$STATIC/var_template/etc \
        sharedstatedir=$STATIC/var_template/com \
        localstatedir=$STATIC/var_template \
        libdir=$STATIC/lib \
        includedir=$STATIC/include \
        infodir=$STATIC/info \
        mandir=$STATIC/man \
        install 2>&1 | tee -a $BB_BUILD_LOG
        touch $BB_TEMP_DIR/stamp.binutils.make.install
    else
        echo "- Skipping 'make install' for binutils; stampfile exists"
    fi
    cd $TOPLEVEL_DIR
} # function binutils_make_install ()

## FUNC: gcc_configure
function gcc_configure () {
    TOPLEVEL_DIR=$PWD
    echo "======= gcc_configure =======" >> $BB_BUILD_LOG
    echo "toplevel directory is ${TOPLEVEL_DIR}" >> $BB_BUILD_LOG
    if ! [ -d "gcc-${GCC_VER}.obj-i486-linux-uclibc" ]; then
        wget -a $BB_BUILD_LOG $BASE_URL/$GCC_FILE
        tar -jxvf $GCC_FILE | tee -a $BB_BUILD_LOG
        mkdir gcc-${GCC_VER}.obj-i486-linux-uclibc
    fi
    echo "changing directory to gcc-${GCC_VER}.obj-i486-linux-uclibc" \
        >> $BB_BUILD_LOG
    cd gcc-${GCC_VER}.obj-i486-linux-uclibc
    # if the .obj directory exists, we've been here before; don't run
    # configure
    if ! [ -e ${BB_TEMP_DIR}/stamp.gcc.configure ]; then
        # run configure
        CROSS=$(basename "$PWD" | cut -d- -f3-99)
        SRC=../$(basename "$PWD" .obj-$CROSS)
        NAME=$(cd $SRC;pwd)
        NAME=$(basename "$NAME" .obj-$CROSS)-$CROSS
        STATIC=/local/app/$NAME

        $SRC/configure \
        --prefix=$STATIC                                \
        --exec-prefix=$STATIC                           \
        --bindir=$STATIC/bin                            \
        --sbindir=$STATIC/sbin                          \
        --libexecdir=$STATIC/libexec                    \
        --datadir=$STATIC/share                         \
        --sysconfdir=/etc                               \
        --sharedstatedir=$STATIC/var/com                \
        --localstatedir=$STATIC/var                     \
        --libdir=$STATIC/lib                            \
        --includedir=$STATIC/include                    \
        --infodir=$STATIC/info                          \
        --mandir=$STATIC/man                            \
        --disable-nls                                   \
        \
        --with-local-prefix=/usr/local                  \
        --with-slibdir=$STATIC/lib                      \
        \
        --target=$CROSS                                 \
        --with-gnu-ld                                   \
        --with-ld="/usr/bin/$CROSS-ld"                  \
        --with-gnu-as                                   \
        --with-as="/usr/bin/$CROSS-as"                  \
        \
        --with-sysroot=/local/cross/$CROSS                \
        \
        --enable-languages="c"                          \
        --disable-shared                                \
        --disable-threads                               \
        --disable-tls                                   \
        --disable-multilib                              \
        --disable-decimal-float                         \
        --disable-libgomp                               \
        --disable-libssp                                \
        --disable-libmudflap                            \
        --without-headers                               \
        --with-newlib                                   \
        \
        2>&1 | tee -a $BB_BUILD_LOG
    fi # if ! [ -e ${BB_TEMP_DIR}/stamp.gcc.configure ]
    touch ${BB_TEMP_DIR}/stamp.gcc.configure
    cd $TOPLEVEL_DIR
} # function binutils_configure

### MAIN SCRIPT ###
make_tempdir $1
sudo_update_timestamp
# things we need to use for this script
export BB_BUILD_LOG="${BB_TEMP_DIR}/build.log"
: > $BB_BUILD_LOG
cd $BB_TEMP_DIR
binutils_configure
generic_make binutils-${BINUTILS_VER}
binutils_make_install
gcc_configure
