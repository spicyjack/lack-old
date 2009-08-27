package AntBuild::Dep::Ldd;

# Copyright (c)2006 Brian Manning ( elspicyjack at gmail dot com )
# $Id: Ldd.pm,v 1.4 2008-11-25 21:30:05 brian Exp $

# a module that will figure out dependencies of files passed to it using
# GNU/Solaris ldd, and return a list of files that the passed-in file depends
# on

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

AntBuild::Dep::Ldd 

=head1 VERSION

The current version of this module is 1.00 (27Apr2006)

=cut

# see 'perldoc Exporter' for more dirt on Perl module versions
$VERSION=1.00;
use strict;
use warnings;
use AntBuild::Dep::Common 1.00;
use AntBuild::Tools 1.00;
@AntBuild::Dep::Ldd::ISA = qw(AntBuild::Dep::Common AntBuild::Tools);
use Log::Log4perl qw(get_logger);

=pod 

=head1 DESCRIPTION

The B<AntBuild::Dep::Ldd> object goes and figures out a file's library
dependencies via an external call to the C<ldd(1)> command.

=head2 Private Methods and Variables

See L<AntBuild::Dep::Common> for a list of private methods and variables.
B<AntBuild::Dep::Ldd> inherits all of it's private methods and variables from
this class.

=cut

sub new {
# create a new file object, or some subclassed file object
    # pop the object name off of the stack and print it
	my ($class, $fullname) = @_;

    # get the logger object that matches whatver object type this method is
    # attached to
	my $logger = get_logger(ref($class) || $class);	
    
	# debugging output if --debug == 'all' or 'plugin'
	$logger->debug(q(Entering ') . $class 
		. qq('::new() with file\n') . $fullname . q(') );

	# create the object with a bless, set the child file list to empty
    my $this = $class->SUPER::new();

    my $cmd = q(/usr/bin/ldd ) . $fullname . q( 2>/dev/null);
    my @cmdout = qx/$cmd/;
    if ( $@ ) { $logger->error(qq(ldd system call returned: $@)) };
    # @cmdout is now a list of libraries that $fileobj is dependent on
    chomp(@cmdout);
	my $firstline = $cmdout[0];
	$firstline =~ s/^\t//;

	SWITCH: {
	    if ($firstline =~ /not a dynamic executable/) {
    		$logger->debug(q(DepLdd: file ) . $fullname
        	    . q(is not a dynamic executable));
			$this->{FILETYPE} = q(NOTEXE);
			last SWITCH;
		}
		if ( $firstline =~ /statically/ ) {
			$logger->debug(q(DepLdd: file ) . $fullname 
        	    . q( is statically linked));
			$this->{FILETYPE} = q(STATIC);
			last SWITCH;
		}
        # file is a dynamically linked file, let's figure out all of it's
        # dependencies
		$this->{FILETYPE} = q(DYNAMIC);	

        # parse each line of the output from ldd
		foreach my $line ( @cmdout ) {
            # skip this libary if it's linuxgate; that's a virtual library
            # that the kernel uses/provides
            next if ( $line =~ /linux-gate/ );
        	$line =~ s/^\t+//;
            $line =~ s/\s+/ /;
            # break apart the dynamically linked file and actual file and
            # memory location where that file loads into
            # the order of the arguments in the ldd output is:
            # deplib => depfile (memloc), or
            # deplib (memloc), where
            # - deplib is the library dependency in the binary
            # - depfile is the file that satisifes that dependency
            # - and memloc is the location in memory where depfile loads in to
            my ($deplib, $depfile, $filememinfo, $memloc);
            if ( $line =~ / => / ) {
                if ( $line =~ /=> \(/ ) {
                    # deplib =>  (memloc)
                    ($deplib, $filememinfo) = split(/ => /, $line);
                    $depfile = $deplib;
                } else {
                    # deplib =>  depfile (memloc)
                    ($deplib, $filememinfo) = split(/ => /, $line);
                    ($depfile, $memloc) = split(/ /, $filememinfo);
                } # if ( $line =~ /=>\s+\(/ )
            } else {
                # deplib (memloc)
                ($deplib, $memloc) =  split(/ /, $line);
                $depfile = $deplib;
            } # if ( $line =~ / => / )
            # now break apart the file/memory info
            #$memloc =~ s/^\(*//g;
            $memloc =~ s/^.*\(//g;
            $memloc =~ s/\)$//g;
            $depfile =~ s/\s//g;
			$logger->debug(qq(adding $memloc and lib $deplib to key )
                . qq($depfile));
            $this->add_dep(lib => $deplib, file => $depfile, mem => $memloc);
		} # foreach my $line ( @cmdout )

        if ( $logger->is_debug() ) {
            $logger->debug(q(DepLdd: ') . $fullname . q(') );
	        $logger->debug(qq(is a dynamically linked file));
	        $logger->debug(qq(and has the following dependencies:)); 
            $this->dump_deps();
        	$logger->debug(q(DepLdd: found ) . $this->count_deps()
                . q( dependencies total) );
        } # if ( $logger->is_debug() )
	} # SWITCH

    # return the newly created object with filetypes and magic intact
    return $this;
} # sub new

=pod

=over 4 

=item new($fullname)

Creates a new DepLdd object, using the full name of the file passed in as
B<$fullname).  Once the new object is B<bless()>ed, uses the C<ldd(1)> system
command to obtain a list of library dependencies.  Whitespace is parsed out of
this list, and then stored inside of the object for retreival using
B<get_depfiles()> or B<get_depinfo()> methods.

=back

=head1 AUTHOR(S)

Brian Manning E<lt>elspicyjack at gmail dot comE<gt>

=cut

# vi: set ft=perl sw=4 ts=4 cin:
1;
