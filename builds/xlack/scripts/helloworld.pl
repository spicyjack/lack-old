#!/usr/bin/perl -w

# Quick Gtk2-Perl demo script
# Copyright (c) 2008 Brian Manning <elspicyjack at gmail dot com>
# Used ideas from the following webpages:
# http://forgeftp.novell.com/gtk2-perl-study/documentation/html/c1091.html
# and probably others

# trig math was obtained from "Trigonometry the Easy Way" (ISBN 0812027175)

use strict;
use warnings;
use utf8;
use Math::Trig;
use Time::HiRes qw(usleep);
# import the TRUE/FALSE constants from Glib prior to loading Gtk2
use Glib qw(TRUE FALSE);
# Gtk2->init; works if you don't use -init on use
use Gtk2 -init;

my ($start_x, $start_y, $current_x, $current_y);
my ($rho, $theta);
my $move_dialog = 0;

sub dialog_move {
    my $toplevel = shift;
    my $move_direction = shift;

    #print qq(entering dialog_move; current theta/rho $theta/$rho\n);
    # grab the current starting position
    if ( $move_direction eq q(center) ) {
        while ( $current_x != $start_x && $current_y != $start_y ) {
            # move the current x and y 
            # if current == start, don't increment/decrement value
            if ( $current_x < $start_x ) { 
                $current_x ++; 
            } elsif ( $current_x > $start_x ) {
                $current_x --; 
            }
            if ( $current_y < $start_y ) { 
                $current_y++; 
            } elsif ( $current_y > $start_y ) {
                $current_y--; 
            }
            $toplevel->move($current_x, $current_y); 
        } # while ( $current_x != $start_x && $current_y != $start_y )
    } else {
        $theta += 0.5;
        if ( $theta < 360 ) {
            # generate the new x and y 
            # absolute value of the sine/cosine of the angle
            my $new_x = int(abs($rho * cos(deg2rad($theta))));
            my $new_y = int(abs($rho * sin(deg2rad($theta))));
            #print qq( for theta $theta, the new x/y values are: )
            #    . qq($new_x, $new_y\n);
            # if current == start, don't increment/decrement value
            if ( $new_y != 0 ) {
                $toplevel->move($new_x, $new_y); 
            }
            return 0;
        } else {
            return 1;
        } # if ( $theta < 360 )
    } # if ( $move_direction eq q(center) )
} # sub move_dialog

sub launch_terminal {
    my $top = shift;

    if ( $move_dialog == 0 ) {
        return TRUE; 
    } # if ( $move_dialog == 0 ) 

    if ( &dialog_move($top, q(notcenter)) == 1 ) {
        if ( -e q(start_term.sh) ) {
            system( q(start_term.sh &) );
        } elsif ( -e q(/etc/scripts/start_term.sh) ) {
            system( q(start_term.sh &) );
        } else {
            warn q(ERROR: can't locate 'start_term.sh' script!);
        } # if ( -e $mrxvt )
        return FALSE;
    } else {
        return TRUE;
    } # if ( &move_dialog($toplevel, q(notcenter)) == 1 )
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
my $launch_timeout_source_id;
$term->signal_connect (clicked => sub { 
    print qq(setting move_dialog to 1\n);
    $move_dialog = 1; } );
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
# get the current rho/theta with the center of the circle being 0,0
$rho = sqrt( ($start_x**2) + ($start_y**2) );
$theta = 360 - rad2deg(atan2($start_y, $start_x));
# use the GDK window() object created by Gtk2::Gdk to set the cursor
$toplevel->window->set_cursor($cursor);

# create a timeout object to check and see if the main window needs to be
# moved
Glib::Timeout->add( 20, \&launch_terminal, $toplevel );

# yield to Gtk2 and wait for user input
Gtk2->main;
