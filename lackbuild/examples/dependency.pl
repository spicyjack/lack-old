#!/usr/bin/perl

# $Id: dependency.pl,v 1.20 2006-07-08 02:19:30 brian Exp $
# Copyright (c)2001 by Brian Manning
#
# dependency checking script

use strict;
use warnings;

# where is the toplevel AntBuild modules directory?
use lib qq(..); # this obviously breaks if directories are moved

# sitewide
BEGIN {
    # this is off by itself because it loads extra stuff
    eval "use Log::Log4perl qw(get_logger :levels);";
    die   " === ERROR: Log::Log4perl failed to load:\n" 
        . "     Do you have the Log::Log4perl module installed?\n"
        . "     Error output from Perl: $@" if $@;
    eval "use AppConfig;";
    die   " === ERROR: AppConfig failed to load:" 
        . "     Do you have the AppConfig module installed?\n"
        . "     Error output from Perl: $@" if $@;
} # BEGIN

# local
use AntBuild::FileDb 1.00;

### Begin Script ###

# create a config object with some default variables
my $Config = AppConfig->new();
	
# Help Options
$Config->define(q(help|h!));
# more script behaivor options 
$Config->define(q(debug|DEBUG|d=s@));
#$Config->define(q(verbose|v!));
$Config->define(q(testfile|tf|f=s));
$Config->define(q(package|pkg|p!));

# parse the command line
$Config->args(\@ARGV);

if ( $Config->get(q(help)) ) {
	&ShowHelp();
} # if ( $Config->get_help() || $Config->get_longhelp() )

# verify something was passed in as --testfile
die qq(ERROR: Missing a file to examine\n)
    . qq(Please pass a filename to be examined using the --testfile switch\n)
	unless ( defined $Config->get(q(testfile)));
die q(ERROR: Can't read file ') . $Config->get(q(testfile)) 
    . qq(', exiting...\n) unless ( -r $Config->get(q(testfile)));

# set up the logger
my $logger_conf = q(
	log4perl.rootLogger             = INFO, Screen
	log4perl.appender.Screen        = \
		Log::Log4perl::Appender::ScreenColoredLevels
	log4perl.appender.Screen.stderr = 1
	log4perl.appender.Screen.layout = PatternLayout
	log4perl.appender.Screen.layout.ConversionPattern = %d %p %m%n
);
#log4perl.appender.Screen.layout.ConversionPattern = %d %p> %F{1}:%L %M - %m%n

Log::Log4perl::init( \$logger_conf );
my $logger = get_logger("");

if ( @{$Config->get(q(debug))} > 0 ) {
	if ( grep(/all/, @{$Config->get(q(debug))}) ) {
    	$logger->level($DEBUG);

    } elsif ( grep(/info/, @{$Config->get(q(debug))}) ) {
    	$logger->level($INFO);
    } else {
		$logger->warn(q("DEBUG" switch turned on, but the debug string used));
		$logger->warn(qq(is not recognized));
	} # if ( grep(/all/, @{$Config->debug()}) )
} # if ( scalar($Config->debug()) > 0 )

$logger->debug("=============== Begin $0 ===============");

my $filedb = AntBuild::FileDb->new($Config);

# get_deps returns a list of file objects
my @dependencies = $filedb->get_file_deps( $Config->get(q(testfile)) );
my $savefile = $filedb->get_fileinfo(file => $Config->get(q(testfile)),
                                    attrib => q(filename));
if ( $Config->get(q(package)) ) {
	$logger->info( qq(The following files will be added to the package) );
	$logger->info( q(for file ) . $Config->get(q(testfile)) . q/ (/
            . $savefile . q/.zip): /);
} else {
	$logger->info( q(File ) . $Config->get(q(testfile))
		. q( has the following dependencies:));
}

# create an archive file with the basename of the file we went and got all of
# the dependencies for
foreach (@dependencies) {
	$logger->info(qq(\t) . $_);
    # add the file to the archive with a system call if package is set
    if ( $Config->get(q(package)) ) {
        system(q(/usr/bin/zip), $savefile . q(.zip), $_);
    } # if ( $Config->get(q(package)) )
} # foreach (@dependencies)

$logger->info(qq($0: found ) 
	. $filedb->get_dep_count($Config->get(q(testfile)))
    . q( dependencies total));
    
# FIXME put a message here about top 10 dependencies, and most cache hits
#
# end message
$logger->debug("=============== End $0 ===============");

exit 0;

############
# ShowHelp #
############
sub ShowHelp {
# shows the help message
    warn "\nUsage: $0 [options]\n";
    warn "[options] may consist of one or more of the following:\n";
    warn " -h|--help         show this help\n";
    warn " -d|--debug        run in debug mode (extra noisy output)\n";
    warn " -tf|--testfile    file to use for testing\n\n";
	exit 0;
} # sub ShowHelp

# vi: set ft=perl sw=4 ts=4 cin:
1;
