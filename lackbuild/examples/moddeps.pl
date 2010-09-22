#!/usr/bin/perl

# $Id$
# Copyright (c)2007 by Brian Manning <elspicyjack at gmail dot com>

=pod

=head1 NAME

moddeps.pl - a wrapper around L<Modules::Dependency>

=head1 VERSION

The current version of this script is $Revision$ $Date$

=pod

=head2 Package Modules::Dependency::Wrapper

An object-oriented wrapper around L<Modules::Dependency>.  The wrapper was
written to make it easier to make calls to Modules::Dependency both through a
shell interface and via the command line.

=cut

# TODO
# - pick 3 or 4 modules to 'get', and use the output from those to write tests
# that can be run in non-interactive mode
# - add a recursive get, which would traverse all of the modules listed with
# 'get' and then get those modules as well
# - add non-interactive config options
# - finish the POD documentation
# - add a 'libpaths' command
#   - list
#   - add
#   - clear
#   - the libpaths can also be obtained from --libpath switches
# - add more commands to the 'graph' function
#   - dependencies
#   - parents
#   - children
#   - output filename; where to write the graph to

# Done TODO's
# - add a 'write list' command
#   DONE - use it with @modlist (below, in get_commands() ) to generate a
#   complete list of Perl modules that would need to be present to get any one
#   of the modules in that list to run on an embedded/standalone system
#   DONE - calculate the complete size of the filelist, including the Perl
#   binary, in order to get an idea of how big it would all end up being

package Modules::Dependency::Wrapper;
use strict;
use warnings;
use vars qw( $AUTOLOAD );
use Log::Log4perl qw(get_logger :levels);
use File::Basename;

{ # begin private methods/variables

# for tracking if the index has been created/generated
my %_flags;

sub _toggle_flag {
	my $this = shift;
	my $flag = shift;
	my $logger = get_logger();

	if ( $flag !~ /^_/ ) {
		$flag = q(_) . $flag;
	} # if ( $flag !~ /^_/ )
	if ( exists $_flags{$flag} ) {
		# run that flag through a NOT filter
		$_flags{$flag} = ! $_flags{$flag};
	} else {
		$_flags{$flag} = 1;
	} # if ( exists $_flags{$flag} )
	$logger->debug(qq(_toggle_flag: $flag is now ) . $_flags{$flag});
} # sub _toggle_flag

sub _get_flag {
	my $this = shift;
	my $flag = shift;
	my $logger = get_logger();
	
	# we do this so perl doesn't autovivify our flags before we say so
	if ( exists $_flags{$flag} ) {
		#$logger->debug(qq(_get_flag called for $flag: ) . $_flags{$flag});
		return $_flags{$flag};
	} else {
		$logger->debug(qq(_get_flag called for $flag: flag is undefined));
		return undef;
	} # if ( exists $_flags{$flag} )
} # sub _get_flag

} # end private methods/variables

sub new {
	my $class = shift;
    my %args = @_;
	my $logger = get_logger();
	if ( ref($class) ) {
		$logger->logdie( q(Sorry, ) . ref($class) 
			. qq( is not meant to be subclassed...));
	} # if ( ref($class) )

    # bless the object into existence
	my $this = bless ({}, $class);
    # add a link to a timer object
	$this->set_timer( OpTimer->new() );

    # set the values in this object obtained from %args
    foreach my $argkey ( keys %args ) {
        my $method = q(set_) . $argkey;
        $this->$method($args{$argkey});
    } # foreach my $argkey ( keys %args )

	return $this;
} # sub new

sub show_not_generated_warning {
	my $this = shift;
	my $caller = shift;
	my $logger = get_logger();

	$logger->debug(qq(show_not_generated_warning called from $caller));
	$logger->warn(q(The index is not available for queries.));
	$logger->warn(qq(  index created:   ) 
		. ( $this->is_index_created() ? q(true) : q(false) ) );
	$logger->warn(qq(  index generated: ) 
		. ( $this->is_index_generated() ? q(true) : q(false) ) );
	$logger->warn(q(To generate an index, try these commands));
	$logger->warn(qq(\tidx create));
	$logger->warn(qq(\tidx generate));
	$logger->warn(q(Use 'show example' for an index generation example.));
} # sub show_not_generated_warning

sub get_module_deps {
    my $this = shift;
	my %args = @_;
    my $op = q(get_module_deps);
    my $logger = get_logger();
    my $timer = $this->get_timer();
	my $return_code;

	if ( $this->is_index_created && $this->is_index_generated ) {
		my @modlist = @{$args{modlist}};
        $logger->debug(qq($op : modlist is ) . join(q(; ), @modlist ) );
	    $timer->start_timer($op);
		foreach my $lookup_mod ( @modlist ) {
    	    my $depinfo;
        	if ( $args{return_info} eq q(CHILDREN)) {
		    	$depinfo = Module::Dependency::Info::getChildren($lookup_mod);
	    		if ( defined $depinfo ) {
					if ( exists $args{return_raw} ) {
						$return_code = $depinfo;
					} else {
		    			$logger->info(qq(Dependency information for: ) 
							. $lookup_mod);
					    foreach my $depchild ( sort(@$depinfo) ) {
					    	$logger->info(qq(\t$depchild));
    					} # foreach my $depkey ( sort( keys(%$depinfo) ) )
						$return_code = 1;
					} # if ( exists $args{return_raw} )
	    		} else {
    				$logger->info(qq(Module '$lookup_mod' has no dependencies));
					$return_code = undef;
    			} # if ( defined $depinfo )
	        } # if ( $args{return_info} eq q(children))
    	    if ( $args{return_info} eq q(PARENTS)) {
			    $depinfo = Module::Dependency::Info::getParents($lookup_mod);
    			if ( defined $depinfo ) {
					if ( exists $args{return_raw} ) {
						$return_code = $depinfo;
					} else {
		    			$logger->info(qq(Parent module information for: ) 
							. $lookup_mod);
					    foreach my $depparent ( sort(@$depinfo) ) {
					    	$logger->info(qq(\t$depparent));
	    				} # foreach my $depkey ( sort( keys(%$depinfo) ) )
						$return_code = 1;
					} # if ( exists $args{return_raw} )
    			} else {
	    			$logger->info(qq(Module '$lookup_mod' has no dependencies));
					$return_code = undef;
    			} # if ( defined $depinfo )
        	} # if ( $args{return_info} eq q(parents))
	        if ( $args{return_info} eq q(FILENAME)) {
			    $depinfo = Module::Dependency::Info::getFilename($lookup_mod);
        	    if ( defined $depinfo ) {
					if ( exists $args{return_raw} ) {
						$return_code = $depinfo;
					} else {
		                $logger->info(qq(Filename of '$lookup_mod is:));
    		            $logger->info($depinfo);
						$return_code = 1;
					} # if ( exists $args{return_raw} )
    	        } else {
        	        $logger->warn(qq(No filename found for '$lookup_mod'));
					$return_code = undef;
            	} # if ( defined $depinfo )
	        } # if ( $args{return_info} eq q(filename))
		} # foreach my $module_lookup ( @modlist )

		# stop the timer and return the $return_code
		if ( exists $args{suppress_stop_time} ) {
			$timer->stop_timer($op);
		} else {
			$logger->info( $timer->stop_timer($op) );
		} # if ( exists $args{supress_stop_time} )
    	return $return_code;
	} else {
		$this->show_not_generated_warning($op);
		return undef;
	} # if ( $this->is_index_created && $this->is_index_generated ) 
} # sub get_module_deps

sub delete_index {
	my $this = shift;
	my %args = @_;
	my $op = q(delete_index);
    my $logger = get_logger();

	if ( $this->is_index_created && $this->is_index_generated ) {
        # try to nuke the file
		# unlink returns the number of files deleted; kinda wierd
        if ( unlink($args{dbfile}) == 0 ) { 
        	$logger->error(q(Unable to delete index file ) . $args{dbfile}
				. qq(: $!) );
        	return undef;
        } # if  ( unlink($args{dbfile}) ) == 0 )
		Module::Dependency::Info::dropIndex();
		$this->_toggle_flag(q(index_generated));
		$this->_toggle_flag(q(index_created));
    	return 1;
	} else {
        $this->show_not_generated_warning(q(delete_index));
		return undef;
    } # if ( $this->is_index_created && $this->is_index_generated )
} # sub delete_index

sub drop_index {
	my $this = shift;
	my $op = q(drop_index);
    my $logger = get_logger();
    my $timer = $this->get_timer();

	if ( $this->is_index_created && $this->is_index_generated ) {
		$timer->start_timer($op);	
		Module::Dependency::Info::dropIndex();
		$this->_toggle_flag(q(index_generated));
		$logger->info( $timer->stop_timer($op) );
    	return 1;
	} else {
        $this->show_not_generated_warning($op);
		return undef;
    } # if ( $this->is_index_created && $this->is_index_generated )
} # sub drop_index

sub show_index_count {
	my $this = shift;
	my $op = q(show_index_count);
	my %args = @_;
    my $timer = $this->get_timer();
	my $logger = get_logger();

	if ( $this->is_index_created && $this->is_index_generated ) {
	    my $allitems = Module::Dependency::Info::allItems();
    	my $allscripts = Module::Dependency::Info::allScripts();
	    $logger->info(q(Loaded ) . scalar(@$allitems) . q( items total));
	    $logger->info(q(Loaded ) . scalar(@$allscripts) . q( scripts total));
	} else {
		$this->show_not_generated_warning($op);
        return undef;
	} # if ( $this->is_index_created && $this->is_index_generated )
} # sub show_index_count

# go out and actually call makeIndex
sub generate_index {
	my $this = shift;
	my $op = q(generate_index);
	my %args = @_;
    my $timer = $this->get_timer();
	my $logger = get_logger();

	if ( ! $this->is_index_created() ) {
		$this->show_not_generated_warning($op);
	} # if ( $this->is_index_created )
    $timer->start_timer($op);	
	# push the values from the pathlist argument into it's own array so it can
	# be passed around to other methods/subroutines
	my @pathlist = $args{pathlist};
	$logger->debug(q(pathlist is: ) . join(q(:), @pathlist) );
# FIXME hack Indexer.pm to shut up the warn statement
	Module::Dependency::Indexer::makeIndex( @pathlist );
	$this->_toggle_flag(q(index_generated));
	$this->show_index_count(index_generated => $this->is_index_generated());
	$logger->info( $timer->stop_timer($op) );
    return 1;
} # sub generate_index

# meant to be used for creating new index files
# directory writeability should be tested before getting to this point
sub create_index_file {
	my $this = shift;
	my $op = q(create_index_file);
	my %args = @_;
    my $timer = $this->get_timer();
    my $logger = get_logger();

	# fileparse comes from File::Basename
	my ($filename, $dirpath, $suffix) = fileparse($args{index_file});
	if ( -w $dirpath ) {
	    $timer->start_timer($op);
   		Module::Dependency::Indexer::setIndex($args{index_file});
	    $logger->info( $timer->stop_timer($op) );
		$this->_toggle_flag(q(index_created));
	    return $args{index_file};
	} else {
        $logger->warn(qq(Can't create index file:) . $filename);
        $logger->warn(qq(Directory ') . $dirpath
    	    . q(' not writeable for current user) );
		return undef;
    } # if ( -w $dirpath )
} # sub create_index_file

# meant to be used for loading indexes that have been saved
sub load_index_file {
	my $this = shift;
	my $op = q(load_index_file);
    my %args = @_;
    my $timer = $this->get_timer();
	my $logger = get_logger();

	# see if the file argument exists/is readable
    $timer->start_timer($op);	
	my $retrieved = Module::Dependency::Info::retrieveIndex($args{index_file});
	if ( $retrieved ) {
		$this->_toggle_flag(q(index_created));
		$this->_toggle_flag(q(index_generated));
	} else {
		$logger->warn(q(Something happend when retrieving));
		$logger->warn($args{index_file});
	} # if ( $retrieved )
	$logger->info( $timer->stop_timer($op) );
    return 1;
} # sub load_index_file

sub AUTOLOAD {
    my $this = shift;
    my $setval = shift;
    
	return if $AUTOLOAD =~ /::DESTROY$/;

	my $logger = get_logger();
#if ( defined $setval ) { 
#		$logger->debug(qq(Entering AUTOLOADer with: ));
#		$logger->debug(qq($AUTOLOAD -> $setval));
#	} else {
#		$logger->debug(qq(Entering AUTOLOADer with: ));
#		$logger->debug(qq($AUTOLOAD));
#	} # if ( defined $setval )

	if ( $AUTOLOAD =~ /.*::set(_\w+)/ ) {
	    if ( defined $setval ) {
    	    $this->{$1} = $setval;
        	return 1;
	    } else {
    	    $logger->logdie(qq(Tried to assign an undefined value to $1));
	    } # if ( defined $timer )
	} elsif ( $AUTOLOAD =~ /.*::get(_\w+)/ ) { 
	    if ( exists $this->{$1} ) {
    	    return $this->{$1};
	    } else {
    	    $logger->logdie(qq(Tried to obtain an undefined value for $1));
	    } # if ( defined $this->{_TIMER} )
	} elsif ( $AUTOLOAD =~ /.*::is(_[\w_]+)/ ) { 
		if ( defined $this->_get_flag($1) ) {
#			$logger->debug(qq(AUTOLOAD: flag $1 is defined));
#			$logger->debug(qq(AUTOLOAD: and is currently set to ) 
#				. $this->_get_flag($1));
			return $this->_get_flag($1);
		} else {
			return 0;
		} # if ( exists $this->_{$1} )
	} else {
		$logger->warn(qq(No handler for AUTOLOAD request: $AUTOLOAD));
	} # if ( $AUTOLOAD =~ /.*::get(_\w+)/ )
} # sub AUTOLOAD

=pod

=head2 Package OpTimer

L</"Package OpTimer"> is meant to time operations by other modules.  You start
a timer with the L</"start_timer"> method, run your method, then call the
L</"stop_timer"> method to stop that timer and return the time in seconds that
the timer was active.

=cut

package OpTimer;
use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use Log::Log4perl qw(get_logger :levels);

my %_timers;

sub new {
    my $class = shift;
    my $logger = get_logger();
    if ( ref($class) ) {
        $logger->logdie( q(Sorry, ) . ref($class)
            . qq( is not meant to be subclassed...));
    } # if ( ref($class) )
    my $this = bless ({}, $class);
    return $this;
} # sub new

sub start_timer {
	my $this = shift;
	my $timer_name = shift;
	my $logger = get_logger();
	
#$logger->debug(ref($this) . qq(->start_timer: entering as '$timer_name'));
	if ( exists $_timers{$timer_name} ) {
		$logger->logwarn(qq(Hmm. Timer '$timer_name' already exists.));
		$logger->logdie(qq(Exiting program due to unknown timer key.));
	} # if ( exists $_timers{$timer_name} )
	# add the start time for this timer to the %_timers hash
    # the tv_interval function (later) expects an array reference, hence the
    # [brackets] around gettimeofday below
	$_timers{$timer_name} = [gettimeofday];
#$logger->debug(ref($this) . qq(->start_timer: leaving as '$timer_name'));
#$logger->debug(q(with ') . join(q(.), @{$_timers{$timer_name}}) . q('));
	return $_timers{$timer_name};
} # sub start_timer

sub stop_timer {
	my $this = shift;
	my $timer_name = shift;
    my $logger = get_logger();

#$logger->debug(ref($this) . qq(->stop_timer: entering as '$timer_name'));
    if ( exists $_timers{$timer_name} ) {
		# return the time value interval between $timer_name and now
		my $interval = sprintf("%0f", tv_interval($_timers{$timer_name}) );
		# make sure you delete the timer key too
		delete $_timers{$timer_name};
        return qq(OK: $timer_name took $interval seconds);
	} else {
		$logger->warn(qq(Hmm. Timer '$timer_name' does not exist.));
		return undef;
	} # if ( exists $_timers{$timer_name} )
} # sub stop_timer

############
### MAIN 
############
package main;
$main::VERSION = (q$Revision$ =~ /(\d+)/g)[0];
use strict;
use warnings;

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

# sitewide
BEGIN {
    # module loading block
	#
	# note that some of these modules are loaded above in their own package
	# spaces, but since this BEGIN block is run first when the script is first
	# loaded, and has the most verbose debugging if there's a problem loading a
	# module, the modules are loaded in main's packagespace as well
    my %load_modules = ( 
					q(Log::Log4perl) => q(get_logger :levels),
                    q(AppConfig) => undef,
                    q(Term::ShellUI) => undef, 
                    q(Time::HiRes) => q(gettimeofday tv_interval),
                    q(Module::Dependency::Indexer) => undef,
                    q(Module::Dependency::Info) => undef,
                    q(File::Basename) => undef,
				); # %modules
	foreach ( keys(%load_modules) ) {
        if ( defined $load_modules{$_} ) {
    	    eval "use $_ qw(" . $load_modules{$_} . ");";
        } else {
    	    eval "use $_";
        } # if ( defined $load_modules{$_} )
   	 	die   " === ERROR: $_ failed to load:\n" 
        	. "     Do you have the $_ module installed?\n"
        	. "     Error output from Perl:\n$@" if $@;
	} # foreach ( keys(%load_modules) )
} # BEGIN

# the bitmask for what gets returned in a 'get' call
use constant {
    NONE        => 0b0000,
    PARENTS     => 0b0001,
    CHILDREN    => 0b0010,
    FILENAME    => 0b0100,
}; # use constant
### Begin Script ###

# create a config object with some default variables
my $Config = AppConfig->new();
	
# Help Options
# add a "program_name" parameter to $Config
my @program_name = split(/\//,$0);
$Config->define(q(program_name|pn=s));
$Config->set(q(program_name), $program_name[-1]);
$Config->define(q(help|h!));
# script behaivor options 
$Config->define(q(debug|DEBUG|d=s@));
$Config->define(q(nocolorlog|nocolourlog|nocl));
$Config->define(q(colorlog));
$Config->define(q(interactive|i!));
$Config->define(q(useincpath|useinc|inc!));
# a bit field that describes what values to return for a 'get' call
$Config->define(q(returned_info=s));
$Config->set(q(returned_info), CHILDREN);
# set interactive mode by default, the user can turn it back off
$Config->set(q(interactive), 1);
# path to the module index (module database)
$Config->define(q(dbfile|db=s));
# list of modules to query dependencies from the module index
$Config->define(q(module|mod|m=s@));
# paths to directories containing perl scripts/modules
$Config->define(q(libpath|path|p=s@));
# don't seed the libpath (for Mac OSX)
$Config->define(q(noseed|ns!));
# don't confirm before deleting files
$Config->define(q(noconfirm|nc!));

# parse the command line
$Config->args(\@ARGV);

# do we need to show the help file?
if ( $Config->get(q(help)) ) {
	&ShowHelp();
} # if ( $Config->get_help() || $Config->get_longhelp() )

# set some defaults, these will be superceded by the same command line
# parameters (if any)

# set a default database file if the user doesn't provide one 
# the user can change this later if they wish
if ( ! defined $Config->get(q(dbfile)) ) { 
    $Config->set(q(dbfile), qq(/tmp/perldep.$$.db)); 
} # if ( ! defined $Config->get(q(dbfile)) )

# do this unless 'noseed' is set
unless ( $Config->get(q(noseed)) ) {
    # seed the libpath with some defaults
    # TODO decide if you want to give these a warning if the below paths are
    # not found; it would be nice, but noisy
    $Config->set(q(libpath), q(/usr/lib/perl)) if ( -d q(/usr/lib/perl) );
    $Config->set(q(libpath), q(/usr/lib/perl5)) if ( -d q(/usr/lib/perl5) );
    $Config->set(q(libpath), q(/usr/share/perl)) if ( -d q(/usr/share/perl) );
    $Config->set(q(libpath), q(/usr/share/perl5)) if ( -d q(/usr/share/perl5) );
} # if ( ! $Config->get(q(noseed)) )

# color log output on by default
if ( $Config->get(q(nocolorlog)) ) {
    $Config->set(q(colorlog), 0);
} else {
    $Config->set(q(colorlog), 1);
} # if ( $Config->get(q(nocolorlog)) )

# set up the logger
my $logger_conf = qq(log4perl.rootLogger = INFO, Screen\n);
if ( $Config->get(q(colorlog)) ) {
    $logger_conf .= qq(log4perl.appender.Screen = ) 
    	. qq(Log::Log4perl::Appender::ScreenColoredLevels\n);
} else {
    $logger_conf .= qq(log4perl.appender.Screen = )
		. qq(Log::Log4perl::Appender::Screen\n);
} # if ( $Config->get(q(colorlog)) )

$logger_conf .= qq(log4perl.appender.Screen.stderr = 1\n)
	. qq(log4perl.appender.Screen.layout = PatternLayout\n)
	. q(log4perl.appender.Screen.layout.ConversionPattern = %d %p %m%n)
	. qq(\n);
#log4perl.appender.Screen.layout.ConversionPattern = %d %p> %F{1}:%L %M - %m%n

# create the logger object
Log::Log4perl::init( \$logger_conf );
my $logger = get_logger("");

if ( @{$Config->get(q(debug))} > 0 ) {
	if ( grep(/all/, @{$Config->get(q(debug))}) ) {
    	$logger->level($DEBUG);
    } elsif ( grep(/info/, @{$Config->get(q(debug))}) ) {
    	$logger->level($INFO);
    } else {
		$logger->warn(q("DEBUG" switch turned on, but the debug option used));
		$logger->warn(q(is not recognized by this script));
	} # if ( grep(/all/, @{$Config->debug()}) )
} # if ( scalar($Config->debug()) > 0 )


my $moddep = new Modules::Dependency::Wrapper( 
		index_file => $Config->get(q(dbfile)) );
my $term = new Term::ShellUI( 	
		commands => get_commands($Config, $moddep),
		app => q(moddeps),
		prompt => q(moddeps> ),);
#		debug_complete => 2 );

print qq(=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n);
print $Config->get(q(program_name)) . qq(, a Perl dependency shell, );
print qq(script version: ) . sprintf("%1.1f", $main::VERSION) . qq(\n);
print q(CVS: $Id$) . qq(\n);
print q(  For help with the shell interface, type 'help help' );
print qq((without the quotes)\n);
print qq(  at the prompt; View an example of index generation with);
print qq( 'show example'\n);;
print qq(  The module index file currently is: ) . $Config->get(q(dbfile)) 
    . qq(\n);

# check that there's actually paths in $Config->libpath; it's sucky to try and
# create an index with no modules to index from
my @libpath = @{$Config->get(q(libpath))};
$logger->debug(q(There are ) . scalar(@libpath) . q( paths in libpath));
$logger->debug(qq(The joined libpaths are: \n) . join(qq(\n), @libpath));
$logger->debug(q(useincpath is currently set to: ) .
        $Config->get(q(useincpath)));
if ( scalar(@libpath) == 0 ) {
    if ( ! $Config->get(q(useincpath)) ) {
        $logger->error(qq(No Perl library paths available.\n));
        $logger->warn(q(Huh.  The script doesn't know where to look for ));
        $logger->warn(q(Perl modules on your system.));
        $logger->warn(q(Re-run the script with '--libpath' to add paths,));
        $logger->warn(q(or use '--useincpath' to allow @INC to be used.));
        exit 1;
    } # if ( ! defined $Config->get(q(useincpath)) )
} # if ( scalar(@libpath) == 0 )

# if the user specified --useincpath, then add it here
if ( $Config->get(q(useincpath)) ) {
    foreach my $incpath ( @INC ) { $Config->set(q(libpath), $incpath); }
} # if ( $Config->get(q(useincpath)) ) 
if ( scalar(@{$Config->get(q(debug))}) ) {
    warn qq(logger_conf is:\n$logger_conf);
} # if ($Config->get(q(debug))) 


# yield to Term::ShellUI
$term->run();

exit 0;

################
# get_commands #
################
sub get_commands {
	# the config object
	my $Config = shift; 
	# the depshell object, a wrapper around	Module::Dependency 
	my $moddep = shift; 
	# grab the logger singleton object
	my $logger = get_logger();
    # a list of Perl modules to look up dependencies for 
    my @modlist;

    if ( scalar( @{$Config->get(q(module))} ) > 0 ) {
        @modlist = @{$Config->get(q(module))};
    } # if ( scalar( @{$Config->get(q(getmods))} ) > 0 )

	return {
### help
	'help'  =>  { desc => q(Print list of commands/info about specific command),
    	args => sub { shift->help_args(undef, @_); },
        meth => sub { shift->help_call(undef, @_); },
        doc => <<HELPDOC
Some examples of commands using the 'help' command:
 
help help
he help
he he
help show
he sh              

HINT: Most commands can be abbreviated to two or three letters :)
HELPDOC
	}, # help
    '?'     =>  { syn => q(help) },
	'h'     =>  { syn => q(help) },
### quit
    'quit'  =>  { desc => q(Exit this script),
        meth => sub { shift->exit_requested(1); } 
	}, #quit
    'exit'  =>  { syn => q(quit) },
    'q'     =>  { syn => q(quit) },
    'x'     =>  { syn => q(quit) },
### idx (index)
    'idx' => { desc => q(Dependency index commands),
        cmds => {
			### drop
            'drop' => {
                desc => q(Drops (but does not delete) the current index file),
                proc => sub { $moddep->drop_index(); },
            }, # idx->drop
            'clear'     =>  { syn => q(drop) },
            'dr'     =>  { syn => q(drop) },
			### drop
            'delete' => {
                desc => q(Drops and deletes an index file (if it exists) ),
                proc => sub { 
                    # do this unless 'noconfirm' is set
                    unless ( $Config->get(q(noconfirm)) ) {
                        # verify this is what the user really wants prior to
                        # doing it
                        return unless ( 
                            &confirm(
	                            confirm_warning => 
                                qq(Do you really want to delete ) 
    	                            . $Config->get(q(dbfile)),
        	                    prompt => qq(Delete ) . $Config->get(q(dbfile))
            	                    . q( [Y/n]? ) ) );
                    } # unless ( $Config->get(q(noconfirm)) )
                    $moddep->delete_index();
                }, # idx->delete->proc
            }, # idx->drop
            'del'     =>  { syn => q(delete) },
			### generate
            'generate' => {
                desc => q(Generates an index file from a list of file paths),
                proc => sub { 
                    my (@temp_path_list, @validated_path_list);
					if ( ! $moddep->is_index_created() ) {
                        # create an index using the built-in filename
                        my $returned_file = $moddep->create_index_file(
                            index_file => $Config->get(q(dbfile)) );
    	                if ( defined $returned_file ) {
        	                # set the database filename
            	            $Config->set(q(dbfile), $returned_file);
	                    } else {
							$logger->warn(q(Could not create index file: )
								. $Config->get(q(dbfile)) );
							return;
						} # if ( defined $returned_file )
					} # if ( ! $moddep->is_index_created() )
                    if ( scalar(@_) > 0 ) { @temp_path_list = @_; }
					@temp_path_list = @{$Config->get(q(libpath))};
					foreach my $checkpath ( @temp_path_list ) {
						if ( -d $checkpath ) {
		                    push( @validated_path_list, $checkpath );
						} else {
							$logger->warn(qq(Directory $checkpath )
								. q(does not exist));
						} # if ( -d $checkpath )
					} # foreach my $checkpath ( @{$Config->get(q(libpath))} )
					$logger->debug(q(validated paths: ) 
						. join(q(:), @validated_path_list) 
						. q(, count is ) . scalar(@validated_path_list) );
                    # the return value from generate_index is used as a flag
                    # to let other parts of the script know that an index is
                    # available to be queried against
                    $moddep->generate_index( pathlist => @validated_path_list );
				} # idx->generate->proc
            }, # idx->generate
            'gen' => { syn => q(generate) },
            'ge' => { syn => q(generate) },
			### create
			'create' => {
                desc => q(Creates a new index file on disk),
                proc => sub { 
					my $returned_file;
					if ( ! $moddep->is_index_created () ) {
						if ( scalar(@_) > 0 ) {
							# create an index using the user-supplied filename
							$returned_file = $moddep->create_index_file(
								index_file => $_[0] );
						} else {
							# create an index using the built-in filename
							$returned_file = $moddep->create_index_file(
								index_file => $Config->get(q(dbfile)) );
	                    }# if ( scalar(@_) > 0 )
						if ( defined $returned_file ) {
							# set the database filename
							$Config->set(q(dbfile), $returned_file);
							# set the 'created' flag
						} # if ( defined $returned_file )
					} else {
						$logger->warn(q(You currently have an index file at));
						$logger->warn($Config->get(q(dbfile)));
						$logger->warn(q(Delete it with 'idx drop' prior to));
						$logger->warn(q(running this command));
					} # if ( ! $moddep->is_index_created () )
				} # idx->create->proc
            }, # idx->create
            'cr' => { syn => q(create) },
            'cre' => { syn => q(create) },
            'new' => { syn => q(create) },
			### load
            'load' => {
                desc => q(Loads an existing index file from disk),
                proc => sub { 
                    # check to see if the user specified a filename first
                    if ( scalar(@_) >= 1 ) {
                        # yep; set this file to be 'dbfile' if
                        # load_index_file returns success
                        $Config->set(q(dbfile), $_[0])
                            if ($moddep->load_index_file(index_file => $_[0]) );
                    # then fall back to the 'dbfile' Config variable
                    } elsif ( $Config->get(q(dbfile)) ) {
                        $moddep->load_index_file( 
                            index_file=> $Config->get(q(dbfile)) );
                    # barf otherwise
                    } else {
                        $logger->warn(q(No index file specified...));
                        $logger->warn(
                            q(Please specify a filename to use for the index,));
                        $logger->warn(
                            q(or use the --dbfile switch on the command line));
                        $logger->warn( q(Try ') . $Config->get(q(program_name))
                            . q( --help' to see more options) );
                    } # if ( $Config->get(q(dbfile)) )
                }, # idx->load->proc
            }, # idx->load
            'lo'     =>  { syn => q(load) },
            ### show
            'show' => {
                desc => q(Displays the index filename),
                proc => sub {
                    $logger->info(q(The current index filename is:));
                    $logger->info($Config->get(q(dbfile)));
                }, # idx->show->proc
            }, # idx->show
            'sh' => { syn => q(show) },
            ### count
            'count' => {
                desc => q(Displays the count of records in the index),
                proc => sub {
                    $moddep->show_index_count();
                }, # idx->show->proc
            }, # idx->show
            'co' => { syn => q(count) },
        }, # idx->cmds
    }, # idx
### show
	'show'	=>  { desc => q(Shows examples/current configuration values),
#maxargs => 1,
		cmds => {
		    ### examples
    		'example' => {
                desc => q(A 'moddep' usage example),
		        proc => sub { print <<EXAMPLES
  Steps to follow to generate and query from a dependency index:
  1) Verify the script knows where to     'show libpaths'
     find Perl modules
  2) Add paths for searching for Perl     'set libpath /perl/module/path'
  3) Create an index file:                'idx create /path/to/index/file.db'
  4) Generate the index:                  'idx generate'
  5) Query the index with one or more     'get IO::Socket File::Basename'
     module names
EXAMPLES
				}, # show->examples->proc
        	}, # show->examples
	    	'examples'  =>  { syn => q(example) },
	    	'ex'        =>  { syn => q(example) },
            ### index
            'idx' => {
                desc => q(Displays the index filename),
                proc => sub {
                    $logger->info(q(The current index filename is:));
                    $logger->info($Config->get(q(dbfile)));
                }, # show->idx->proc
            }, # show->idx
            'index'     => { syn => q(idx) },
            'in'        => { syn => q(idx) },
            'id'        => { syn => q(idx) },
            ### count
            'count' => {
                desc => q(Displays the count of records in the index),
                proc => sub {
                    $moddep->show_index_count();
                }, # idx->show->proc
            }, # idx->show
            'co' => { syn => q(count) },
            ### libpath
            'libpath' => {
                desc => q(Displays the Perl library paths used to find modules),
                proc => sub {
                    $logger->info(q(The current Perl library paths are:));
					foreach my $path ( @{$Config->get(q(libpath))} ) {
	                    $logger->info(qq(\t$path));
					} # foreach my $path ( $Config->get(q(libpath))
                }, # show->libpath->proc
            }, # show->libpath
            'libpaths'	=> { syn => q(libpath) },
            'lp'     	=> { syn => q(libpath) },
            'lib'     	=> { syn => q(libpath) },
            'li'     	=> { syn => q(libpath) },
            ### modlist
            'modlist' => {
                desc => q(Displays the index filename),
				cmds => {
					### names 
					'names' => {
						desc => q(Shows the modules used for a 'get' command),
						proc => sub {
							$logger->info(q(The following modules will have));
							$logger->info(q(depedency info returned with a ));
							$logger->info(q('get' command:));
							foreach my $modulename ( @modlist ) {
								$logger->info(qq(\t$modulename));
							} # foreach my $modulename ( @modlist )
						}, # show->modlist->names->proc
					}, # show->modlist->names
					'na'	=> { syn => q(names) },
					'nam'	=> { syn => q(names) },
					### count
					'count' => {
						desc => q(A count of all of the dependent modules),
						proc => sub {
							# get the dependencies for each module, and then
							# make a summary object which holds the information
							# that we're looking for
							my %returned_count;
							my $return_type;
							if ($Config->get(q(returned_info)) & CHILDREN){	
								$return_type = q(CHILDREN);
							} elsif ($Config->get(q(returned_info)) & PARENTS){
								$return_type = q(PARENTS);
							} # if ($Config->get(q(returned_info)) & CHILDREN)
							foreach my $countmod ( @modlist ) {
								my $raw_string = q(raw_) . lc($return_type);
								my $returned_list = $moddep->get_module_deps(
									modlist     => [ $countmod ],
									return_raw  => 1,
				                  	return_info => $return_type);
								foreach my $module (@{$returned_list}) {
									$returned_count{$module}++;
								} # foreach my $childcount
							} # foreach my $countmod ( @modlist )
							if ( scalar(keys(%returned_count)) > 0 ) {
								$logger->info(q(Total dependencies by module:));
								$logger->info(qq(\tcount -> module name));
								foreach my $mod_key ( 
                                    sort (keys(%returned_count)) ) {
								# list the modules here in most -> least count
								# order
									$logger->info(qq(\t)
                                        . $returned_count{$mod_key} 
                                        . qq( -> $mod_key) );
								} # foreach my $mod_key ( keys(%returned_count)
							} # if ( scalar(keys(%returned_count)) > 0 ) 
						}, # show->modlist->count->proc
					}, # show->modlist->count
					'co'	=> { syn => q(count) },
					'cou'	=> { syn => q(count) },
					### initramfslist
					'initramfslist' => {
						desc => 
							q(Output a gen_init_cpio formatted list of modules),
						proc => sub {
							my %filename_list;
							my @dependency_list = 
								&get_filename_list(@modlist);

							print qq(WARNING: this list needs work;\n);
							print qq(You'll have to add directories )
								. qq((<dir>) tags at the very least.\n);
							print qq(See the 'gen_init_cpio' docs in )
								. qq(the Linux kernel for usage info.\n);
                            print qq(=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n);
							# run through the module list and stat each file
							# print out the file's details in initramfs format
							# file <name> <source> <mode> <uid> <gid>
							foreach my $dep_file (@dependency_list) {
								my ($dev,$ino,$mode,$nlink,$uid,$gid,
									$rdev,$size,$atime,$mtime,$ctime,
									$blksize,$blocks) = stat($dep_file);
								# mangle the mode
								my $mangledmode 
									= sprintf("%04o", $mode & 07777);
								print qq(file $dep_file $dep_file $mangledmode )
									. qq($uid $gid\n);
							} # foreach my $dep_file (@dependency_list)
						}, # show->modlist->initramfslist->proc
					}, # show->modlist->initramfslist
					'init'    	=> { syn => q(initramfslist) },
					'ini'    	=> { syn => q(initramfslist) },
					'il'    	=> { syn => q(initramfslist) },
					'in'    	=> { syn => q(initramfslist) },
					'ramfs' 	=> { syn => q(initramfslist) },
					'initramfs' => { syn => q(initramfslist) },
					### size
					'size' => {
						desc => q(A list of dependent modules with sizes),
						proc => sub {
							my %filename_list;
							my @dependency_list = 
								&get_filename_list(@modlist);
							foreach my $dep_file (@dependency_list) {
								$filename_list{$dep_file} 
									= (stat($dep_file))[7];	
							} # foreach my $dep_file (@dependency_list)

							if ( scalar(keys(%filename_list)) > 0 ) {
								$logger->info(q(File sizes by binary/module:));
								$logger->info(qq(\tsize -> filename));
								# $^X is perl-ese for the running perl binary
								my $perlsize = (stat($^X))[7];
                                if ( ! defined $perlsize ) { 
                                    $perlsize = q(undef);
                                } # if ( ! defined $perlsize )
								my $total_file_sizes = $perlsize;
								$logger->info(qq(\t$perlsize -> ) . $^X);
								# now do all of the modules
								foreach my $mod_key ( 
									sort(keys(%filename_list)) ) 
								{
									# list the module file sizes and the
									# modules here in alphabet order
									$logger->info(qq(\t) . 
										$filename_list{$mod_key} 
										. qq( -> $mod_key));
									$total_file_sizes +=
										$filename_list{$mod_key};
								} # foreach my $mod_key ( keys(%returned_count)
								$logger->info(qq(Total size of all files: ) 
									. $total_file_sizes);
							} # if ( scalar(keys(%filename_list)) > 0 )
						}, # show->modlist->size->proc
					}, # show->modlist->size
					'si'	=> { syn => q(size) },
					'siz'	=> { syn => q(size) },
                }, # show->modlist->cmds
            }, # show->modlist
            'mods'  => { syn => q(modlist) },
            'mod'   => { syn => q(modlist) },
            'mo'    => { syn => q(modlist) },
            'ml'    => { syn => q(modlist) },
            ### returnedinfo
            'returnedinfo' => {
                desc => q(Sets information is returned during a 'get' query),
                proc => sub {
                    my @ri_strings;
                    my $ri_bitmask = $Config->get(q(returned_info));
                    if ( $ri_bitmask == 0 ) {
                        $logger->info(q(returned_info is currently NONE));
                    } else {
                        if ( $ri_bitmask & PARENTS ) {
                            push(@ri_strings, q(PARENTS));
                        }  # if ( $ri_bitmask & PARENTS )
                        if ( $ri_bitmask & CHILDREN ) {
                            push(@ri_strings, q(CHILDREN));
                        } # if ( $ri_bitmask & CHILDREN )
                        if ( $ri_bitmask & FILENAME ) {
                            push(@ri_strings, q(FILENAME));
                        } # if ( $ri_bitmask & FILENAME )
                        $logger->debug(q(returned_info bitmask is: )
                            . sprintf("0b%04b: ", 
                                $Config->get(q(returned_info))) );
                        $logger->info(q(returned_info is currently:));
                        $logger->info( join(q( ), @ri_strings) );
                    } # if ( $ri_bitmask == 0 )
                }, # show->returnedinfo->proc
            }, # show->returnedinfo
            'ri'        => { syn => q(returnedinfo) },
            'returned'  => { syn => q(returnedinfo) },
		}, # show->cmds
	}, # show
	'sh'     =>  { syn => q(show) },
	'sho'    =>  { syn => q(show) },
### set 
	'set' => { 
        desc => q(Sets script configuration values),
		cmds => {
		    ### returnedinfo
    		'returnedinfo' => {
                desc => q(Tells the script which values to return for queries),
                proc  => sub {
                    # we use foreach instead of a separate set of menu commands
                    # because this way we can specify multiple items at once
                    # FIXME the below tests will toggle the bit; set it once to
                    # turn it on, set it again to turn it back off; NONE will
                    # turn *all* of the bits off
                    foreach my $ri_arg ( @_ ) {
                        $logger->debug(q(returned_info bitmask is currently:)
                            . sprintf("0b%04b",
                                $Config->get(q(returned_info))) );
                        my $current_ri = $Config->get(q(returned_info));
                        if ( $ri_arg =~ /^pa.*$/i ) {
                            # PARENTS
                            $Config->set(q(returned_info), 
                                $current_ri | PARENTS);
                            $logger->info(q(Enabled returning PARENTS )
                                . q(dependency info));
                        } elsif ( $ri_arg =~ /^ch.*$/i ) {
                            # CHILDREN
                            $Config->set(q(returned_info), 
                                $current_ri | CHILDREN);
                            $logger->info(q(Enabled returning CHILDREN )
                                . q(dependency info));
                        } elsif ( $ri_arg =~ /^fi.*$/i ) {
                            # FILENAME
                            $Config->set(q(returned_info), 
                                $current_ri | FILENAME);
                            $logger->info(q(Enabled returning FILENAME )
                                . q(dependency info));
                        } elsif ( $ri_arg =~ /^al.*$/i ) {
                            $Config->set(q(returned_info), 
                                $current_ri | CHILDREN | PARENTS | FILENAME );
                            $logger->info(q(Enabled returning ALL )
                                . q(dependency info));
                        } elsif ( $ri_arg =~ /^no.*$/i ) {
                            # NONE
                            $Config->set(q(returned_info), 0b0);
                            $logger->info(q(Cleared returned information mask));
                        } # if ( $ri_arg =~ /^pa.*$/i )
                        $logger->debug(q(returned_info bitmask is now:)
                            . sprintf("0b%04b",
                                $Config->get(q(returned_info))) );
                    } # foreach my $ri_arg ( @_ )
                }, # set->returnedinfo->proc
            }, # set->returnedinfo
            'ri'        => { syn => q(returnedinfo) },
            'returned'  => { syn => q(returnedinfo) },
        }, # set->cmds
    }, # set
	'se'     =>  { syn => q(set) },
### get
	'get'  =>  { desc => q(Get the dependencies for one or more Perl modules),
	# if getfiles is defined, or the file is passed in on @_
    	proc => sub {
            if ( ! $moddep->is_index_generated() 
				|| ! $moddep->is_index_created() ) 
			{
				$moddep->show_not_generated_warning(q(get));
                return;
            } # if ( ! $moddep->is_index_generated() )
			# if either the @modlist or the @_ array has values 
			if ( scalar (@modlist) || scalar(@_) ) {
                # any files passed in replace the files that were in @modlist
				if ( scalar(@_) ) {
					# reset @modlist before we assign to it, or we will end up
					# appending the new entries
                    @modlist = undef;
                    @modlist = @_;
				} # if ( scalar(@_) )
                # getfiles may have multiple entries; loop across each one of
                # them
				$logger->debug(q(modlist currently holds:));
				$logger->debug( join(q(;), @modlist) );
				$logger->debug(q(the following modules were passed in:));
				$logger->debug( join(q(;), @_) );
                if ( $Config->get(q(returned_info)) & CHILDREN ) {
                    $moddep->get_module_deps(
                            modlist     => [ @modlist ], 
                            return_info => q(CHILDREN) );
                } # if ( $Config->get(q(returned_info)) & CHILDREN )
                if ( $Config->get(q(returned_info)) & PARENTS ) {
                    $moddep->get_module_deps(
                            modlist     => [ @modlist ] ,
                            return_info => q(PARENTS) );
                } # if ( $Config->get(q(returned_info)) & PARENTS )
                if ( $Config->get(q(returned_info)) & FILENAME ) {
                    $moddep->get_module_deps(
                            modlist     => [ @modlist ],
                            return_info => q(FILENAME) );
                } # if ( $Config->get(q(returned_info)) & FILENAME )
			} else {
				$logger->warn(q(Please input one or more modules to look));
				$logger->warn(q(up dependencies for.));
			} # if ( scalar @modlist > 0 || scalar(@_) )
		}, # get->proc
	}, # get
	'ge'     =>  { syn => q(get) },
### graph 
	'graph'	=>  { desc => q(Shows module dependencies in an image),
		cmds => {
			'dependencies' => {
				desc => q(Flag for whether or not to recurse dependencies),
                proc => sub { 
					$logger->warn(q(This command is not implemented));
                }, # graph->cmds->dependencies->proc
            }, # graph->cmds->dependencies
			'de'     =>  { syn => q(dependencies) },
			'dep'     =>  { syn => q(dependencies) },
			'deps'     =>  { syn => q(dependencies) },
        }, # graph->cmds
    }, # graph
	'gr'     =>  { syn => q(graph) },
	} # return
} # sub get_commands

sub get_filename_list {
	my @modlist = @_;

	my %filename_list;
	# grab the names for the modules in @modlist and
	# their children
	foreach my $getnamemod ( @modlist ) {
		# look up the filename of the module itself
		my $mod_filename = $moddep->get_module_deps(
			suppress_stop_time 	=> 1,
			modlist     		=> [ $getnamemod ],
			return_raw 			=> 1,
			return_info 		=> q(FILENAME));
		$filename_list{$mod_filename} = undef;

		#$logger->debug(qq($getnamemod: mod_filename));
		#&_dump_hash(\%filename_list);

		# grab a list of children modules
		my $mod_children = $moddep->get_module_deps(
			suppress_stop_time 	=> 1,
			modlist     		=> [ $getnamemod ],
			return_raw 			=> 1,
			return_info 		=> q(CHILDREN));

		# now get their filenames as well
		foreach my $child_key ( @{$mod_children} ) {
			my $this_child = $moddep->get_module_deps(
				suppress_stop_time 	=> 1,
				modlist     		=> [ $child_key ],
				return_raw 			=> 1,
				return_info 		=> q(FILENAME));
				
			if ( defined $this_child ) {
				$filename_list{$this_child} = undef;
			} # if ( defined $this_child )
		} # foreach $child_key ( @{$mod_children} )

		#$logger->debug(qq($getnamemod: mod_children));
		#&_dump_hash(\%filename_list);

	} # foreach my $countmod ( @modlist )

	# now get the full paths for all of the files
	foreach my $filename_key ( keys(%filename_list) ) {
		my $fullpath = &get_fullpath(	
							filename => $filename_key,
							Config => $Config );
		# delete the old name from the list hash
		delete($filename_list{$filename_key});
		# add it back with the full name as the key and
		# stat it at the same time
		$filename_list{$fullpath} = undef;
	} # foreach my $filename_key ( keys(%filename_list)

	#$logger->debug(q(dumping after fullpathing));
	#&_dump_hash(\%filename_list);
					
	# return the keys from %filename_list, which will be the list of resolved
	# filenames
	return keys(%filename_list);
} # sub get_filename_list

sub get_fullpath {
	my %args = @_;
	my $Config = $args{Config};
	my $filename = $args{filename};
	my $logger = get_logger();

	foreach my $libpath ( @{$Config->get(q(libpath))} ) {
        # strip extra slashes off of the end
        $libpath =~ s/\/+$//;
		my $fullpath = qq($libpath/$filename);
		$logger->debug(qq(Searching $libpath for $filename));
		if ( -r $fullpath ) {
			# first filename found will win
			return $fullpath;
		} # if ( -r $mod_filename )
	} # foreach my $libpath

	# uh-oh, we shouldn't reach this, the original module path was found by
	# searching the paths that the script already knows about
	$logger->error_die(qq(Can't find the full path for '$filename'));
} # sub get_fullname

sub _dump_hash {
	my $tmphash = shift;

	if ( $logger->is_debug() ) {
		my %dump_hash = %$tmphash;
		$logger->debug(q(key/value pairs from %filename_list));
		foreach my $kvp ( sort(keys(%dump_hash)) ){
			if ( defined $dump_hash{$kvp} ) {
				$logger->debug($kvp . q( -> ) . $dump_hash{$kvp} );
			} else {
				$logger->debug($kvp . q( -> 'undef') );
			} # if ( defined $dump_hash{$kvp} )
		} # foreach my $kvp (sort(keys(%filename_list))
	} # if ( $logger->is_debug() )
} # sub _dump_hash

sub confirm {
	my %args = @_;
	my $logger = get_logger();
	$logger->warn($args{confirm_warning});
	print $args{prompt} . q( );
	my $read;
	$read = <STDIN>;
	return 1 if ( $read =~ /y/ig ); 
	return undef;
} # sub confirm

############
# ShowHelp #
############
sub ShowHelp {
# shows the help message
    warn qq(\nUsage: $0 [options]\n\n);
    warn qq([options] may consist of one or more of the following:\n);
    warn qq(\n General Options:\n);
    warn qq( -h|--help          show this help\n);
    warn qq( -f|--dbfile        file to use for storing index data\n);
    warn qq( -m|--module	    Perl module to work out dependencies for\n);
    warn qq(   (use --module multiple times to specifiy multiple modules)\n);
    warn qq( -p|--libpath       Perl library path to search\n);
    warn qq(   (use --libpath multiple times to specifiy multiple paths)\n);
    warn q( -inc|--useincpath  add/use paths from the '@INC' variable). qq(\n);
	warn qq(\n Switches that control script behaivor:\n);
    warn qq( -d|--debug         run in debug mode (extra noisy output)\n);
    warn qq( -i|--interactive   run in interactive mode (default)\n);
    warn qq( -noi|--nointeractive   Don't run in interactive mode\n);
    warn qq( -nc|--noconfirm    don't confirm before deleting files\n);
    warn qq( -ns|--noseed       don't seed 'libpath'\n);
    warn qq( (Please use --libpath to specifiy non-standard paths on OS X)\n);
    warn qq( -nocl|--nocolorlog don't colorize the shell output\n);
	warn qq(\n);
	exit 0;
} # sub ShowHelp

# vi: set ft=perl sw=4 ts=4 cin:
