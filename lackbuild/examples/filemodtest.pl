#!/usr/bin/perl

# $Id: filemodtest.pl,v 1.19 2006-08-12 06:51:39 brian Exp $
# Copyright (c)2001 by Brian Manning
#
# tester for the File.pm module

use strict;
use warnings;

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
use AntBuild::FileInfo 1.00;

### Begin Script ###

# create a config object with some default variables
my $Config = AppConfig->new();
	
# Help Options
$Config->define(q(help|h!));
# more script behaivor options 
$Config->define(q(debug|DEBUG|d=s@));
#$Config->define(q(verbose|v!));
$Config->define(q(testfile|tf|f=s));

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
#	log4perl.rootLogger             = DEBUG, Screen

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

$logger->info("============ Begin $0 ============");

my $file = AntBuild::FileInfo->new($Config->get(q(testfile)));
$file->dump_attribs();

$logger->info(q(File ) . $Config->get(q(testfile)) . q( is a regular file))
    if $file->is_S_IFREG();
$logger->info(q(File ) . $Config->get(q(testfile)) . q( is a directory))
    if $file->is_S_IFDIR;
$logger->info(q(File ) . $Config->get(q(testfile)) . q( is a SUID binary))
    if $file->is_S_ISUID;
$logger->info(q(File ) . $Config->get(q(testfile)) . q( is sticky))
    if $file->is_S_ISVTX;
$logger->info(q(File ) . $Config->get(q(testfile)) . q( is executable by user))
    if $file->is_S_USREX;
$logger->info(q(File ) . $Config->get(q(testfile)) . q( is executable by group))
    if $file->is_S_GRPEX;
$logger->info(q(File ) . $Config->get(q(testfile)) . q( is executable by other))
    if $file->is_S_OTHEX;
$logger->info(q(File ) . $Config->get(q(testfile)) . q( is writeable by user))
    if $file->is_S_USRWR;

# end message
$logger->info("============ End $0 ============");

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
# end of line
1;
