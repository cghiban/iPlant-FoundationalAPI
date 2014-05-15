package iPlant::FoundationalAPI::Transport;

use strict;
use warnings;

use Carp;
use File::HomeDir ();
#use File::Basename qw/dirname/;
use Data::Dumper;


our $VERSION = '0.12';
use vars qw($VERSION);

use iPlant::FoundationalAPI::Constants ':all';
use LWP;
# Emit verbose HTTP traffic logs to STDERR. Uncomment
# to see detailed (and I mean detailed) HTTP traffic
#use LWP::Debug qw/+/;
#use HTTP::Request::Common qw(POST);

# For handling the JSON that comes back from iPlant services
use JSON::XS;
use MIME::Base64 qw(encode_base64);

use constant kMaximumSleepSeconds => 600; # 10 min

# these should be moved to a config file (or not?)

# Never subject to configuration
my $ZONE = 'iPlant Job Service';
my $AGENT = "iPlantRobot/0.2 ";

# Define API endpoints
my $IO_ROOT = "io-v1";
my $IO_END = "$IO_ROOT/io";

my $AUTH_ROOT = "auth-v1";
my $AUTH_END = $AUTH_ROOT;

my $DATA_ROOT = "data-v1";
my $DATA_END = "$DATA_ROOT/data";

my $APPS_ROOT = "apps-v1";
my $APPS_END = "$APPS_ROOT/apps";
my $APPS_SHARE_END = "$APPS_ROOT/apps/share/name";

my $JOB_END = "$APPS_ROOT/job";
my $JOBS_END = "$APPS_ROOT/jobs";

my $TRANSPORT = 'https';

my %end_point = (
		auth => $AUTH_END,
		io => $IO_END,
		data => $DATA_END,
		apps => $APPS_END,
		job => $JOB_END,
	);



sub _get_end_point {
	my $self = shift;

	my $ref_name = ref $self;
	return unless $ref_name;
	$ref_name =~ s/^.*:://;

	return $end_point{lc $ref_name};
}

sub do_get {

	my ($self, $path, %params) = @_;

	my $END_POINT = $self->_get_end_point;
	print STDERR  $END_POINT, $/ if $self->debug;
	unless ($END_POINT) {
		print STDERR "::do_get: invalid request: ", $self, $/;
		return kExitError;
	}
	
	# Check for a request path
	unless (defined($path)) {
		carp "RESTful path missing for " . $END_POINT;
		return kExitError;
	}
	print STDERR  "::do_get: path: ", $path, $/ if $self->debug;
	$self->log( type => 'request', method => 'GET', path => $path);

	my $ua = _setup_user_agent($self);
	my ($req, $res);

	if (defined $params{limit_size} || defined $params{save_to} || defined $params{stream_to_stdout}) {

		my $data;

		if ($params{save_to}) {
			my $filepath = $params{save_to};
			# should we at least check if parent directory exists?

			$res = $ua->get("$TRANSPORT://" . $self->hostname . "/" . $END_POINT . $path,
						':content_file' => $filepath,
					);
			$data = 1;
		}
		elsif ($params{stream_to_stdout}) {
			$res = $ua->get("$TRANSPORT://" . $self->hostname . "/" . $END_POINT . $path,
						#':read_size_hint' => $params{limit_size} > 0 ? $params{limit_size} : undef,
						':content_cb' => sub {my ($d)= @_; print STDOUT $d;},
					);
			$data = 1;
		}

		else {
			$res = $ua->get("$TRANSPORT://" . $self->hostname . "/" . $END_POINT . $path,
						':read_size_hint' => $params{limit_size} > 0 ? $params{limit_size} : undef,
						':content_cb' => sub {my ($d)= @_; $data = $d; die();},
					);
		}

		$self->log( type => 'response', method => 'GET', 
			path => $path, code => $res->code,);

		if ($res->is_success) {
			return $data;
		}
		else {
			print STDERR $res->status_line, "\n" if $self->debug;
			croak $res->status_line;
		}
	}
	else {
		$req = HTTP::Request->new(GET => "$TRANSPORT://" . $self->hostname . "/" . $END_POINT . $path);
		$res = $ua->request($req);
	}
	
	print STDERR "\n$TRANSPORT://" . $self->hostname . "/" . $END_POINT . $path, "\n" if $self->debug;
	
	# Parse response
	my $message;
	my $mref;

	# success or we have a json resp
	my $headers = $res->headers;
	my $is_json = $headers->{'content-type'} =~ m'^application/json';
	if ($res->is_success || $is_json) {
		$message = $res->content;
		print STDERR $message, "\n" if $self->debug;

		$self->log( type => 'response', method => 'GET', path => $path, 
			code => $res->code, content => $message);

		my $json = JSON::XS->new->allow_nonref;
		$mref = eval {$json->decode( $message );};
		if ($@) {
			print STDERR $message, "\n";
			croak "Invalid message received!\n";
		}
		if (ref $mref) {
			if ($mref->{status} eq 'success') {
				return $mref->{result};
			}
			else {
				croak $mref->{message};
			}
		}
		else {
			croak "Invalid message received!\n";
		}
	}
	else {
		$self->log( type => 'response', method => 'GET', path => $path, 
			code => $res->code, content => $res->content);
		print STDERR $res->status_line, "\n" if $self->debug;
		print STDERR $req->content, "\n" if $self->debug;
		croak $res->status_line;
	}
}

sub do_put {

	my ($self, $path, %params) = @_;

	my $END_POINT = $self->_get_end_point;
	unless ($END_POINT) {
		print STDERR  "Invalid request. ", $/;
		return kExitError;
	}
	
	# Check for a request path
	unless (defined($path)) {
		print STDERR "Please specify a RESTful path using for ", $END_POINT, $/;
		return kExitError;
	}
	print STDERR  "Path: ", $path, $/ if $self->debug;

	print STDERR '::do_put: ', Dumper( \%params), $/ if $self->debug;
	my $content = '';
	while (my ($k, $v) = each %params) {
		$content .= "$k=$v&";
	}

	my $log_path = $path . '?' . $content;
	$self->log( type => 'request', method => 'PUT', path => $log_path);

	my $ua = _setup_user_agent($self);
	print STDERR "\n$TRANSPORT://" . $self->hostname . "/" . $END_POINT . $path, "\n" if $self->debug;
	my $req = HTTP::Request->new(PUT => "$TRANSPORT://" . $self->hostname . "/" . $END_POINT . $path);
	$req->content($content) if $content;
	my $res = $ua->request($req);
	
	# Parse response
	my $message;
	my $rc;
	
	if ($res->is_success) {
		$message = $res->content;
		print STDERR $message, "\n" if $self->debug;
		my $json = JSON::XS->new->allow_nonref;
		$rc = eval {$json->decode( $message );};
	}
	else {
		print STDERR 'PUT response: ', $res->status_line, "\n" if $self->debug;
		$rc = kExitError;
	}

	$self->log( type => 'response', method => 'PUT', path => $log_path, 
		code => $res->code, content => $res->content);

	return $rc;
}

sub do_delete {

	my ($self, $path) = @_;

	my $END_POINT = $self->_get_end_point;
	unless ($END_POINT) {
		print STDERR  "Invalid request. ", $/;
		return kExitError;
	}
	
	# Check for a request path
	unless (defined($path)) {
		print STDERR "Please specify a RESTful path using for ", $END_POINT, $/;
		return kExitError;
	}
	print STDERR  "DELETE Path: ", $path, $/ if $self->debug;

	my $user = $self->user;
	if ($user =~ m|$path/*$|) {
		print STDERR  "Can't remove user's directory. Given path = $path", $/;
		return kExitError
	}

	$self->log( type => 'request', method => 'DELETE', path => $path);

	my $ua = _setup_user_agent($self);
	my $req = HTTP::Request->new(DELETE => "$TRANSPORT://" . $self->hostname . "/" . $END_POINT . $path);
	my $res = $ua->request($req);
	
	print STDERR "\nDELETE => $TRANSPORT://" . $self->hostname . "/" . $END_POINT . $path, "\n" if $self->debug;
	
	# Parse response
	my $message;
	my $rc;
	
	if ($res->is_success) {
		$message = $res->content;
		print STDERR $message, "\n" if $self->debug;

		my $json = JSON::XS->new->allow_nonref;
		my $mref = eval { $json->decode( $message ); };
		if ($mref && $mref->{status} eq 'success') {
			$rc = 1;
		}
		else {
			$rc = $mref;
		}
	}
	else {
		print STDERR $res->status_line, "\n";
		print STDERR $res->content, "\n";
		$rc = kExitError;
	}
	
	$self->log( type => 'response', method => 'DELETE', path => $path, 
		code => $res->code, content => $res->content);
	return $rc;
}


sub do_post {

	my ($self, $path, %params) = @_;

	my $END_POINT = $self->_get_end_point;
	unless ($END_POINT) {
		print STDERR  "Invalid request. ", $/;
		return kExitError;
	}
	
	# Check for a request path
	unless (defined($path)) {
		print STDERR "Please specify a RESTful path using for ", $END_POINT, $/;
		return kExitError;
	}

	$path =~ s'/$'';

	$self->log( type => 'request', method => 'POST', path => $path, params => \%params);

	print STDERR '::do_post: ', Dumper( \%params), $/ if $self->debug;
	print STDERR "\n$TRANSPORT://" . $self->hostname . "/" . $END_POINT . $path, "\n" 
		if $self->debug;

	my $ua = $self->_setup_user_agent;
	my $res = $ua->post(
				"$TRANSPORT://" . $self->hostname . "/" . $END_POINT . $path,
				\%params
			);
	
	# Parse response
	my $message;
	my $mref;
	
	my $json = JSON::XS->new->allow_nonref;
	if ($res->is_success) {
		$message = $res->content;
		if ($self->debug) {
			print STDERR '::do_post content: ', $message, "\n";
		}

		$self->log( type => 'response', method => 'POST', path => $path, 
			code => $res->code, content => $message);

		$mref = eval {$json->decode( $message );};
		if ($mref && $mref->{status} eq 'success') {
			return $mref->{result};
		}
		return $mref;
	}
	else {
		print STDERR "Status line: ", (caller(0))[3], " ", $res->status_line, "\n" if $self->debug;
		my $content = $res->content;

		$self->log( type => 'response', method => 'POST', path => $path, 
			code => $res->code, content => $content);

		print STDERR "Content: ", $content, $/ if $self->debug;
		if ($content =~ /"status":/) {
			$mref = eval {$json->decode( $content );};
			if ($mref && $mref->{status}) {
				return {status => "error", message => $mref->{message} || $res->status_line};
			}
		}
		return {status => "error", message => $res->status_line};
	}
}

# Transport-level Methods
sub _setup_user_agent {
	
	my $self = shift;
	my $ua = LWP::UserAgent->new;
	
	$ua->agent($AGENT);
	if (defined $self->user && $self->user ne '' && defined $self->token && $self->token ne '') {
		if ($self->debug) {
			print STDERR (caller(0))[3], ": Username/token authentication selected\n";
		}
		$ua->default_header( Authorization => 'Basic ' . _encode_credentials($self->user, $self->token) );
	} else {
		if ($self->debug) {
			print STDERR (caller(0))[3], ": Sending no authentication information\n";
		}
	}
	
	return $ua;

}

sub _encode_credentials {
	
	# u is always an iPlant username
	# p can be either a password or RSA encrypted token
	
	my ($u, $p) = @_;
	encode_base64("$u:$p");
}

sub debug {
	my $self = shift;
	if (@_) { $self->{debug} = shift }
	return $self->{debug};
}

sub logger {
	my $self = shift;
	if (@_) { $self->{logger} = shift }
	return $self->{logger};
}

sub log {
	my $self = shift;
	my %args = @_;

	return unless $self->{logger};
	return unless keys %args;

	my %params = (
		user => $self->{user} || 'no_user',
		end_point => $self->_get_end_point || 'no_ep',
	);
	$params{$_} = $args{$_} for (keys %args);
	if (exists $params{content} && defined $params{content}) {
		$params{content} = substr($params{content}, 0, 8_000);
	}

	#print STDERR Dumper( \%params ), $/;

	# we don't care about if this suceeds, for now..
	eval {
		$self->{logger}->can('log') 
			? $self->{logger}->log(\%params)
			: $self->{logger}->send(\%params);
	};
}


1;
