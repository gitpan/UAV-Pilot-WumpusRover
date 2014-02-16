use Test::More tests => 15;
use v5.14;

use_ok( 'UAV::Pilot::WumpusRover' );
use_ok( 'UAV::Pilot::WumpusRover::Control' );
use_ok( 'UAV::Pilot::WumpusRover::Control::Event' );
use_ok( 'UAV::Pilot::WumpusRover::Driver' );
use_ok( 'UAV::Pilot::WumpusRover::Packet' );
use_ok( 'UAV::Pilot::WumpusRover::Packet::Ack' );
use_ok( 'UAV::Pilot::WumpusRover::Packet::Heartbeat' );
use_ok( 'UAV::Pilot::WumpusRover::Packet::RadioMaxes' );
use_ok( 'UAV::Pilot::WumpusRover::Packet::RadioMins' );
use_ok( 'UAV::Pilot::WumpusRover::Packet::RadioOutputs' );
use_ok( 'UAV::Pilot::WumpusRover::Packet::RadioTrims' );
use_ok( 'UAV::Pilot::WumpusRover::Packet::RequestStartupMessage' );
use_ok( 'UAV::Pilot::WumpusRover::Packet::StartupMessage' );
use_ok( 'UAV::Pilot::WumpusRover::PacketFactory' );
use_ok( 'UAV::Pilot::WumpusRover::Video' );
