# ===== binutils_configure_runner.sh =====
#!/bin/sh
# run from inside the .obj-i486-linux-uclibc inside the binutils source dir
# install prefix
if [ -z $INSTALL_PREFIX ]; then
    echo "ERROR: missing INSTALL_PREFIX environment variable"
    exit 1
fi
SRC=..
# what's our current directory name?
CROSS=`basename "$PWD"`
# remove the .obj at the end
CROSS="${CROSS#.obj-}"
NAME=`cd $SRC;pwd`
# the full name of the install directory
NAME=`basename "$NAME"`-$CROSS

# target install directory
STATIC_TARGET=$INSTALL_PREFIX/$NAME
# target cross-compilation install directory
CROSS_TARGET=$INSTALL_PREFIX/cross

$SRC/configure \
--prefix=$STATIC_TARGET                        \
--exec-prefix=$STATIC_TARGET                   \
--bindir=/usr/bin                       \
--sbindir=/usr/sbin                     \
--libexecdir=$STATIC_TARGET/libexec            \
--datadir=$STATIC_TARGET/share                 \
--sysconfdir=/etc                       \
--sharedstatedir=$STATIC_TARGET/var/com        \
--localstatedir=$STATIC_TARGET/var             \
--libdir=/usr/lib                       \
--includedir=/usr/include               \
--infodir=/usr/info                     \
--mandir=/usr/man                       \
--oldincludedir=/usr/include            \
--target=$CROSS                         \
--with-sysroot=$CROSS_TARGET/$CROSS        \
--disable-rpath                         \
--disable-nls                           \
2>&1 | tee -a "$0.log"

# ===== binutils_make_install.sh =====
#!/bin/sh
# run from inside the .obj-i486-linux-uclibc inside the binutils source dir
# install prefix
if [ -z $INSTALL_PREFIX ]; then
    echo "ERROR: missing INSTALL_PREFIX environment variable"
    exit 1
fi
SRC=..
CROSS=`basename "$PWD"`
CROSS="${CROSS#.obj-}"
NAME=`cd $SRC;pwd`
# the full name of the install directory
NAME=`basename "$NAME"`-$CROSS

# target install directory
STATIC_TARGET=$INSTALL_PREFIX/$NAME
# target cross-compilation install directory
CROSS_TARGET=$INSTALL_PREFIX/cross

time sudo make \
prefix=$STATIC_TARGET                          \
exec-prefix=$STATIC_TARGET                     \
bindir=$STATIC_TARGET/bin                      \
sbindir=$STATIC_TARGET/sbin                    \
libexecdir=$STATIC_TARGET/libexec              \
datadir=$STATIC_TARGET/share                   \
sysconfdir=$STATIC_TARGET/var_template/etc     \
sharedstatedir=$STATIC_TARGET/var_template/com \
localstatedir=$STATIC_TARGET/var_template      \
libdir=$STATIC_TARGET/lib                      \
includedir=$STATIC_TARGET/include              \
infodir=$STATIC_TARGET/info                    \
mandir=$STATIC_TARGET/man                      \
install 2>&1 | tee -a "$0.log"

# ===== binutils_run_installlink.sh =====
#!/bin/sh
. ./installink.sh

NAME=`basename "$PWD"`
VER=-`echo $NAME | cut -d '-' -f 2-99`
NAME=`echo $NAME | cut -d '-' -f 1`
CROSS=`basename $PWD | cut -d '-' -f 3-99`
INSTALL_PREFIX="/home/cross"
# install prefix
if [ -z $INSTALL_PREFIX ]; then
    echo "ERROR: missing INSTALL_PREFIX environment variable"
    exit 1
fi
# target install directory
#STATIC_TARGET=$INSTALL_PREFIX/stow/$NAME$VER
echo "Creating links from ${INSTALL_PREFIX}/${NAME}${VER}"
STATIC_TARGET=$INSTALL_PREFIX/$NAME$VER
# target cross-compilation install directory
CROSS_TARGET=$INSTALL_PREFIX/cross

test "${STATIC_TARGET%$CROSS}" = "$STATIC_TARGET" && { 
    echo 'Wrong $CROSS in '"$0"; exit 1; 
}

mkdir -p $CROSS_TARGET/$CROSS/bin
mkdir -p $CROSS_TARGET/$CROSS/lib
# Don't want to deal with pairs of usr/bin/ and bin/, usr/lib/ and lib/
# in /usr/cross/$CROSS. This seems to be the easiest fix:
ln -s . $CROSS_TARGET/$CROSS/usr

# Do we really want to install tclsh8.4 and wish8.4 though? What are those btw?
link_samename_strip     /usr/bin                "$STATIC_TARGET/bin/*"
link_samename_strip     $CROSS_TARGET/$CROSS/bin   "$STATIC_TARGET/$CROSS/bin/*"
# elf2flt.ld and ldscripts/*. Actually seems to work just fine
# without ldscripts/* symlinked, but elf2flt does insist.
link_samename           $CROSS_TARGET/$CROSS/lib   "$STATIC_TARGET/$CROSS/lib/*"

# ===== gcc_configure_runner.sh =====
#!/bin/sh
CROSS=`basename "$PWD" | cut -d- -f3-99`
# gcc source directory
SRC=../`basename "$PWD" .obj-$CROSS`
NAME=`cd $SRC;pwd`
NAME=`basename "$NAME" .obj-$CROSS`-$CROSS
# install prefix
if [ -z $INSTALL_PREFIX ]; then
    echo "ERROR: missing INSTALL_PREFIX environment variable"
    exit 1
fi
# target install directory
STATIC_TARGET=$INSTALL_PREFIX/stow/$NAME
# target cross-compilation install directory
CROSS_TARGET=$INSTALL_PREFIX/cross

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
--with-local-prefix=/usr/local                  \
--with-slibdir=$STATIC/lib                      \
--target=$CROSS                                 \
--with-gnu-ld                                   \
--with-ld="/usr/bin/$CROSS-ld"                  \
--with-gnu-as                                   \
--with-as="/usr/bin/$CROSS-as"                  \
--with-sysroot=$CROSS_TARGET/$CROSS                \
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
--with-gmp                                      \
2>&1 | tee -a "$0.log"

# ===== gcc_make.sh =====
#!/bin/sh
CROSS=`basename "$PWD" | cut -d- -f3-99`
# install prefix
if [ -z $INSTALL_PREFIX ]; then
    echo "ERROR: missing INSTALL_PREFIX environment variable"
    exit 1
fi
# target install directory
STATIC_TARGET=$INSTALL_PREFIX/stow/$NAME
INSTALL_PREFIX=/usr/local
# target install directory
STATIC_TARGET=$INSTALL_PREFIX/stow/$NAME
# target cross-compilation install directory
CROSS_TARGET=$INSTALL_PREFIX/cross

# "The directory that should contain system headers does not exist:
# # /usr/cross/foobar/usr/include"
mkdir -p $CROSS_TARGET/$CROSS/usr/include

time make "$@" 2>&1 | tee -a "$0.log"

# ===== gcc_make_install.sh =====
#!/bin/sh
CROSS=`basename "$PWD" | cut -d- -f3-99`
SRC=../`basename "$PWD" .obj-$CROSS`
NAME=`cd $SRC;pwd`
NAME=`basename "$NAME" .obj-$CROSS`-$CROSS
INSTALL_PREFIX="/home/cross"
# install prefix
if [ -z $INSTALL_PREFIX ]; then
    echo "ERROR: missing INSTALL_PREFIX environment variable"
    echo "INSTALL_PREFIX is $INSTALL_PREFIX"
    exit 1
fi
# target install directory
STATIC_TARGET=$INSTALL_PREFIX/stow/$NAME
# target cross-compilation install directory
CROSS_TARGET=$INSTALL_PREFIX/cross

time make -k \
prefix=$STATIC_TARGET                          \
exec-prefix=$STATIC_TARGET                     \
bindir=$STATIC_TARGET/bin                      \
sbindir=$STATIC_TARGET/sbin                    \
libexecdir=$STATIC_TARGET/libexec              \
datadir=$STATIC_TARGET/share                   \
sysconfdir=$STATIC_TARGET/var_template/etc     \
sharedstatedir=$STATIC_TARGET/var_template/com \
localstatedir=$STATIC_TARGET/var_template      \
libdir=$STATIC_TARGET/lib                      \
includedir=$STATIC_TARGET/include              \
infodir=$STATIC_TARGET/info                    \
mandir=$STATIC_TARGET/man                      \
install 2>&1 | tee -a "$0.log"

# ===== gcc_run_installlink.sh =====
#!/bin/sh
. ./installink.sh

NAME=`basename "$PWD"`
VER=-`echo $NAME | cut -d '-' -f 2-99`
NAME=`echo $NAME | cut -d '-' -f 1`
CROSS=`basename $PWD | cut -d '-' -f 3-99`
INSTALL_PREFIX="/home/cross"
# install prefix
if [ -z $INSTALL_PREFIX ]; then
    echo "ERROR: missing INSTALL_PREFIX environment variable"
    exit 1
fi
# target install directory
STATIC_TARGET=$INSTALL_PREFIX/stow/$NAME$VER
# target cross-compilation install directory
CROSS_TARGET=$INSTALL_PREFIX/cross

test "${STATIC_TARGET%$CROSS}" = "$STATIC_TARGET" && { 
    echo 'Wrong $CROSS in '"$0"; exit 1; 
}

# Strip executables anywhere in the tree
# grep guards against matching files like *.o, *.so* etc
strip `find -perm +111 -type f | grep '/[a-z0-9]*$' | xargs`
# symlink binaries
link_samename_strip /usr/bin                "$STATIC_TARGET/bin/*"
# symlink libs
link_samename /opt/cross/$CROSS/lib         "$STATIC_TARGET/$CROSS/lib/*"
# symlink includes
link_samename /opt/cross/$CROSS/include/c++ "$STATIC_TARGET/$CROSS/include/c++/*"

# ===== generic_make.sh =====
#!/bin/sh
time make "$@" 2>&1 | tee -a "$0.log"

# ===== installink.sh =====
#!/bin/sh
# version 0.B

function link() {
    echo "Making $1 -> $2..."
    local answer=""
    test ! -L "$1" -a -d "$1" && {
    # Asked to make /a/b/c/d -> somewhere, but d exists and is a dir?!
    echo -n " $1 is a directory! I am confused.
I will create a symlink INSIDE it. Probably this isn't what you want.
Press <Enter>/[S]kip/Ctrl-C: "; read answer
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
    echo >>"$1" "cd '`dirname  \"$2\"`'"
    # above:     cd '/path to/exec img'"
    echo >>"$1" "exec './`basename \"$2\"`'" '"$@"'
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
        bn=`basename "$fn"`
        mkdir -p "$1" 2>/dev/null
        make_stub "$1/$bn" "$fn"
    fi
    done
}

function make_stub_samename_abs() {
    for fn in $2; do
        if test -e "$fn"; then
        bn=`basename "$fn"`
        mkdir -p "$1" 2>/dev/null
        make_stub_abs "$1/$bn" "$fn"
    fi
    done
}

function link_samename() {
    for fn in $2; do
        if test -e "$fn"; then
        bn=`basename "$fn"`
        mkdir -p "$1" 2>/dev/null
        link "$1/$bn" "$fn"
    fi
    done
}

function link_samename_strip() {
    strip $2
    for fn in $2; do
        if test -e "$fn"; then
        bn=`basename "$fn"`
        mkdir -p "$1" 2>/dev/null
        link "$1/$bn" "$fn"
    fi
    done
}

function link_samename_r() {
    for fn in $2; do
        if test -e "$fn"; then
        bn=`basename "$fn"`
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
    bn=`basename "$fn"`
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
        bn=`basename "$fn"`
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
        link=`linkname "$a"`
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
    link "$1/$a" "`pwd`/$a"
    done
    # for each dir: descend into
    for a in *; do
        if test ! -e "$a"; then break; fi
    if test -d "$a"; then
        mkdir -p "$1" 2>/dev/null
            link_man_r_gz "$1/$a" "`pwd`/$a"
    fi
    done
    )
}
# ===== kernel_make_config.sh =====
#!/bin/sh
make ARCH=i386 CROSS_COMPILE=i486-linux-uclibc- defconfig 2>&1 \
    | tee -a "$0.log"
ln -s asm-x86 include/asm
make ARCH=i386 CROSS_COMPILE=i486-linux-uclibc- headers_install 2>&1 \
    | tee -a "$0.log"

# ===== uclibc_make_install.sh =====
#!/bin/sh
{
    make install || exit 1
    make install_kernel_headers || exit 1
} 2>&1 | tee -a "$0.log"


# ===== uclibc_run_installlink.sh =====
#!/bin/sh
. ./installink.sh

NAME=`basename "$PWD"`
VER=-`echo $NAME | cut -d '-' -f 2-99`
NAME=`echo $NAME | cut -d '-' -f 1`
INSTALL_PREFIX="/home/cross"
# install prefix
if [ -z $INSTALL_PREFIX ]; then
    echo "ERROR: missing INSTALL_PREFIX environment variable"
    exit 1
fi
# target install directory
STATIC_TARGET=$INSTALL_PREFIX/stow/$NAME
# target cross-compilation install directory
CROSS_TARGET=$INSTALL_PREFIX/cross
CROSS=`echo $NAME$VER | cut -d- -f3-99`
ARCH=`echo $NAME$VER | cut -d- -f3 | sed -e 's/i.86/i386/'`

mkdir -p $CROSS_TARGET/$CROSS/lib
mkdir -p $CROSS_TARGET/$CROSS/include
# symlink libs
link_samename $CROSS_TARGET/$CROSS/lib     "$STATIC_TARGET/$ARCH/usr/lib/*"
# symlink includes
link_samename $CROSS_TARGET/$CROSS/include "$STATIC_TARGET/$ARCH/usr/include/*"
