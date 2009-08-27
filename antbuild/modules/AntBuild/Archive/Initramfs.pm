package AntBuild::Archive::Initramfs;
# Copyright (c)2006 Brian Manning ( elspicyjack at gmail dot com )
# $Id: Initramfs.pm,v 1.1 2006-12-14 21:45:54 brian Exp $

=pod

=head1 NAME

AntBuild::Archive::Initramfs

=head1 DESCRIPTION

=head2 Overview

B<AntBuild::Archive::Initramfs> is a set of common methods for working with
archives.  The object is meant to be inherited by other classes, and is not
designed to run by itself.

=cut

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



=head1 VERSION

The current version of this module is 1.00 (10Apr2006)

=cut

# see 'perldoc Exporter' for more dirt on Perl module versions
$VERSION=1.00;
#$VC_VERSION=q($Revision: 1.1 $ $Date: 2006-12-14 21:45:54 $);
use strict;
use warnings;
use AntBuild::Tools 1.00;
@AntBuild::Archive::Initramfs::ISA = qw(AntBuild::Tools);
use vars qw( $AUTOLOAD );
use Log::Log4perl qw(get_logger);

=pod

=head2 Public Methods

=cut

sub new {
    my $class = shift;

    # create the object with a bless, set the child file list to empty
    my $this = $class->SUPER::new();

    # get the logger object that matches whatver object type this method is
    # attached to
    my $logger = get_logger(ref($class) || $class);
    my %args = $this->_check_args(q(new), @_);

    $logger->debug(qq(Entering '$class'::new()));

} # sub new

=pod

=item new()

Autoloader which implements generic get() and set() methods on object
attributes that haven't already been implemented above.  Returns a warning if
the attribute specified in B<$AUTOLOAD> doesn't exist.

=back 4

=head2 Private Methods and Variables

B<WARNING>: These interfaces may change at any time.  For compatabiltiy, it's
recommended you use the L</"Public Object Methods"> listed below.  These are
only documented here for completeness.

=cut

{ # begin private methods and variables

=pod

=over 4

=item _some_method()

=cut

} # end private methods and variables

=pod 

=back 4

=head1 AUTHOR(S)

Brian Manning E<lt>elspicyjack at gmail dot comE<gt>

=cut 

# vi: set ft=perl sw=4 ts=4 cin:
1;
