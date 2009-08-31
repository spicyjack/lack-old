#!/opt/local/bin/perl

use strict;
use warnings;
use lib qq(..);
use AntBuild::FileInfo;
use Log::Log4perl;
use AntBuild::Pkg::DarwinPorts;
use AntBuild::Pkg::Rpm;

my $logger_conf = qq(log4perl.rootLogger = INFO, Screen\n)
    . qq(log4perl.appender.Screen = )
    . qq(Log::Log4perl::Appender::ScreenColoredLevels\n)
	. qq(log4perl.appender.Screen.stderr = 1\n)
    . qq(log4perl.appender.Screen.layout = PatternLayout\n)
    . q(log4perl.appender.Screen.layout.ConversionPattern = %d %p %m%n)
    . qq(\n);

Log::Log4perl::init(\$logger_conf);
my %modules = ( q(AntBuild::Pkg::DarwinPorts) => q(/opt/local/bin/port),
				q(AntBuild::Pkg::Rpm) => q(/bin/rpm) );

my $fileinfo = AntBuild::FileInfo->new(q(/usr/bin/ssh));

foreach ( keys(%modules) ) {
    my $version = $_->new($fileinfo, $modules{$_} );
	if ( defined $version && $version->can(q(get_version)) ) {
		if ( defined $version->get_version($modules{$_}) ) {
		    print $_ . q(: ) . $version->get_version($modules{$_}) . qq(\n);
		} else { 
			print $_ . qq(: version unavailable\n);
		}
	} else {
	 	print $_ . qq(: version unavailable\n);
	} # if ( $version->can(q(get_version)) )
} 
