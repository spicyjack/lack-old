package AntBuild::Tools;
# Copyright (c)2006 Brian Manning ( elspicyjack at gmail dot com )
# $Id: Tools.pm,v 1.11 2006-09-07 20:17:46 brian Exp $

=pod

=head1 NAME

AntBuild::Tools

=head1 DESCRIPTION

=head2 Overview

B<AntBuild::Tools> is a set of common methods meant to be inherited by other
classes.  This module is not designed to run by itself.

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
#$VC_VERSION=q($Revision: 1.11 $ $Date: 2006-09-07 20:17:46 $);
use strict;
use warnings;
use vars qw( $AUTOLOAD );
use Log::Log4perl qw(get_logger);
=pod

=head2 Private Methods and Variables

B<WARNING>: These interfaces may change at any time.  For compatabiltiy, it's
recommended you use the L</"Public Object Methods"> listed below.  These are
only documented here for completeness.

=cut

{ # begin private methods and variables

    sub _check_args {
        my $this = shift;
        my $method_name = shift;

		my $logger = get_logger();

        # FIXME
        # put something here that strips leading dashes ('--' or '-') from keys
        if ( (scalar(@_) % 2) != 0) {
            $logger->logcarp(qq(Uneven number of arguments passed to )
                . ref($this) . qq(->$method_name()) );
            $logger->warn( join(q(:), @_) );
        } # if ( (scalar(@_) % 2) != 0)
        return @_;
    } # sub _check_args

=pod

=over 4

=item _check_args(@_)

Verifies that the arguments passed into the calling method are in pairs,
meaning if there's an odd number of arguments, then the caller made a mistake,
and a warning is printed.

=cut

} # end private methods and variables

sub paginate {
    my ($this, $rowsperpage, @lines) = @_;

    # FIXME make this work
} # sub paginate

sub AUTOLOAD {
# autoloader will handle missing get/set_*() methods
    my ($this, $setval) = @_;
    
    # FIXME see if you can adapt the autoload class method teacher code in OO
    # Perl book page 94 to this autoloader
    
    # a DESTROY call perhaps?  exit if so...
    return if $AUTOLOAD =~ /::DESTROY$/;
    
    # create the logger object after we're sure we weren't called as a DESTROY
    # method
    my $logger = get_logger(ref($this));
    
    # a get_* method?
    if ( $AUTOLOAD =~ /.*::get(_\w+)/ ) {
        if ( exists $this->{$1} ) {
			$logger->debug(ref($this) . q(::AUTOLOAD: 'get' returning ) 
				. $this->{$1});
            return $this->{$1}; 
        } else {
            $logger->warn(ref($this) . q(::AUTOLOAD: 'get' variable/method ));
            #$logger->warn(qq(\t'$1' was not found));
            $logger->logcarp(qq(  '$1' was not found));
            return undef;
        } # if ( exists $this->{$1} )
    } # if ( $AUTOLOAD =~ /.*::get(_\w+)/ )
    #$AUTOLOAD =~ /.*::get(_\w+)/ 
        #and $this->_accessable($1, 'r') 
        #and return $this->{$1};

    # nope, it's a set_* method
    $AUTOLOAD =~ /.*::set(_\w+)/ and do { 
		$logger->debug(ref($this) . qq(::AUTOLOAD: setting $1 to $setval));
		$this->{$1} = $setval; 
		return;
	};
    #$AUTOLOAD =~ /.*::set(_\w+)/ 
        #and $this->_accessable($1, 'w')
        #and do { $this->{$1} = newval; return }

    $logger->warn(ref($this) . ": no such attribute: $AUTOLOAD");
} # AUTOLOAD

=pod 

=item AUTOLOAD($AUTOLOAD)

Autoloader which implements generic get() and set() methods on object
attributes that haven't already been implemented above.  Returns a warning if
the attribute specified in B<$AUTOLOAD> doesn't exist.

=back 4

=head1 AUTHOR(S)

Brian Manning E<lt>elspicyjack at gmail dot comE<gt>

=cut 

# vi: set ft=perl sw=4 ts=4 cin:
1;
