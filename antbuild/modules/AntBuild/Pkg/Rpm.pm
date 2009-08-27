package AntBuild::Pkg::Rpm;

# Copyright (c)2006 Brian Manning ( elspicyjack at gmail dot com )
# $Id: Rpm.pm,v 1.8 2006-08-24 02:14:21 brian Exp $

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

AntBuild::Pkg::Rpm

=head1 VERSION

The current version of this module is 1.00 (26Jul2006)

=cut

# see 'perldoc Exporter' for more dirt on Perl module versions
$VERSION=1.00;
#$VC_VERSION=q($Revision: 1.8 $ $Date: 2006-08-24 02:14:21 $);
use strict;
use warnings;
use Log::Log4perl qw(get_logger);
use AntBuild::Tools;
use AntBuild::Pkg::Common;
@AntBuild::Pkg::Rpm::ISA = qw(AntBuild::Tools AntBuild::Pkg::Common);

=pod 

=head1 DESCRIPTION

B<AntBuild::Pkg::Rpm> is a set of common methods and attributes used for
working with the system packaging tools on Red Hat and related systems.

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
    my $rpmpath = $args{q(rpmpath)} || q(/bin/rpm);
	
	if ( -x $rpmpath ) {
		# the RPM command lets you choose which fields are output, and in
		# whatever format/order you desire to put them in... yum!
	    my $cmd = $rpmpath . q( --query --queryformat )
			. q("%{NAME}:%{VERSION}:%{RELEASE}:%{ARCH}:%{LICENSE}\n" )
			. q(--file ) . $args{fullname} . q( 2>/dev/null);
	    my $cmdout = qx/$cmd/;
	    if ( $@ ) { $logger->error(qq(rpm system call returned: $@)) };

    	# $cmdout is now the output of the ports command
	    chomp($cmdout);
    
    	if ( $cmdout !~ /not owned by any package/ ) {
        	# split up the line on the colon<space> to get package name
	        my @splitcmd = split(/:/, $cmdout); 
    	    $this->set_name($splitcmd[0]);
	        $this->set_software_version($splitcmd[1]);
    	    $this->set_release_version($splitcmd[2]);
	        $this->set_arch($splitcmd[3]);
    	} else {
			# the file is not under RPM's control; the command output is
			# verbose enough to use directly
			$logger->warn($cmdout); 
			# return undef to let the caller know that something's up
			return undef;
	    } # if ( $cmdout =~ /provided by:/ ) 

    	return $this;
	} else {
		return undef;
	} # if ( -x $rpmpath )
} # sub new

=pod 

=item new(fullname => $fullname, rpmpath => $rpmpath)

Creates a new RPM pakcage object, which queries the RPM system for the name and
package information for the filename cointained inside of the B<fullname>
argument.  The full path to the C<rpm> command can be passed in via the
B<rpmpath> argument if desired.  The default path to the C<rpm> command is
'/bin/rpm'.

Returns a L<AntBuild::Pkg::Common> package object if the package could be
determined via the C<rpm> command, B<undef> if the package could not be
determined.  A warning will be output if the C<rpm> command returns a
non-standard response.

=cut

sub get_version {
    my ($this, $rpmpath) = @_;

    my $logger = get_logger();

    if ( -x $rpmpath ) {
        my $cmd = qq($rpmpath --version);
        my $rpm_version = qx/$cmd/;
        if ( $@ ) { $logger->error(qq(rpm system call returned: $@)) };
        chomp($rpm_version);
        $rpm_version =~ s/^RPM version //;
        return $rpm_version;
    } else {
        return undef;
    } # if ( -x $portspath )
} # sub get_version

=pod

=item get_version()

Returns the version information for the 'rpm' application.

=back 4

=head2 Private Methods and Variables

None at this time.

=head1 AUTHOR(S)

Brian Manning E<lt>elspicyjack at gmail dot comE<gt>

=cut 

# vi: set ft=perl sw=4 ts=4 cin:
1;
