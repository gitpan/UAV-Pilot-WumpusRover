package UAV::Pilot::WumpusRover::Packet::Ack;
use v5.14;
use Moose;
use namespace::autoclean;


use constant {
    payload_length => 3,
    message_id     => 0x00,
    payload_fields => [qw{
        message_received_id
        checksum_received1
        checksum_received2
    }],
    payload_fields_length => {
        message_received_id => 1,
        checksum_received1  => 1,
        checksum_received2  => 1,
    },
};


has 'message_received_id' => (
    is  => 'rw',
    isa => 'Int',
);
has 'checksum_received1' => (
    is  => 'rw',
    isa => 'Int',
);
has 'checksum_received2' => (
    is  => 'rw',
    isa => 'Int',
);

with 'UAV::Pilot::WumpusRover::Packet';


sub make_ack_packet_queue_key
{
    my ($self) = @_;
    my $key = join( $self->_PACKET_QUEUE_MAP_KEY_SEPERATOR,
        $self->message_received_id,
        $self->checksum_received1,
        $self->checksum_received2,
    );
    return $key;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

