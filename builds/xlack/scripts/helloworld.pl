#!/usr/bin/perl -w

# Quick Gtk2-Perl demo script
# Copyright (c) 2008 Brian Manning <elspicyjack at gmail dot com>
# Used ideas from the following webpages:
# http://forgeftp.novell.com/gtk2-perl-study/documentation/html/c1091.html
# and probably others

use strict;
use warnings;
use utf8;
use Time::HiRes qw(usleep);
# import the TRUE/FALSE constants from Glib prior to loading Gtk2
use Glib qw(TRUE FALSE);
# Gtk2->init; works if you don't use -init on use
use Gtk2 -init;

my $mrxvt = q(/usr/bin/mrxvt);
my $xterm = q(/usr/bin/xterm +sb);
my ($start_x, $start_y);

sub move_launcher {
    my $toplevel = shift;
    my $move_direction = shift;

    # grab the current starting position
    my ($current_x, $current_y) = $toplevel->get_position();   
    if ( $move_direction eq q(center) ) {
        while ( $current_x != $start_x && $current_y != $start_y ) {
            # move the current x and y 
            # if current == start, don't increment/decrement value
            if ( $current_x < $start_x ) { 
                $current_x++; 
            } elsif ( $current_x > $start_x ) {
                $current_x--; 
            }
            if ( $current_y < $start_y ) { 
                $current_y++; 
            } elsif ( $current_y > $start_y ) {
                $current_y--; 
            }
            $toplevel->move($current_x, $current_y); 
            usleep 500;
        } # while ( $current_x != $start_x && $current_y != $start_y )
    } else {
        # pick a random spot at the top of the screen and go there 
        my $screen = $toplevel->get_screen();
        my $screen_width = $screen->get_width();
        my $new_x = int(rand($screen_width));
        while ( $current_x != $new_x && $current_y != 0 ) {
            # move the current x and y 
            # if current == start, don't increment/decrement value
            if ( $current_x < $new_x ) { 
                $current_x++; 
            } elsif ( $current_x > $new_x ) {
                $current_x--; 
            }
            if ( $current_y > 0 ) { 
                $current_y--; 
            }
            $toplevel->move($current_x, $current_y); 
            usleep 500;
        } # while ( $current_x != $start_x && $current_y != $start_y )
        warn(q(new x and y are: ) . $current_x . qq(x ) . $current_y);
    } # if ( $move_direction eq q(center) )
} # sub move_launcher

sub launch_terminal {
    my $toplevel = shift;

    my $terminal;
    if ( -e $mrxvt ) {
        #$terminal = $mrxvt;
        $terminal = $xterm;
    } else {
        $terminal = $xterm;
    } # if ( -e $mrxvt )
    warn qq(toplevel isa ) . ref($toplevel);
    &move_launcher($toplevel, q(notcenter));
    system(qq($terminal -geometry +0-0 &));
} # sub launch_terminal

### MAIN SCRIPT
# create the mainwindow
my $toplevel = Gtk2::Window->new (q(toplevel));

# create a VBox to hold a label and a button
my $vbox = Gtk2::VBox->new(FALSE, 5);

# create a label with some text
my $label_text = "Hello world!\n";
$label_text .= "Здравствуйте!\n";
my $label = Gtk2::Label->new($label_text);
# pack the label, expand == true, fill == true, 5 pixels padding
$vbox->pack_start($label, TRUE, TRUE, 2);

# create a 'launch' button
my $term = Gtk2::Button->new (q|Launch a Terminal Window|);
# connect the button's 'click' signal to an action
$term->signal_connect (clicked => sub { 
    my $self = shift;
    my $top = shift;
    warn qq(toplevel isa ) . ref($top);
    &launch_terminal($top);
    }, $toplevel);
#$term->signal_connect (clicked => \&launch_terminal($toplevel) );
# pack the button, expand == false, fill == FALSE, 5 pixels padding
$vbox->pack_start($term, FALSE, FALSE, 2);

# CREATE a 'quit' button
my $quit = Gtk2::Button->new (q|Quit (Restarts XWindows)|);
# connect the button's 'click' signal to an action
$quit->signal_connect (clicked => sub { Gtk2->main_quit });
# pack the button, expand == false, fill == FALSE, 5 pixels padding
$vbox->pack_start($quit, FALSE, FALSE, 2);

# set the cursor on the display object
my $cursor = Gtk2::Gdk::Cursor->new(q(left_ptr));

# add the vbox
$toplevel->add($vbox);
# center the window
$toplevel->set_position(q(center));
# show the window
$toplevel->show_all;
# set the starting position of the window
($start_x, $start_y) = $toplevel->get_position();
# use the GDK window() object created by Gtk2::Gdk to set the cursor
$toplevel->window->set_cursor($cursor);

# yield to Gtk2 and wait for user input
Gtk2->main;
