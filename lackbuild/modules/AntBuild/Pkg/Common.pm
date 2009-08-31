package AntBuild::Pkg::Common;

# Copyright (c)2006 Brian Manning ( elspicyjack at gmail dot com )
# $Id: Common.pm,v 1.10 2006-08-24 02:14:21 brian Exp $

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

AntBuild::Pkg::Common

=head1 VERSION

The current version of this module is 1.00 (19May2006)

=cut

# see 'perldoc Exporter' for more dirt on Perl module versions
$VERSION=1.00;
use strict;
use warnings;
use Log::Log4perl qw(get_logger);
use AntBuild::Tools;
@AntBuild::Pkg::Common::ISA = qw(AntBuild::Tools);

=pod 

=head1 DESCRIPTION

B<AntBuild::Pkg::Common> is a set of common methods and attributes used for
working with the system packaging tools.  B<AntBuild::Pkg::Common> is meant to
be subclassed by other modules that do the actual work of figuring out the
dependeicies, the B<AntBuild::Pkg::Common> module would be called by the
dependent module as B<$class::SUPER->new()> in order to correctly initialize
the object.

=head2 Public Methods

=over 4

=cut
	
sub new {
    die(q(HEY! Please call one of the other classes instead of this one!));
} # sub new

=pod 

=item new()

Not meant to be used; prints a warning right before exiting the script.

=cut

sub get_varkeys {
	my $this = shift;

	# retrieve all of the variables in the current object
	# this only works as long as the object is a blessed hash, as no list of
	# object attributes is stored inside of the object itself 
	return keys(%{$this});
} # sub get_varkeys

sub dump_pkginfo {
	my $this = shift;
    # get the logger object that matches whatver object type this method is
    # attached to
    my $logger = get_logger(ref($this) || $this);
	foreach ( $this->get_varkeys() ) {
		my $method = qq(get$_);		
        $_ =~ s/^_//;
		$logger->info(qq(  $_: ) . $this->$method() );
	} # foreach my $line
} # sub dump_deps

=pod

=back 4

=head1 AUTHOR(S)

Brian Manning E<lt>elspicyjack at gmail dot comE<gt>

=cut 

# vi: set ft=perl sw=4 ts=4 cin:
1;
