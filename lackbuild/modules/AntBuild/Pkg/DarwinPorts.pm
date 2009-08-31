package AntBuild::Pkg::DarwinPorts;

# Copyright (c)2006 Brian Manning ( elspicyjack at gmail dot com )
# $Id: DarwinPorts.pm,v 1.8 2006-08-24 02:14:21 brian Exp $

# common functions for other dependency modules to use

# FOR SUPPORT WITH THIS SOFTWARE, PLEASE VISIT THE PROJECT WEBPAGE at
#
# http://www.antlinux.com/antlinux/antbuild
#
# A list of support options (including a mailing list and FAQ) are available
# there.  E-mailing the author directly will result in a terse reply asking you
# to visit the above URL ;)

#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published
#    by the Free Software Foundation; version 2 dated June, 1991.

#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program;  if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111, USA.

=pod

=head1 NAME

AntBuild::Pkg::DarwinPorts

=head1 VERSION

The current version of this module is 1.00 (19May2006)

=cut

# see 'perldoc Exporter' for more dirt on Perl module versions
$VERSION=1.00;
use strict;
use warnings;
use Log::Log4perl qw(get_logger);
use AntBuild::Tools;
use AntBuild::Pkg::Common;
@AntBuild::Pkg::DarwinPorts::ISA = qw(AntBuild::Tools AntBuild::Pkg::Common);

=pod 

=head1 DESCRIPTION

B<AntBuild::Pkg::DarwinPorts> is a set of common methods and attributes used for
working with the system packaging tools. 
dependent module as B<$class::SUPER->new()> in order to correctly initialize.

=head2 Public Methods

=over 4

=cut
	
sub new {
    my $class = shift;

    # create the object with a bless
    my $this = bless ({}, ref($class) || $class);

    # get the logger object that matches whatver object type this method is
    # attached to
    my $logger = get_logger(ref($class) || $class);
	my %args = $this->_check_args(q(new), @_);

    $logger->debug(q(Entering ') . $class
        . qq('::new() with file\n') . $args{fullname} . q(') );

	# set a default just in case
	my $portspath = $args{portspath} || q(/opt/local/bin/port);
	
	if ( -x $portspath ) { 
	    my $cmd = qq($portspath provides ) 
    	    . $args{fullname} . q( 2>/dev/null);
	    my $port_prov = qx/$cmd/;
    	if ( $@ ) { $logger->error(qq(port system call returned: $@)) };

	    chomp($port_prov);
    
    	if ( $port_prov =~ /provided by:/ ) {
        	# split up the line on the colon<space> to get package name
	        my @splitcmd = split(/: /, $port_prov); 
    	    $cmd = qq($portspath info ) . $splitcmd[1];
        	$logger->debug(q('port info' call is:) . $cmd );
	        my @port_info = qx/$cmd/;
    	    if ( $@ ) { $logger->error(qq(port system call returned: $@)) };

	        # return the first line of the command output
    	    my $firstline = shift(@port_info);
	        # search forward in the output to the Platform string
    	    foreach ( @port_info ) {
            	chomp($_);
        	    if ( $_ =~ /^Platforms: (\w.)$/ ) {
	                $this->set_arch($1);
    	        } # if ( $_ =~ /^Platforms:/ )
        	} # foreach ( @port_info )
	        # split on comma<space>
			# WARNING: this doesn't always split the line evenly; further
			# parsing may be needed
			my @pkginfo = split(/, /, $firstline);
	        my @pkgnamever = split(/ /, shift(@pkginfo));
    	    # set the package name and software version from $pkginfo[0]
        	$this->set_name($pkgnamever[0]);
	        $this->set_software_version($pkgnamever[0]);
    	    # check if $pkginfo[1] is the package revision
	        if ( $pkginfo[0] =~ /Revision (\w.)/ ) {
    	        # regular expression isolates the package revision number 
	            $this->set_version($1);
	            # shift off the revision data
    	        shift @pkginfo;
        	} else {
	            # no package revision, set it to 0
    	        $this->set_version(0);
        	} # if ( $pkginfo[0] =~ /Revision/ )
	        if ( @pkginfo ) {
    	        # combine @pkginfo to get the rest of the package details 
        	    $this->set_miscinfo( join(q( ), @pkginfo) );
	        } # if ( defined @pkginfo )
    	} elsif ( $port_prov =~ /not provided by/ ) {
        	return undef;
	    } else {
    	    $logger->warn(ref($this) 
        	    . q(->new: ports command returned nonstandard response:)); 
	        $logger->warn(qq(\t) . $port_prov);
    	} # if ( $port_prov =~ /provided by:/ ) 
	    return $this;
	} else {
		return undef;
	} # if ( -x $portspath )
} # sub new

=pod 

=item new(fullname => $fullname, portspath => $portspath)

Creates a new DarwinPorts pakcage object, which queries the DarwinPorts system
for the name and package information for the filename contained inside of the
B<fullname> argument.  A path to the C<port> binary can be passed in as the
B<portspath> argument if desired.  The default C<port> path is
'/opt/local/bin/port'.

Returns a L<AntBuild::Pkg::Common> package object if the package could be
determined via the B<port> command, B<undef> if the package could not be
determined.  A warning will be output if the B<port> command returns a
non-standard response.

=cut

sub get_version {
    my ($this, $portarg) = @_; 

	# set a default just in case
	my $portspath = $portarg || q(/opt/local/bin/port);

    my $logger = get_logger();

	if ( -x $portspath ) {
	    my $cmd = qq($portspath version);
    	my $port_version = qx/$cmd/;
	    if ( $@ ) { $logger->error(qq(port system call returned: $@)) };
    	chomp($port_version);
	    $port_version =~ s/^Version: //;
    	return $port_version;
	} else {
		return undef;
	} # if ( -x $portspath )
} # sub get_version

=pod

=item get_version($portspath)

Returns the version information for the 'port' application.

=back 4

=head2 Private Methods and Variables

None at this time.

=head1 AUTHOR(S)

Brian Manning E<lt>elspicyjack at gmail dot comE<gt>

=cut 

# vi: set ft=perl sw=4 ts=4 cin:
1;
