#!/usr/bin/env perl

use strict;
use warnings;

use constant {
# FIXME change these to "ANDable" values for later on
# sprintf "%lo", $perms;
# the leading zero makes it octal; do not remove
    S_IFSOCK => 0140000,
    S_IFLNK =>  0120000,
    S_IFREG =>  0100000,
    S_IFBLK =>  0060000,
    S_IFDIR =>  0040000,
    S_IFCHR =>  0020000,
    S_IFIFO =>  0010000,
    S_ISUID =>  0004000,
    S_ISGID =>  0002000,
    S_ISVTX =>  0001000,
}; # use constant

my $mode2 = 0100755;
my $mode = sprintf("%o", 0100755);
my $test2 = S_IFREG;
my $test = sprintf("%o", S_IFREG);
#my $sp = sprintf("%o", $mode & $test);
my $sp = $mode & $test;
my $sp2 = $mode2 & $test2;
print q(S_IFSOCK is ) . sprintf("%o", $test) . qq(\n);
#print q(mode and S_IFSOCK is ) 
#    . (sprintf("%o", $mode & $test)) == $test . qq(\n);
print qq( mode is $mode, sprintf is $sp test is $test\n);
print qq( mode2 is $mode2, sprintf2 is $sp2 test2 is $test2\n);
if ($test == $sp) {
    print qq(mode value matches test\n);
}
if ($test2 == $sp2) {
    print qq(mode2 value matches test2\n);
}

