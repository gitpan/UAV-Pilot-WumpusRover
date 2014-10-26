use Test::More tests => 14;
use v5.14;
use UAV::Pilot::WumpusRover::Driver::Mock;
use Test::Moose;

my $wumpus = UAV::Pilot::WumpusRover::Driver::Mock->new({
    host => 'localhost',
    port => 49005,
});
isa_ok( $wumpus => 'UAV::Pilot::WumpusRover::Driver' );
does_ok( $wumpus => 'UAV::Pilot::Driver' );
cmp_ok( $wumpus->port, '==', 49005, "Port set" );

ok( $wumpus->connect, "Connect to WumpusRover" );
my $startup_request_packet = $wumpus->last_sent_packet;
isa_ok( $startup_request_packet
    => 'UAV::Pilot::WumpusRover::Packet::RequestStartupMessage' );

$wumpus->send_radio_output_packet( 150 );
my $radio1_packet = $wumpus->last_sent_packet;
isa_ok( $radio1_packet => 'UAV::Pilot::WumpusRover::Packet::RadioOutputs' );
cmp_ok( $radio1_packet->ch1_out, '==', 150, "Channel1 set" );

$wumpus->send_radio_output_packet( 150, 70 );
my $radio2_packet = $wumpus->last_sent_packet;
cmp_ok( $radio2_packet->ch1_out, '==', 150, "Channel1 set" );
cmp_ok( $radio2_packet->ch2_out, '==', 70,  "Channel2 set" );


my ($first_queue_packet_key) = keys %{ $wumpus->_packet_queue };
my $first_queue_packet = $wumpus->_packet_queue->{$first_queue_packet_key};
my $cur_packet_queue_len = $wumpus->_packet_queue_size;
my $packet_queue_max_len = $wumpus->MAX_PACKET_QUEUE_LENGTH;
while( $cur_packet_queue_len <= $packet_queue_max_len ) {
    my $packet = make_dummy_ack();
    $wumpus->_add_to_packet_queue( $packet );
    $cur_packet_queue_len++;
}


cmp_ok( $wumpus->_packet_queue_size, '==', $packet_queue_max_len,
    "Packet queue at maximum" );
($first_queue_packet_key) = keys %{ $wumpus->_packet_queue };
$first_queue_packet = $wumpus
    ->_packet_queue
    ->{$first_queue_packet_key};
cmp_ok( "$first_queue_packet", 'eq', "$first_queue_packet",
    "First packet still the same" );

my $one_too_many = make_dummy_ack();

$wumpus->_add_to_packet_queue( $one_too_many );
my ($new_first_queue_packet_key) = keys %{ $wumpus->_packet_queue };
my $new_first_queue_packet = $wumpus
    ->_packet_queue
    ->{$new_first_queue_packet_key};
cmp_ok( $wumpus->_packet_queue_size, '==', $packet_queue_max_len,
    "Packet queue still at maximum" );
cmp_ok( "$first_queue_packet", 'ne', "$new_first_queue_packet",
    "Oldest packet pushed out" );

($first_queue_packet_key) = keys %{ $wumpus->_packet_queue };
$first_queue_packet = $wumpus
    ->_packet_queue
    ->{$first_queue_packet_key};
diag( "First queue packet key [$first_queue_packet_key], generated key: [" . $first_queue_packet->make_packet_queue_map_key . ']' );
$cur_packet_queue_len = $wumpus->_packet_queue_size;
my $ack_old_packet = UAV::Pilot::WumpusRover::PacketFactory->fresh_packet(
    'Ack' );
$ack_old_packet->checksum_received1( $first_queue_packet->checksum1 );
$ack_old_packet->checksum_received2( $first_queue_packet->checksum2 );
$ack_old_packet->message_received_id( $first_queue_packet->message_id );
$ack_old_packet->make_checksum_clean;
$wumpus->_process_ack( $ack_old_packet );
cmp_ok( $wumpus->_packet_queue_size, '==', $cur_packet_queue_len - 1,
    "Removed a packet" );


sub make_dummy_ack
{
    my $packet = UAV::Pilot::WumpusRover::PacketFactory->fresh_packet( 'Ack' );
    $packet->checksum_received1( int rand 0xFF );
    $packet->checksum_received2( int rand 0xFF );
    $packet->message_received_id( 0x01 );
    $packet->make_checksum_clean;
    return $packet;
}
