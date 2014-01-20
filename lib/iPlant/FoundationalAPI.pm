package iPlant::FoundationalAPI;

use warnings;
use strict;

=head1 NAME

iPlant::FoundationalAPI - The great new iPlant::FoundationalAPI!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use base 'iPlant::FoundationalAPI::Base';

use iPlant::FoundationalAPI::IO ();
#use iPlant::FoundationalAPI::Data ();
use iPlant::FoundationalAPI::Apps ();
use iPlant::FoundationalAPI::Auth ();
use iPlant::FoundationalAPI::Job ();

# Needed to emit the curl-compatible form when DEBUG is enabled
use URI::Escape;
# For handling the JSON that comes back from iPlant services
use JSON::XS ();

use Data::Dumper;

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use iPlant::FoundationalAPI;

    my $api = iPlant::FoundationalAPI->new();
    ...

=head1 FUNCTIONS

=cut

my @config_files = qw(
   ./iplant.foundationalapi.v2.json
   ~/.iplant.foundationalapi.v2.json 
   ~/Library/Preferences/iplant.foundationalapi.v2.json
   /etc/iplant.foundationalapi.v2.json
);

=head2 new

=cut

sub new {

	my $proto = shift;
	my %args = @_;
	my $class = ref($proto) || $proto;
	
	my $self  = {
            hostname => delete $args{hostname} || 'agave.iplantc.org',
            iplanthome => '/iplant/home/',
            processors => 1,
            run_time => '01:00:00',
            csecret => $args{csecret} || '',
            ckey => $args{ckey} || '',
            user => $args{user} || '',
            password => $args{password} || '',
            token => $args{token} || '',
            credential_class => $args{credential_class} || 'self',
            lifetime => defined $args{lifetime} ? delete $args{lifetime} : undef,
            http_timeout => defined $args{http_timeout} ? delete $args{http_timeout} : undef,
            auth => undef,
            debug => defined $args{debug} ? delete $args{debug} : undef,
        };
	
    my $config_file = defined $args{config_file} ? delete $args{config_file} : undef;
    $self = _auto_config($self, $config_file) unless %args;
	
	if ($self->{user} && ($self->{token} || $self->{password})) {
		_init_auth($self);
	}

    delete $self->{password};
	
	bless($self, $class);
	return $self;
}


sub _auto_config {
	
	# Try loading config from various paths
	# to populate user, password, token, host, processors, runtime, and so on

	my ($self, $config_file) = @_;
	
	my $json = JSON::XS->new->allow_nonref;	
	my $home_dir = File::HomeDir->home;

    my (@cfiles) = defined $config_file && -f $config_file 
                    ? ($config_file) 
                    : @config_files;

	foreach my $c (@cfiles) {
		if ($c =~ /^~/) {
			$c =~ s/^~/$home_dir/;
		}
		
		if (-e $c) {
			open(CONFIG, $c);
			my $contents = do { local $/;  <CONFIG> };
			if (defined($contents)) {
				my $mref = $json->decode( $contents );
				
				foreach my $option (keys %{ $mref }) {
					$self->{$option} = $mref->{$option};
				}
			}
			close CONFIG;
            last;
		}
	}
	
	return $self;

}


sub _init_auth {
	my ($self) = @_;
	
	my $auth = iPlant::FoundationalAPI::Auth->new($self);
	if ($auth && $auth->token) {
		$self->{token} = $auth->token;
		$auth->debug($self->{debug});
	}
    else {
        delete $self->{token};
    }
	$self->{auth} = $auth;
}

sub auth {
	my ($self) = @_;
	return $self->{auth};
}

sub io {
	my $self = shift;
	return iPlant::FoundationalAPI::IO->new($self);
}

sub data {
	my $self = shift;
	return iPlant::FoundationalAPI::Data->new($self);
}

sub apps {
	my $self = shift;
	return iPlant::FoundationalAPI::Apps->new($self);
}

sub job {
	my $self = shift;
	return iPlant::FoundationalAPI::Job->new($self);
}

sub token_expiration {
	my $self = shift;
	if ($self->{auth}) {
		return $self->{auth}->token_expiration;
	}
	return 0;
}

sub debug {
	my ($self, $d) = @_;
	if (defined $d) {
		$self->{auth} && $self->{auth}->debug($d);
	}
	$self->SUPER::debug($d);
}

=head1 AUTHOR

Cornel Ghiban, C<< <ghiban at cshl.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-iplant-foundationalapi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=iPlant-FoundationalAPI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc iPlant::FoundationalAPI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=iPlant-FoundationalAPI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/iPlant-FoundationalAPI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/iPlant-FoundationalAPI>

=item * Search CPAN

L<http://search.cpan.org/dist/iPlant-FoundationalAPI/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2011 Cornel Ghiban.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of iPlant::FoundationalAPI
