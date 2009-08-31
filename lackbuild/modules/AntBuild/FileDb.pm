package AntBuild::FileDb;
# Copyright (c)2006 Brian Manning ( elspicyjack at gmail dot com )
# $Id: FileDb.pm,v 1.47 2006-08-22 00:21:48 brian Exp $

=pod

=head1 NAME

AntBuild::FileDb

=head1 VERSION

The current version of this module is 1.00 (10Apr2006)

=cut

# see 'perldoc Exporter' for more dirt on Perl module versions
# version must be set before 'strict' pragma is set
$VERSION = 1.00;
#$CVS_VERSION=q($Revision: 1.47 $ $Date: 2006-08-22 00:21:48 $);
use strict;
use warnings;

use AntBuild::FileInfo 1.00;
use AntBuild::Tools 1.00;
# parent object is a AntBuild::File object:
@AntBuild::FileDb::ISA = qw(AntBuild::FileInfo AntBuild::Tools);

use Log::Log4perl qw(get_logger);
use Time::HiRes qw(gettimeofday tv_interval);
=pod

=head1 DESCRIPTION

=head2 Overview

B<AntBuild::FileDb> will keep track of File objects used when building lists of
file dependencies in Linux.  Uses the L<AntBuild::FileInfo> module for gatering
system-level data about files.

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

=pod

=head2 Public Object Methods

=cut

sub new {
# create a new file object, or some subclassed file object

    # pop the object name off of the stack and print it
	my ($class, $Config) = @_;

    # get the logger object that matches whatver object type this method is
    # attached to
	my $logger = get_logger(ref($class) || $class);	
    
	# debugging output 
	$logger->debug(q(Entering ') . $class . q('));

	# create the object with a bless, set the parent/child file lists to empty
    #my $this = bless ({ _parents => {}, _children => {} }, 
    my $this = bless ({}, ref($class) || $class);

	# get the platform we're running on for later (finding dependencies)
	$logger->debug(q(Currently running on ') . $this->get_system_os() . q('));

    # save $Config for future use
    $this->{Config} = $Config; 

    return $this;
} # sub new

=pod

=over 4

=item new($Config)

Creates a new B<AntBuild::FileDb> object.  When the new B<AntBuild::FileDb>
object is created, the running platform is determined and stored internally in
the object.  It can then be retrieved with the B<get_system_os()> method.

=cut

sub get_file_deps {
    my ($this, $file) = @_;

	my $logger = get_logger();	
	my $fileobj;
	my $Config = $this->{Config};

	# see if the file exists in %_FILEDB already
	if ( ! defined $this->_check_filedb_key($file) ) {
		if ( ! -r $file ) {
			$logger->warn(qq(Unable to read '$file'));
			return;
		}
        # create the FileInfo object, this is what gets passed around to
        # other objects and evenutally made a part of the dependencies
        # database
    	$fileobj = AntBuild::FileInfo->new($file);

        # test for symlink-ed-ness; symlinks don't have dependencies, but they
        # may have packages
        my $depsobj;
        if ( ! $fileobj->is_S_IFLNK() ) {
    		# create a deps object; calling get_depfiles returns the file
        	# dependencies as a list of files
    		DEPSWITCH: {
	    		# for Mac OS X/Darwin's otool
		    	if ( $this->get_system_os() eq q(darwin) ) {
                    # Darwin-enabled library dependency checker
                    use AntBuild::Dep::Otool 1.00; 
		        	$depsobj = AntBuild::Dep::Otool->new(
                        $fileobj->get_fullname());
                 	last DEPSWITCH;
	    		} # if ( $this->get_system_os() eq q(darwin) )

		    	# this is the default option for this switch block
                # GNU/Solaris library dependency checker			
                use AntBuild::Dep::Ldd 1.00; 
	            $depsobj = AntBuild::Dep::Ldd->new($fileobj->get_fullname());
    	    } # DEPSWITCH
        } # if ( $fileobj->is_S_IFLNK )

        # now grab the package info for this file
        my $pkgobj;
        # use the binary on darwin to determine which package system to query.
        # watch for both packaging systems to be installed at the same time
        # use the distro-specific file for Linux-y package queries
        # http://wiki.antlinux.com/pmwiki.php?n=AntLinux.DepSh 
        PKGSWITCH: {
			if ( $this->get_system_os() eq q(linux) 
				&& -e q(/etc/debian_version) ) {
				use AntBuild::Pkg::Deb;
	            $pkgobj = AntBuild::Pkg::Deb->new(
					fullname => $fileobj->get_fullname(),
					dpkgpath => $Config->get(q(dpkgpath)) );
				last PKGSWITCH;
			} # $this->get_system_os() eq q(linux) && -e q(/etc/debian_version)
			if ( $this->get_system_os() eq q(linux) 
				&& -e q(/etc/redhat-release) ) {
				use AntBuild::Pkg::Rpm;
	            $pkgobj = AntBuild::Pkg::Rpm->new(
					fullname => $fileobj->get_fullname(),
					rpmpath => $Config->get(q(rpmpath)) );
				last PKGSWITCH;
			} # $this->get_system_os() eq q(linux) && -e q(/etc/redhat-release)
			if ( $this->get_system_os() eq q(darwin) ) {
                if ( -x $Config->get(q(portspath)) ) {
    				use AntBuild::Pkg::DarwinPorts;
	                $pkgobj = AntBuild::Pkg::DarwinPorts->new(
                        fullname => $fileobj->get_fullname(),
						portspath => $Config->get(q(portspath)) );
                    last PKGSWITCH;
			    } elsif ( -x $Config->get(q(finkpath)) ) {
#                   use AntBuild::Pkg::Fink;
#	                $pkgobj = AntBuild::Pkg::Fink->new( 
#	                    fullname => $fileobj->get_fullname(),
#	                    finkpath => $Config->get(q(finkpath)) );
                    last PKGSWITCH;
#                } else {
#                die(q(Darwin platform detected, but no packaging )
#                    . q(system found));
                } # if ( -d $Config->get(q(portspath)) )
			} # if ( $this->get_system_os() eq q(darwin) )
			# we shouldn't reach here...
			die(q(Cannot determine Platform/Package Tools; platform: ') 
				. $this->get_system_os() . q('));
        } # PKGSWITCH

        # add the dependencies/file information/package information for this
        # file
	    $this->_add_objs(fileobj => $fileobj, depsobj => $depsobj,
                pkgobj => $pkgobj);
    } else {
        # the dependencies for this object have already been worked out;
        # return them to the caller as filename strings
        # - query the database using the filename, which will return the deps
        # object
		$fileobj = $this->_get_file_obj($file);
    } # if ( ! defined $this->_check_filedb_key($file) )

	# store the files needed for this file in an array
    my @dependencies = $this->_get_dep_keys($fileobj);
    # add this file to the parent objects to establish this file's
    # dependency relationship 
	#$this->add_parents(@dependencies);

	if ( $Config->get(q(recursion)) ) {
		# check each file in the @dependencies array to make sure it's already
		# in the FileDb
        if ( $fileobj->is_S_IFLNK() ) {
            my $linkedfile = $fileobj->get_links_to();
            # test to verify the symlink has a full path; add the full path to
            # the linked file if needed
            #if ( $linkedfile !~ /^\// ) {
            #    $linkedfile = $fileobj->get_dirname() . q(/) . $linkedfile;
            #}
            $logger->debug(q(linked to file is: ) . $linkedfile);
            $this->get_file_deps( $linkedfile );
        } else {
    		foreach ( @dependencies ) {
	    		if ( ! defined $this->_check_filedb_key($_) ) {
		    		$this->get_file_deps($_);
			    } # if ( ! defined $this->_check_filedb_key($_) )
    		} #  foreach ( @dependencies )
        } # if ( $fileobj->is_S_IFLNK() )
	} # if ( $Config->get(q(recursion)) )
    # we only need to return the files, not the memory locations
	return @dependencies;
} # sub get_file_deps

=pod

=item get_file_deps($file)

The B<get_file_deps()> method first checks to see if the file passed in as
B<$file> is readable, then proceedes to gather the file's physical information
and dependencies and store them in internal data structures.  The B<get_deps()>
method will also verify whether or not the physical or dependency information
already exists prior to attempting to obtain that information.  The method
returns a list of dependency files to the caller.

=cut

sub get_file_attr {
    my $this = shift;
    my %args = $this->_check_args(q(get_file_attr), @_);

    return $this->_get_file_attrib(file => $args{file}, 
                                    attrib => $args{attrib});
} # sub get_file_attr

=pod

=item get_file_attr(file => $file, attrib => $attrib)

Returns the L<AntBuild::FileInfo> attribute specified by B<$attrib> for file
B<$file>.

=cut

sub get_pkg_attr {
    my $this = shift;
    my %args = $this->_check_args(q(get_pkg_attr), @_);

    return $this->_get_pkg_attrib(pkg => $args{pkg}, 
                                    attrib => $args{attrib});
} # sub get_pkg_attr

=pod

=item get_pkg_attr(file => $file, attrib => $attrib)

Returns the L<AntBuild::Pkg::Common> attribute specified by B<$attrib> for file
B<$file>.

=cut

sub count_deps { 
    my $this = shift;
    my $file = shift;
    # call the _count_deps() method on the Deps object inside %_FILEDB for
    # this filename
    return $this->_count_deps($file);
} # sub _count_deps

=pod

=item count_deps($file)

Returns a number for the number of files that B<$file> is dependent on.

=cut

sub get_system_os {
	my $this = shift;
	
	if ( ! defined $this->{OS} ) {
		$this->{OS} = $^O; # perl shorthand for the running OS
	} 
	return $this->{OS};
} # sub system_os

=pod 

=item get_system_os() 

Returns a text string representing the operating system which Perl is currently
running on top of.  To be used for determining which library dependency program
to run for figuring out dependencies (Different operating systems use different
binaries for determining library dependencies).

=cut

sub clear_filedb {
    my $this = shift;
    $this->_clear_filedb();
} # sub clear_filedb

=pod

=item clear_filedb()

Clears out the contents of the B<%_FILEDB> (calls private method of the same
name to do the dirty work.  Do not pass GO, do not collect $200.

=cut

sub clear_pkgs {
    my $this = shift;
    $this->_clear_pkgs();
} # sub clear_filedb

=pod

=item clear_pkgs()

Clears out the contents of the B<%_PKGS> hash (calls private method of the same
name to do the dirty work.  Do not pass GO, do not collect $200.

=back 4

=head2 Private Methods and Variables

B<WARNING>: These interfaces may change at any time.  For compatabiltiy, it's
recommended you use the L</"Public Object Methods"> listed below.  These are
only documented here for completeness.

=cut

#################################
# PRIVATE VARIABLES AND METHODS #
#################################
{ 
# all of the attributes/methods in this block are visible to all members of
# this class

	my %_FILEDB;
    my %_PKGS;
    my %_TIMER;

=pod

=over 4

=item %_FILEDB

Hash containing a list of filenames as keys and pointers to
L<AntBuild::FileInfo> and L<AntBuild::DepLdd> or L<AntBuild::DepOtool> objects
for that filename as values.  Basically a database of dependency files.   

=item %_PKGS

Hash containing a list of packages as keys, and pointers to individual objects
derived from the L<AntBuild::Pkg::Common> module as values.  The
L<AntBuild::Pkg::Common> object would contain more information about the 
specific package that the file belongs to.  The package keys are (usually) the
name of the software package minus any versioning information or packaging
versions.  The software versions and package versions can be obtained using the
dedicated methods related to the package objects.

=item %_TIMER

A timer to be used for figuring out how long things take to happen on the
system; the timer will be used to measure how long system calls take to return.

=cut 

###
### General Private FileDb methods
###

    sub _start_timer {
        my ($this, $name) = @_;
        
        my $logger = get_logger();
        if ( exists $_TIMER{$name} ) {
            $logger->warn(qq(timer $name already exists));
            $logger->warn("(a timer with this name was overwritten)");
        } # if ( defined $_TIMER )
        # gettimeofday() is defined in Time::HiRes
        $_TIMER{$name} = [gettimeofday()];
        return $_TIMER{$name};
    } # sub _start_timer

=pod

=item _start_timer($name)

Starts a timer with the name of $name.  If $name was previously used, print a
warning prior to resetting that timer.  The timer is stopped and the time
retrieved using the _stop_timer() method below.  Timers are meant to be used to
time how long system calls take.

=cut

    sub _stop_timer {
        my ($this, $name) = @_;

        my $logger = get_logger();

        # bitch if a timer was requested that doesn't exist
        if ( exists $_TIMER{$name} ) {
            # save the value for returning prior to clearng it out
            my $return = tv_interval($_TIMER{$name});
            delete $_TIMER{$name};
            return $return;
        } else {
            $logger->warn(qq(timer $name does not exist));
            return undef;
        } # if ( exists $_TIMER{$name} )
    } # sub _stop_timer

=pod

=item _stop_timer($name)

Stops a timer by the name of $name and returns the elapsed time in seconds
between when that timer was started and stopped.  If $name was never defined,
prints a warning and returns B<undef>.

=cut

	sub _add_objs {
		# expects some kind of Deps object (Ldd or Otool)
		my $this = shift;
		my $logger = get_logger();
		my %args = $this->_check_args(q(_add_deps_obj), @_);
		my $depsobj = $args{depsobj};
		my $fileobj = $args{fileobj};
        my $pkgobj = $args{pkgobj};
		die q(FileDb: attempted to add missing or unknown object )
            . q(to the FileDb database)
			unless ( $fileobj->isa(q(AntBuild::FileInfo)) );

        # add the file object to the FileDb entry for this file
		$_FILEDB{$fileobj->get_fullname()}{fi} = $fileobj;

        # if defined, add the deps object to the database as the value to key
        # 'deps'
        if ( defined $depsobj ) {
    		$_FILEDB{$fileobj->get_fullname()}{deps} = $depsobj;
        } # if ( defined $depsobj )

        # if the package object is undefined, then the file doesn't belong to
        # any package according to the system's package tools (determined in
        # the individual package # module)
        if ( defined $pkgobj && ref($pkgobj) =~ /AntBuild::Pkg::/ ) {
    		$_FILEDB{$fileobj->get_fullname()}{pkg} = $pkgobj->get_name();
    		# add the package info to the package database
	    	if ( ! exists $_PKGS{$pkgobj->get_name()} ) {
		    	$_PKGS{$pkgobj->get_name()} = $pkgobj;
    		} # if ( ! exists $_PKGS{$pkgobj->get_name()} )
        } else {
            # this file doesn't belong to any package 
            $_FILEDB{$args{fileobj}->get_fullname()}{pkg} = undef;
        }# if ( defined $pkgobj && $pkgobj->isa(q(AntBuild::Pkg::Common)) )

	} # sub _add_deps_obj

	sub _check_filedb_key { 
		return 1 if ( exists $_FILEDB{$_[1]} );
		return undef;
	} # sub _check_filedb_key

	sub _get_filedb_keys {
		return ( keys(%_FILEDB) );
	} # sub _get_all_keys

	sub _count_filedb_keys {
		return scalar( keys(%_FILEDB) );
	} # sub _count_filedb_keys

    sub _clear_filedb {
        %_FILEDB = ();
    } # sub _clear_filedb

    sub _clear_pkgs {
        %_PKGS = ();
    } # sub _clear_pkgs

=pod

=item _add_objs()

Takes L<AntBuild::Dep::Common>, L<AntBuild::FileInfo> and
L<AntBuild::Pkg::Common> objects as arguments, and stores them in the
B<%_FILEDB> hash under the original filename.  Each individual argument is
stored inside of the B<%_FILEDB> hash under it's own hash key; the
L<AntBuild::Dep::Common> and L<AntBuild::FileInfo> objects are stored as
'{deps}' and '{fi}' respectively, and the name of the package that the original
file belongs to is stored in '{pkg}', which can then be used to look up the
package version and software version if desired.

=item _check_filedb_key($filename_key)

If the filename specified in B<$filename_key> exists in %_FILEDB, return true,
otherwise, return false (B<undef>).

=item _get_all_keys()

Returns all of the keys in %_FILEDB, which would be a list of files which have
had their dependencies worked out.

=item _count_filedb_keys() 

Returns a count of all of the keys in the %_FILEDB database; this would
correspond to how many files have had their dependencies worked out by the
script.

=item _clear_filedb()

Zeros out the %_FILEDB hash.

=item _clear_pkgs()

Zeros out the %_PKGS hash.

=cut

###
### Private dependency object methods
###
    sub _get_dep_keys { 
		my $this = shift;
		my $fileobj = shift;
		my $depobj = $_FILEDB{$fileobj->get_fullname()}{deps};
        if ( defined $depobj ) {
    		return $depobj->get_dep_file_info(); 
        }
	}

    sub _count_deps { 
        my $this = shift;
        my $file = shift;
        # call the _count_deps() method on the Deps object inside %_FILEDB for
        # this filename
        if ( defined $_FILEDB{$file}{deps} ) {
            return $_FILEDB{$file}{deps}->count_deps(); 
        } else {
            return 0;
        } # if ( defined $_FILEDB{$file}{deps} )
    } # sub _count_deps

=pod

=item _get_dep_keys($fileobj)

Returns the list of all of the filenames stored as keys in %_FILEDB

=item _count_deps($file)

For the scalar string filename passed in as $file, returns a count of all of
how many other files $file needs to work. 

=cut

###
### Private file object methods
###
    
	sub _get_file_obj {
		my ($this, $file) = @_;
		# the caller will need to check to make sure the fileinfo object exists
		# and is valid
		return $_FILEDB{$file}{fi};
	} # sub _get_file_obj

    sub _check_file_obj {
        my ($this, $file) = @_;
        return 1 if ( exists $_FILEDB{$file}{fi} );
        return undef;
    } # sub _check_file_obj

    sub _get_file_attrib {
        my $this = shift;
        my %args = $this->_check_args(q(_get_file_attrib), @_);

        my $fileobj = $_FILEDB{$args{file}}{fi};
        my $get = q(get_) . $args{attrib};
        return $fileobj->$get;
    } # _get_file_attrib

=pod

=item _get_file_obj

Need to document

=item _check_file_obj($file)

Returns true if the file object passed in as B<$file> exists in the file
database (%_FILEDB), returns undef otherwise.

=item _get_file_attrib

Need to document

=cut

###
### Package object private methods
###

    sub _get_pkg_attrib {
        my $this = shift;
        my %args = $this->_check_args(q(_get_pkg_attrib), @_);

        my $pkgobj = $_PKGS{$this->_get_pkg_name($args{file})};
        my $get = q(get_) . $args{attrib};
        return $pkgobj->$get;
    } # _get_file_attrib

	sub _get_pkg_name {
		my ($this, $file) = @_;
		return $_FILEDB{$file}{pkg};
	} # sub _get_pkg_name

    sub _get_pkg_obj {
        my ($this, $pkgname) = @_;
        if ( defined $pkgname ) {
            return $_PKGS{$pkgname};
        } else {
            return undef;
        } # if ( defined $pkgname )
    } # sub _get_pkg_obj

    sub _get_pkg_keys { my $this = shift; return keys(%_PKGS); }
    sub _count_pkg_keys { my $this = shift; return scalar(keys(%_PKGS)); }

=pod
		
=item _get_pkg_attrib()

Need to document

=item _get_pkg_name()

Need to document

=item _get_pkg_obj()

Need to document

=item _get_pkg_keys()

Returns a list of packages currently cached by the system.  Each package in
this list can then be queried for things like package version, software
version, and package architecture.

=back 4

=cut

} # end private methods and variables

=pod

=back 4

=head1 AUTHOR(S)

Brian Manning E<lt>elspicyjack at gmail dot comE<gt>

=cut 

# vi: set ft=perl sw=4 ts=4 cin:
1;
