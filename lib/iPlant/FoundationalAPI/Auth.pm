package iPlant::FoundationalAPI::Auth;

use warnings;
use strict;

use base 'iPlant::FoundationalAPI::Base';
use MIME::Base64;
use Data::Dumper;

=head1 NAME

iPlant::FoundationalAPI::Auth - The great new iPlant::FoundationalAPI::Auth!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

my $TRANSPORT = 'https';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use iPlant::FoundationalAPI::Auth;

    my $foo = iPlant::FoundationalAPI::Auth->new();
    ...

=head1 FUNCTIONS

=head2 new

=cut

sub new {
	my ($proto, $args) = @_;
	my $class = ref($proto) || $proto;
	
	my $self  = { map {$_ => $args->{$_}} grep {/(?:user|token|password|hostname|debug)/} keys %$args};
	
	
	bless($self, $class);
	
	if ($self->{user} && $self->{password} && !$self->{token}) {
		# hit auth service for a new token
		my $newToken = $self->auth_post_token();
		print "Issued-Token: ", $newToken, "\n" if $self->debug;
		$self->{token} = $newToken;
		delete $self->{password};
	}
	
	return $self;
}

=head2 function2

=cut

sub _configure_auth_from_opt {
	
	# Allows user to specify username/password (unencrypted)
	# Uses this info to hit the auth-v1 endpoint
	# fetch a token and cache it as the global token
	# for this instance of the application
	
	my ($self, $opt1) = @_;
	
	if ($opt1->user and $opt1->password and not $opt1->token) {
	
		if ($self->debug) {
			print STDERR (caller(0))[3], ": Username/password authentication selected\n";
		}
		# set global.user global.password
		$self->user( $opt1->{'user'} );
		$self->password( $opt1->{'password'} );
				
		# hit auth service for a new token
		my $newToken = $self->auth_post_token();
		print "Issued-Token: ", $newToken, "\n";
		
		$self->password(undef);
		# set global.token
		$self->token( $newToken );
	
	} elsif ($opt1->user and $opt1->token and not $opt1->password) {
		
		if ($self->debug) {
			print STDERR (caller(0))[3], ": Secure token authentication selected\n";
		}
		
		$self->user( $opt1->user );	
		$self->token( $opt1->token );
	
	} else {
		if ($self->debug) {
			print STDERR (caller(0))[3], ": Defaulting to pre-configured values\n";		
		}
	}
	
	return 1;
}

sub validate_auth {
	my ($self) = @_;
	
	return 0;
}


sub auth_post_token {
	
	# Retrieve a token in user mode
	my $self = shift;

	my $ua = $self->_setup_user_agent;
	$ua->default_header( Authorization => 'Basic ' . _encode_credentials($self->user, $self->password) );
	
	my $auth_ep = $self->_get_end_point;
	my $url = "https://" . $self->hostname . "/$auth_ep/";

	my $req = HTTP::Request->new(POST => $url);
	my $res = $ua->request($req);
	
	my $message;
	my $mref;
	my $json = JSON::XS->new->allow_nonref;
				
	if ($res->is_success) {
		$message = $res->content;
		#print $message, $/;
		$mref = $json->decode( $message );
		if (defined($mref->{'result'}->{'token'})) {
			$self->{token_expires} = $mref->{'result'}->{expires};
			return $mref->{'result'}->{'token'};
		}
	} else {
		print STDERR (caller(0))[3], " ", $res->status_line, "\n";
		return undef;
	}

}


sub token_expiration {
	my ($self) = shift;
	return $self->{token_expires};
}


sub _encode_credentials {
	
	# u is always an iPlant username
	# p can be either a password or RSA encrypted token
	
	my ($u, $p) = @_;
	encode_base64("$u:$p");
}


=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Cornel Ghiban, C<< <ghiban at cshl.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-iplant-foundationalapi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=iPlant-FoundationalAPI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc iPlant::FoundationalAPI::Auth


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

1; # End of iPlant::FoundationalAPI::Auth
