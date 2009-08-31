package AntBuild::FileInfo;
# Copyright (c)2006 Brian Manning ( elspicyjack at gmail dot com )
# $Id: FileInfo.pm,v 1.26 2006-12-20 08:20:12 brian Exp $

# generic file class 
# other specific file type classes will be built on top of this one
# this class will hold the file's physical details, such as size, permissions,
# mtime/ctime, ownership, checksums, etc.

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

B<AntBuild::FileInfo> 


=head1 VERSION

The current version of this module is 1.00 (10Apr2006)

=cut

# see 'perldoc Exporter' for more dirt on Perl module versions
$VERSION=1.00;
use strict;
use warnings;
use vars qw( $AUTOLOAD );
use Log::Log4perl qw(get_logger);
use File::Basename;
use Digest::MD5;


=pod 

=head1 DESCRIPTION

=head2 Overview

B<AntBuild::FileInfo> reads a file from storage, and will then parse and
store a file's physical attributes (the output of the B<stat()> function in
Perl], which can then be used and inherited by other modules

=head2 Public Object Methods

=cut

sub new {
# create a new file object, or some subclassed file object

    # pop the object name off of the stack and print it
	my ($class, $file) = @_;

    # get the logger object that matches whatver object type this method is
    # attached to
	my $logger = get_logger(ref($class) || $class);	
    
	# debugging output if --debug == 'all' or 'plugin'
    $logger->debug(q(Entering ) . $class . q(->new() ) );
	$logger->debug(qq(with file: '$file') );

	# create the object with a bless, set the child file list to empty
    my $this = bless ({}, ref($class) || $class);

    # get the file's info if a file was passed in and is a valid regular file
	# note: the -f test does an implied stat() system call
    if ( defined $file and -e $file ) {
        # put the full path to the file inside of _fullname
        $this->{_fullname} = $file;
        my ($basename, $suffix);
    	$this->{_dirname} = dirname($this->{_fullname});
		# check to see if _dirname is $PWD; unset _dirname if it is 
		if ( $this->{_dirname} eq q(.) ) {
			$this->{_dirname} = q();
		} # if ( $this->{_dirname} = q(.) )
        # get the full name of the file by removing the directory path
        $basename = $this->{_fullname};
        $basename =~ s/$this->{_dirname}//;
		# had to make this a separate regex cause it was giving vim syntax
		# highlighting fits
        # remove the leading slash (forwards (unix) or backwards (windows))
		$basename =~ s/^[\/|\\]//;
		# set the filename
		$this->{_filename} = $basename;
        # get the files extension (suffix)
        # regular expression should be fine with files that use multiple dot
        # characters in the filename
        $suffix = $basename;
        $suffix =~ s/.*\.(\w+)$/$1/;
    	$this->{_suffix} = $1;
		# define $this->{_suffix} to keep warnings pragma happy
		if ( ! defined $this->{_suffix} ) { $this->{_suffix} = q();}
        # now get the filename sans suffix
        $basename =~ s/\.$this->{_suffix}//;
		$this->{_basename} = $basename;

        # here's a fun one; if $file is a symlink, run lstat(), otherwise, run
        # stat()
        if ( -l $this->get_fullname() ) {
            ( $this->{_dev}, $this->{_inode}, $this->{_mode},
                $this->{_num_hardlinks}, $this->{_uid}, $this->{_gid},
                $this->{_rdev}, $this->{_size}, $this->{_atime},
                $this->{_mtime},$this->{_ctime}, $this->{_blksize},
                $this->{_blocks} ) = lstat $this->get_fullname();
            $this->{_links_to} = readlink $this->get_fullname();
            if ( $this->{_links_to} !~ /^\// ) {
                $this->{_links_to} = $this->{_dirname} . q(/) 
                    .  $this->{_links_to};
            } # if ( $this->{_links_to} !~ /^\// )
        } else {
            ( $this->{_dev}, $this->{_inode}, $this->{_mode},
                $this->{_num_hardlinks}, $this->{_uid}, $this->{_gid},
                $this->{_rdev}, $this->{_size}, $this->{_atime},
                $this->{_mtime},$this->{_ctime}, $this->{_blksize},
                $this->{_blocks} ) = stat $this->get_fullname();
        } # if ( -l $this->get_fullname() )

        # FIXME add something here that deciphers the mode flags and adds them
        # to a _modeflags attribute; make sure _output_attribs then skips
        # _modeflags when outputting attributes
        
        # can't use Digest::MD5 on directories
        if ( -f $file ) {
            open(MD5FILE, qq(<$file));
            binmode(MD5FILE);
            $this->set_md5sum(Digest::MD5->new->addfile(*MD5FILE)->hexdigest);
            close(MD5FILE);
        } # if ( -f $file )
    } else {
		die(qq(ERROR: file $file does not exist or is not readable\n));
    } # if ( defined $file and -f $file )

    # return the newly created object with filetypes and magic intact
    return $this;
} # sub new

=pod

=over 4

=item new($file)

The B<new()> method is used to create a new B<AntBuild::FileInfo> object from
the filename passed in as B<$file>.  Returns a reference to the newly created
B<AntBuild::FileInfo> object.

=cut

sub dump_attribs {
# dump all of the file attributes to the logger

    my ($this, $key) = @_;
    my $logger = get_logger();

	# dump the value for $key
	# if $key is all, dump everything, log an error if the key doesn't
	# exist
	if ( defined $key ) {
		$logger->info(qq(Attribute $key for file ) . $this->get_fullname()
			. q( is:));
		$this->_output_attrib($key);
	} else {
		$logger->info(qq(Attributes for file ) . $this->get_fullname()
			. q( are:));
	    foreach my $attrib ( sort( keys(%{$this}) ) ) {
			$this->_output_attrib($attrib);
        } # foreach my $attrib ( keys($this) )
	} # if ( defined $key )
} # sub dump_attribs

=pod

=item dump_attribs($attribute)

Verifies that the specified file attribute exists, then calls
L<AntBuild::FileInfo/"_output_attrib()"> to print the attribute to the screen
via the B<logger()> facility.  If B<$attribute> is not defined, all of the file
attributes will be dumped to the screen via the B<logger()> facility.

=cut

sub AUTOLOAD {
# autoloader will handle missing get/set_*() methods
	my ($this, $setval) = @_;

    my %modes = (
    # the leading zero makes it octal; do not remove
    # FIXME the Fnctl module has these already; reuse
    # http://perldoc.perl.org/Fcntl.html
	    S_IFSOCK => 0140000,
    	S_IFLNK => 	0120000,
	    S_IFREG =>	0100000,
    	S_IFBLK =>	0060000,
	    S_IFDIR => 	0040000,
    	S_IFCHR => 	0020000,
    	S_IFIFO => 	0010000,
    	S_ISUID => 	0004000, 
    	S_ISGID => 	0002000,
    	S_ISVTX =>	0001000,
        S_USREX =>  0000100,
        S_GRPEX =>  0000010,
        S_OTHEX =>  0000001,
        S_USRWR =>  0000200,
    ); # my %modes

	# a DESTROY call perhaps?  exit if so...
	return if $AUTOLOAD =~ /::DESTROY$/;

	# create the logger object after we're sure we weren't called as a DESTROY
	# method
	my $logger = get_logger("AntBuild::FileInfo");

	# a get_* method?
	if ( $AUTOLOAD =~ /.*::get(_\w+)/ ) {
    	if ( exists $this->{$1} ) {
	    	return $this->{$1};
    	} else {
	    	$logger->warn(q(FileInfo::AUTOLOAD: 'get' variable/method ));
    		$logger->logcarp(qq(\t'$1' was not found));
	    	return undef;
    	} # if ( exists $this->{$1} )
    } # if ( $AUTOLOAD =~ /.*::get(_\w+)/ )

	# nope, it's a set_* method
	$AUTOLOAD =~ /.*::set(_\w+)/ and do { $this->{$1} = $setval; return };
	#$AUTOLOAD =~ /.*::set(_\w+)/ 
		#and $this->_accessable($1, 'w')
		#and do { $this->{$1} = newval; return }

    # a check against filemodes
    if ( $AUTOLOAD =~ /.*::is(_[\w_]+)/ ) {
        my $match = $1;
        $match =~ s/^_//;
        # if mode is defined, and matches any of the mode keys
        if ( exists $modes{$match} ) {
            my $octalmode  = $modes{$match};
            # verify the filemode is defined 
            if ( defined $this->{_mode} ) {
                # if the regex match ANDs with the filemode, then this
                # returns 1
                my $andresult = $this->{_mode} & $octalmode;
                $logger->debug(q(AUTOLOAD called as: ) . $AUTOLOAD);
                $logger->debug(q(file mode is ) . $this->{_mode});
                $logger->debug(qq(octalmode is $octalmode, ) 
                    . qq( 'and' result is $andresult));
                return 1 if $octalmode == $andresult;
                return 0;
            } else {
                $logger->warn(q(File mode is undefined));
            } # if ( defined $this->{_mode} )
        } else {
            $logger->warn(q(No POSIX file mode ) . $1);
        } # if ( $1 )
    } # if ( $AUTOLOAD =~ /.*::is(_\w+)/ )

	$logger->logcarp("FileInfo: no such method/attribute: $AUTOLOAD");
} # AUTOLOAD

=pod

=item AUTOLOAD($AUTOLOAD)

Autoloader which implements generic get() and set() methods on object
attributes that haven't already been implemented above.  Returns a warning if
the attribute specified in B<$AUTOLOAD> doesn't exist.

=back

=head2 Private Methods and Variables

B<WARNING>: These interfaces may change at any time.  For compatabiltiy, it's
recommended you only use the L</"Public Object Methods">
listed below.  These are only documented here for completeness.

=cut

# classwide variables and functions
# these are visible to all members of this class
{

    # from Apache's icon set; samples here:
    # http://httpd.apache.org/icons/icon.sheet.png
    # feel free to change as needed, but you'll have to provide the icon
    # yourself
    my $_ICON = "binary.png";
    sub _get_icon { return $_ICON }

=pod

=over 4

=item $_ICON

Apache icon image to associate with this filetype.  This could be used for
example when dynamically creating directory indexes that are full of files, the
icon can be listed along with the filename and file properties to give the user
a visual aid as to what the contents of the file are.

=item _get_icon()

Returns the filename of the associated Apache icon image specified by
C<$_ICON>.

=cut

    # description of the module meant to be used when the user is trying to
    # decide what modules to load (--module help)
    # returning undef means that the user shouldn't know/worry about this module
    my $_MODULE_DESCRIPTION = undef;
    sub _get_module_description { return $_MODULE_DESCRIPTION }

	sub _decode_timestamp {
	# decode an epoch timestamp used in [c|m|a]time attributes of stat()
	# function
        my ($this, $timestamp) = @_;
		
        # create the time objects
        # date format shortcuts (in order)
        # s m h D M Y w j d
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) 
            = localtime($timestamp);

        my @dayname = qw( Sun Mon Tue Wed Thu Fri Sat );
        my @monthname = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
        
        return sprintf("%s, %02d%s%04d %02d:%02d:%02d", 
            $dayname[$wday], $mday, $monthname[$mon], ($year + 1900),
            $hour, $min, $sec);
	} # sub _decode_timestamp

=pod

=item _decode_timestamp($timestamp)

Decodes the epoch value B<$timestamp> returned by a C<stat()> function call
into a human-readable string.

=cut

	sub _output_attrib {
		my ($this, $attrib) = @_;
		
		my $logger = get_logger();

        if ( exists $this->{$attrib} ) {
            my $stripped = $attrib;
            $stripped =~ s/^_//; 
            my $outstring;
            SWITCH: {
        		# decode the file's timestamp?
    	    	if ( $attrib =~ /time/ ) {
    				$outstring = $this->_decode_timestamp($this->{$attrib});
                    last SWITCH;
                } # if ( $attrib =~ /time/ )
                if ( $attrib =~ /mode/ ) {
                    # set the file mode to the octal value using the mode value
                    # returned from stat()
                    $outstring = sprintf("%o", $this->{$attrib});
                    last SWITCH;
                } # if ( $attrib =~ /mode/ )

	    		# an attribute that needs no massaging
                $outstring = $this->{$attrib};
    	    } # SWITCH	
            # output the info to the screen
            $logger->info(qq(  $stripped: ') . $outstring . q('));
        } else {
            $logger->warn(qq(Attribute $attrib doesn't exist in )
                    . q(this FileInfo object));
        }# if ( exists $this->{$attrib} )
	} # sub _output_attrib

} # classwide variables and functions

=pod

=item _output_attrib($attrib)

Outputs the attribute passed in as B<$attrib> via the Log4Perl logging
interface at B<DEBUG> loglevel.  If Log4Perl is not set to B<DEBUG>, you won't
see any output whatsoever.

=back

=head1 AUTHOR(S)

Brian Manning E<lt>elspicyjack at gmail dot comE<gt>

=cut

# vi: set ft=perl sw=4 ts=4 cin:
1;
