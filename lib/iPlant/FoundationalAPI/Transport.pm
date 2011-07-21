package iPlant::FoundationalAPI::Transport;

use Carp;
use File::HomeDir ();
use Data::Dumper;

#require Exporter;

our $VERSION = '0.10';
use vars qw($VERSION);

use iPlant::FoundationalAPI::Constants ':all';
    
use LWP;
# Emit verbose HTTP traffic logs to STDERR. Uncomment
# to see detailed (and I mean detailed) HTTP traffic
#use LWP::Debug qw/+/;
use HTTP::Request::Common qw(POST);
# Needed to emit the curl-compatible form when DEBUG is enabled
use URI::Escape;
# For handling the JSON that comes back from iPlant services
use JSON::XS;
# A special option handler that can be dynamically configured
# It relies on GetOpt::Long, but I configure that dependency
# to pass through non-recognized options.
use Getopt::Long::Descriptive;
use Getopt::Long qw(:config pass_through);
# Used for exporting complex data structures to text. Mainly used here 
# for debugging. May be removed as a dependency later
use YAML qw(Dump);
use MIME::Base64 qw(encode_base64);

use constant kMaximumSleepSeconds => 600; # 10 min

# these should be moved to a config file (or not?)

# Never subject to configuration
my $ZONE = 'iPlant Job Service';
my $AGENT = "iPlantRobot/0.1 ";

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
	print STDERR  $END_POINT, $/;
	unless ($END_POINT) {
		print STDERR  "Invalid request. ", $/;
		return kExitError;
	}
	#print $END_POINT, $/;
	
	# Check for a request path
	unless (defined($path)) {
		print STDERR "Please specify a RESTful path using for ", $END_POINT, $/;
		return kExitError;
	}
	print STDERR  "Path: ", $path, $/;

	my $ua = _setup_user_agent($self);
	my $req = HTTP::Request->new(GET => "$TRANSPORT://" . $self->hostname . "/" . $END_POINT . $path);
	my $res = $ua->request($req);
	
	print "\n$TRANSPORT://" . $self->hostname . "/" . $END_POINT . $path, "\n" if $self->debug;
	
	# Parse response
	my $message;
	my $mref;
	
	#print STDERR Dumper( $res ), $/;
	if ($res->is_success) {
		$message = $res->content;
		print STDERR $message, "\n" if $self->debug;

		my $json = JSON::XS->new->allow_nonref;
		$mref = $json->decode( $message );
		# mref in this case is an array reference
		#_display_io_list_reference($mref->{'result'});
		#return kExitOK;
		return $mref->{result};
	}
	else {
		print STDERR $res->status_line, "\n";
		return kExitError;
	}
}

sub do_put {

	my ($self, $path, %params) = @_;

	my $END_POINT = $self->_get_end_point;
	unless ($END_POINT) {
		print STDERR  "Invalid request. ", $/;
		return kExitError;
	}
	#print $END_POINT, $/;
	
	# Check for a request path
	unless (defined($path)) {
		print STDERR "Please specify a RESTful path using for ", $END_POINT, $/;
		return kExitError;
	}
	#print STDERR  "Path: ", $path, $/;

	print STDERR '::do_put: ', Dumper( \%params), $/ if $self->debug;
	my $content = '';
	while (my ($k, $v) = each %params) {
		$content .= "$k=$v&";
	}

	my $ua = _setup_user_agent($self);
	#print STDERR Dumper( $ua), $/;
	print "\n$TRANSPORT://" . $self->hostname . "/" . $END_POINT . $path, "\n" if $self->debug;
	my $req = HTTP::Request->new(PUT => "$TRANSPORT://" . $self->hostname . "/" . $END_POINT . $path);
	$req->content($content) if $content;
	my $res = $ua->request($req);
	
	# Parse response
	my $message;
	my $mref;
	
	#print STDERR Dumper( $res ), $/;
	if ($res->is_success) {
		$message = $res->content;
		if ($self->debug) {
			print STDERR $message, "\n";
		}
		my $json = JSON::XS->new->allow_nonref;
		$mref = eval {$json->decode( $message );};
		#return kExitOK;
		return $mref;
	}
	else {
		print STDERR $res->status_line, "\n";
		return kExitError;
	}
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
	print STDERR  "DELETE Path: ", $path, $/;

	my $ua = _setup_user_agent($self);
	my $req = HTTP::Request->new(DELETE => "$TRANSPORT://" . $self->hostname . "/" . $END_POINT . $path);
	my $res = $ua->request($req);
	
	print "\nDELETE => $TRANSPORT://" . $self->hostname . "/" . $END_POINT . $path, "\n" if $self->debug;
	
	# Parse response
	my $message;
	my $mref;
	
	if ($res->is_success) {
		$message = $res->content;
		print STDERR $message, "\n" if $self->debug;

		# TODO - make sure we've got a json string

		my $json = JSON::XS->new->allow_nonref;
		$mref = $json->decode( $message );
		#return kExitOK;
		return $mref;
	}
	else {
		print STDERR $res->status_line, "\n";
		return kExitError;
	}
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

	print STDERR '::do_post: ', Dumper( \%params), $/ if $self->debug;
	my $content = '';
	while (my ($k, $v) = each %params) {
		$content .= "$k=$v&";
	}

	my $ua = $self->_setup_user_agent;
	#print STDERR Dumper( $ua), $/;
	print "\n$TRANSPORT://" . $self->hostname . "/" . $END_POINT . $path, "\n" if $self->debug;
	my $req = HTTP::Request->new(POST => "$TRANSPORT://" . $self->hostname . "/" . $END_POINT . $path);
	$req->content($content) if $content;
	my $res = $ua->request($req);
	
	# Parse response
	my $message;
	my $mref;
	
	#print STDERR Dumper( $res ), $/;
	if ($res->is_success) {
		$message = $res->content;
		if ($self->debug) {
			print STDERR $message, "\n";
		}
		my $json = JSON::XS->new->allow_nonref;
		$mref = eval {$json->decode( $message );};
		#return kExitOK;
		return $mref;
	}
	else {
		print STDERR $res->status_line, "\n";
		return kExitError;
	}
}

# Transport-level Methods
sub _setup_user_agent {
	
	my $self = shift;
	my $ua = LWP::UserAgent->new;
	
	#print STDERR "\nSetting up UA\n";
	
	$ua->agent($AGENT);
	if (($self->user ne '') and ($self->token ne '')) {
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


1;
