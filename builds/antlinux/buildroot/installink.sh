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
