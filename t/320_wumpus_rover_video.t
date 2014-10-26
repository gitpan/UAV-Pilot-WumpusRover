# Copyright (c) 2014  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
use Test::More tests => 4;
use v5.14;
use UAV::Pilot;
use UAV::Pilot::WumpusRover::Driver::Mock;
use UAV::Pilot::WumpusRover::Video::Mock;
use UAV::Pilot::Video::FileDump;
use File::Temp ();
use AnyEvent;
use Test::Moose;

use constant VIDEO_DUMP_FILE         => 't_data/wumpus_video_stream_dump.wump';
use constant MAX_WAIT_TIME           => 15;
use constant EXPECT_FRAMES_PROCESSED => 24;
use constant EXPECT_SIZE             => 98_304;

my ($OUTPUT_FH, $OUTPUT_FILE) = File::Temp::tempfile(
    'wumpus_video_stream.h264.XXXXXX',
    UNLINK => 1,
);


my $control_video = UAV::Pilot::Video::FileDump->new({
    fh => $OUTPUT_FH,
});

my $cv = AnyEvent->condvar;
my $wumpus = UAV::Pilot::WumpusRover::Driver::Mock->new({
    host => 'localhost',
});
my $driver_video = UAV::Pilot::WumpusRover::Video::Mock->new({
    file      => VIDEO_DUMP_FILE,
    handlers  => [ $control_video ],
    condvar   => $cv,
    driver    => $wumpus,
});
isa_ok( $driver_video => 'UAV::Pilot::WumpusRover::Video' );


my $pass_timer; $pass_timer = AnyEvent->timer(
    after    => 1,
    interval => 0.1,
    cb       => sub {
        my $pass = (EXPECT_SIZE == -s $OUTPUT_FILE);
        if( EXPECT_SIZE == -s $OUTPUT_FILE ) {
            pass( 'File '
                . $OUTPUT_FILE
                . ' matches expected size '
                . EXPECT_SIZE );
            $cv->send( 'Pass' );
        }
        $pass_timer;
    },
);
my $timeout_timer; $timeout_timer = AnyEvent->timer(
    after => MAX_WAIT_TIME,
    cb    => sub {
        fail( 'File '
            . $OUTPUT_FILE
            . ' did not match expected size '
            . EXPECT_SIZE
            . ' after '
            . MAX_WAIT_TIME
            . ' seconds.'
            . '  Actual size is '
            . (-s $OUTPUT_FILE)
            . '.' );
        $cv->send( 'Failed' );
        $timeout_timer;
    },
);


$driver_video->init_event_loop;
$cv->recv;

cmp_ok( $driver_video->frames_processed, '==', EXPECT_FRAMES_PROCESSED,
    'Expected number of frames processed' );
cmp_ok( $driver_video->heartbeat_count, '==', EXPECT_FRAMES_PROCESSED,
    'Heartbeats sent' );


close $OUTPUT_FH;
