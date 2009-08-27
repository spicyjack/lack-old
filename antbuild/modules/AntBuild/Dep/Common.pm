package AntBuild::Dep::Common;

# Copyright (c)2006 Brian Manning ( elspicyjack at gmail dot com )
# $Id: Common.pm,v 1.3 2006-08-01 06:26:36 brian Exp $

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

AntBuild::Dep::Common

=head1 VERSION

The current version of this module is 1.00 (19May2006)

=cut

# see 'perldoc Exporter' for more dirt on Perl module versions
$VERSION=1.00;
use strict;
use warnings;
use Log::Log4perl qw(get_logger);
use AntBuild::Tools;
@AntBuild::Dep::Common::ISA = qw(AntBuild::Tools);

=pod 

=head1 DESCRIPTION

The B<AntBuild::Dep::Common> object stores the dependency information for later
use/retreival by external objects.  B<AntBuild::Dep::Common> is meant to be
subclassed by other modules that do the actual work of figuring out the
dependeicies, the B<AntBuild::Dep::Common> module would be called by the
dependent module as B<$class::SUPER->new()> in order to correctly initialize.

=head2 Public Methods

=over 4

=cut
	
sub new {
    my ($class) = shift;
    my $this = bless ({}, ref($class) || $class);

    $this->{_DEPS} = ();
    return $this;
} # sub new

=pod 

=item new()

Creates a new dependency object, and initializes the values of the B<$_FILE>
and <%_DEPS> variables respectively.  The B<$_FILE> variable stores the
filename of the file which this object is describing, and the B<%_DEPS> hash
stores the dependency information that has been worked out for B<$_FILE>.

=cut

sub add_dep {
	my $this = shift;

    my $logger = get_logger();

    # from AntBuild::Tools
    my %args = $this->_check_args(q(add_dep), @_);

	# removed and delete the file argument, it's used as a key later on
	my $file = $args{file};
	delete $args{file};
    
    $logger->debug( ref($this) . qq(->_add_dep(): adding values:\n) 
        . join(q(:), %args) );
	# now add the rest of the values from args to the DEPS hash
	$this->{_DEPS}{$file} = {%args};
} # sub add_dep

=pod

=item add_dep()

The add_dep() method adds the dependency information passed into it to the
B<_DEPS> hash for this file.  Dependency information might include the name of
a file or information about where the file is loaded into memory.

=cut

sub dump_deps {
	my $this = shift;
    # get the logger object that matches whatver object type this method is
    # attached to
    my $logger = get_logger(ref($this) || $this);

    my @return = $this->get_dep_file_info();
	foreach (@return) {
			$logger->debug(qq(  $_));
	} # foreach my $line
} # sub dump_deps

sub count_deps { my $this = shift; return scalar(keys(%{$this->{_DEPS}})); }
sub get_dep_file_info { my $this = shift; return keys(%{$this->{_DEPS}}); }
sub get_all_dep_info { my $this = shift; return @{$this->{_DEPS}}; }
=pod

=item count_deps

Returns the number of files that this file is dependent on

=item get_dep_file_info()

Returns a list of files that this object is dependent on.

=item get_all_dep_info()

Returns the file and memory info of files that this object is dependent on.
Since the object stores these values interally as a hash, the caller of this
method should assign the return value of this method either to a Perl list or
hash in order to access the information returned from this method correctly.
(Assigning to a scalar value will most likely result in that scalar holding the
number of list/hash items returned, not a reference to those items, which is
probably not what you want).

=back 4

=head2 Private Methods and Variables

None at this time.

=cut

# classwide variables and functions
# these are visible to all members of this class
#{

# XXX maybe add a counter for how many dependency objects are running around?
# Although since each file has it's own list of dependencies, counting how many
# files have been put into the %_FILEDB would take care of that as well.

#} # classwide variables and functions

=pod 

=head1 AUTHOR(S)

Brian Manning E<lt>elspicyjack at gmail dot comE<gt>

=cut 

# vi: set ft=perl sw=4 ts=4 cin:
1;
