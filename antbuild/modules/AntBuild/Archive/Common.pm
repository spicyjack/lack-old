package AntBuild::Archive::Common;
# Copyright (c)2006 Brian Manning ( elspicyjack at gmail dot com )
# $Id: Common.pm,v 1.6 2008-11-25 19:13:17 brian Exp $

# http://search.cpan.org/~kane/Archive-Extract-0.12/lib/Archive/Extract.pm
# http://search.cpan.org/~pmqs/IO-Compress-Bzip2-2.000_13/lib/IO/Compress/Bzip2.pm
# http://search.cpan.org/~pmqs/IO-Compress-Zlib-2.000_13/lib/IO/Compress/Gzip.pm
# http://search.cpan.org/~pmqs/Compress-Zlib-1.42/Zlib.pm
# http://search.cpan.org/author/SMPETERS/Archive-Zip-1.16/lib/Archive/Zip.pod
# http://search.cpan.org/author/SOFTDIA/Archive-TarGzip-0.03/lib/Archive/TarGzip.pm
#
=pod

=head1 NAME

AntBuild::Archive::Common

=head1 DESCRIPTION

=head2 Overview

B<AntBuild::Archive::Common> is a set of common methods for working with
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
#$VC_VERSION=q($Revision: 1.6 $ $Date: 2008-11-25 19:13:17 $);
use strict;
use warnings;
use AntBuild::Tools 1.00;
@AntBuild::Archive::Common::ISA = qw(AntBuild::Tools);
use vars qw( $AUTOLOAD );
use Log::Log4perl qw(get_logger);

=pod

=head2 Public Methods

=cut 

sub new {
    my ($class) = shift;
    my $this = bless ({}, ref($class) || $class);

    return $this;
} # sub new

# FIXME see http://wiki.antlinux.com/pmwiki.php?n=AntLinux.DepSh#Archiving for
# a list of methods that each archive class should implement; see the list
# above at the top of the file to verify that the list of methods to implement
# in the wiki is complete and will perform all of the required functionality;
# implement all of the methods in this class with warn() functions, so when a
# user tries to call a method that is not implemented in a child class, they
# get the warning here instead of going off to the AUTOLOADer to retreive a
# object attribute instead

=pod

=item some_public_method 

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
