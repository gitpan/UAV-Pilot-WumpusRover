use v5.14;
use UAV::Pilot::Exceptions;
use UAV::Pilot::Events;
use UAV::Pilot::EasyEvent;


{
    my $dev         = undef;
    my $cv          = undef;
    my $events      = undef;
    my $easy_events = undef;

    # TODO
    # Make this into a role so ARDrone and WumpusRover can share the code
    my $init_events = sub {
        return 1 if defined $events;
        die "Can't init UAV::Pilot::Events without a condvar\n" unless defined $cv;

        $events = UAV::Pilot::Events->new({
            condvar => $cv,
        });

        $events->init_event_loop;

        # If we can load SDL, then init it here
        eval "use UAV::Pilot::SDL::Events";
        if(! $@ ) {
            my $sdl_events = UAV::Pilot::SDL::Events->new;
            $events->register( $sdl_events );
        }

        $dev->init_event_loop( $cv, $easy_events );
        return 1;
    };

    my $vid_driver = undef;
    my $init_vid_driver = sub {
        return 1 if defined $vid_driver;

        $vid_driver = UAV::Pilot::WumpusRover::Video->new({
            condvar => $cv,
            driver  => $dev->driver,
        });
        $vid_driver->init_event_loop;

        return 1;
    };

    sub uav_module_init
    {
        my ($class, $cmd, $args) = @_;
        $cv = $args->{condvar};

        $easy_events = UAV::Pilot::EasyEvent->new({
            condvar => $cv,
        });
        $easy_events->init_event_loop;

        $dev = $cmd->controller_callback_wumpusrover->(
            $cmd, $cv, $easy_events );
        return 1;
    }

    sub throttle ($)
    {
        my ($value) = @_;
        $dev->throttle( $value );
        return 1;
    }

    sub turn ($)
    {
        my ($value) = @_;
        $dev->turn( $value );
        return 1;
    }

    sub stop ()
    {
        $dev->throttle( 0 );
        $dev->turn( 0 );
        return 1;
    }

    # TODO
    # Make this into a role so ARDrone and WumpusRover can share the code
    sub start_joystick ()
    {
        $init_events->();
        eval "use UAV::Pilot::SDL::Joystick";
        die "Problem loading UAV::Pilot::SDL::Joystick: $@\n" if $@;

        my $joystick = UAV::Pilot::SDL::Joystick->new({
            condvar => $cv,
            events  => $easy_events,
        });
        $events->register( $joystick );

        say 'Ready for joystick input on ['
            . SDL::Joystick::name( $joystick->joystick->index )
            . ']';

        return 1;
    }

    sub dump_video_to_file ($)
    {
        my ($file) = @_;
        $init_vid_driver->();

        open( my $fh, '>', $file ) or UAV::Pilot::IOException->throw({
            error => "Can't open [$file] for reading: $!\n",
        });
        my $vid_dump = UAV::Pilot::Video::FileDump->new({
            fh => $fh,
        });

        $vid_driver->add_handler( $vid_dump );
        say "Dumping video to file '$file'";
        return 1;
    }
}

# TODO
# Implement video
#sub start_video ()
#{
#}

# TODO
# Implement taking picture
#sub take_picture ($)
#{
#    my ($file) = @_;
#}



# TODO
# Implement telemetry on server
#sub start_nav ()
#{
#}




1;
