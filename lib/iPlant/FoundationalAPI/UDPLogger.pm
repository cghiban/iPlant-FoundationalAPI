package iPlant::FoundationalAPI::UDPLogger;

use strict;

use IO::Socket::INET ();
use Storable qw(nfreeze);

sub new {
    my $class = shift;

    my %args = @_;

    my $udp = IO::Socket::INET->new(
                PeerHost => delete $args{host} || 'localhost',
                PeerPort => delete $args{port} || '9999',
                Proto => 'udp',
            );

    $args{socket} = $udp;

    my $self = bless \%args, $class;
}

sub log {
    my $self = shift;
    my $msg = shift;

    my $data;
    if ('HASH' eq ref $msg) {
        for (grep {!/(?:socket|host|port)/} keys %$self) {
            $msg->{$_} = $self->{$_};
        }
    }
    $data = nfreeze \($msg);

    if ($self && $self->{socket}) {
        $self->{socket}->send($data);
    }
}

sub session {
    my ($self, $session) = @_;
    if ($session) {
        $self->{_session} = $session;
    }
    return $self->{_session};
}


sub DESTROY {
    my $self = shift;
    if ($self && ref $self && $self->{socket}) {
        $self->{socket}->close;
    }
}

1;

__END__
package main;
use Data::Dumper; 
use strict;
use warnings;

my $logger = iPlant::FoundationalAPI::UDPLogger->new(pid => 132);
print STDERR Dumper( $logger ), $/;
$logger->log({a => 22});

1;
