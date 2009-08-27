package AntBuild::Pkg::Deb;

# Copyright (c)2006 Brian Manning ( elspicyjack at gmail dot com )
# $Id: Deb.pm,v 1.11 2006-08-24 02:14:21 brian Exp $

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

AntBuild::Pkg::Deb

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
@AntBuild::Pkg::Deb::ISA = qw(AntBuild::Tools AntBuild::Pkg::Common);

=pod 

=head1 DESCRIPTION

B<AntBuild::Pkg::Deb> is a set of common methods and attributes used for
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
    my $dpkgpath = $args{q(dpkgpath)} || q(/usr/bin/dpkg);

    my $cmd = $dpkgpath . q( -S ) . $args{fullname} . q( 2>/dev/null);
    my $dpkg_search = qx/$cmd/;
    if ( $@ ) { $logger->error(qq(dpkg system call returned: $@)) };

    chomp($dpkg_search);
    
    # if we didn't see 'not found', then our file belongs to a package
    if ( $dpkg_search !~ /not found/ ) {
        # split up the line on the colon<space> to get package name
        my @split_dpkg = split(/: /, $dpkg_search); 
        # set the name of the package now; for some reason, dpkg doesn't print
        # the 'Package:' line when it's not run interactively
        $this->set_name($split_dpkg[0]);
        # build the dpkg command
        $cmd =  $dpkgpath . q( -p ) . $split_dpkg[0];
        $logger->debug(q('dpkg -p' call is:) . $cmd );
        my @dpkg_query = qx/$cmd/;
        if ( $@ ) { $logger->error(qq(dpkg system call returned: $@)) };
        #chomp(@dpkg_query);
        # return the first line of the command output
        my $firstline = shift(@dpkg_query);
        # search forward in the output to the Platform string
        foreach ( @dpkg_query ) {
            $logger->debug(q(dpkg line is: ) . $_);
            chomp($_);
	        SWITCH: {
    	        if ( $_ =~ /^Architecture: (\w+)$/ ) {
                    $logger->debug(qq(Architecture name: $1));
        	        $this->set_arch($1);
            	    last SWITCH;
	            } # if ( $_ =~ /^Platforms:/ )
    	        if ( $_ =~ /^Version: ([\w\-_].*)$/ ) {
                    $logger->debug(qq(Version info: $1));
					my @version = split(/-/, $1);
                    $version[0] =~ s/^.*://;
                    $this->set_source_version($version[0]);
                    $version[1] =~ s/-//;
                    $this->set_distro_version($version[1]);

                	last SWITCH;
	            } # if ( $_ =~ /^Platforms:/ )
    	    } # SWITCH
        } # foreach ( @dpkg_query )
    } else {
        return undef;
    } # if ( $dpkg_search !~ /not found/ ) 

    return $this;
} # sub new

=pod 

=item new(fullname => $fullname, dpkgpath => $dpkgpath)

Creates a new Deb pakcage object, which queries the Debian system for the name
and package information for the filename cointained inside of the B<fullname>
argument.  A path to the C<dpkg> binary can also be supplied as the B<dpkgpath>
argument if needed/desired.  The default path to C<dpkg> is '/usr/bin/dpkg'.

Returns a L<AntBuild::Pkg::Common> package object if the package could be
determined via the C<dpkg> command, B<undef> if the package could not be
determined.  

=back 4

=head2 Private Methods and Variables

None at this time.

=head1 AUTHOR(S)

Brian Manning E<lt>elspicyjack at gmail dot comE<gt>

=cut 

# vi: set ft=perl sw=4 ts=4 cin:
1;
