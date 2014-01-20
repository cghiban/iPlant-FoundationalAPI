package iPlant::FoundationalAPI::Transport;

use strict;
use warnings;

use File::HomeDir ();
use Try::Tiny;

use iPlant::FoundationalAPI::Exceptions ();

use LWP;
# Emit verbose HTTP traffic logs to STDERR. Uncomment
# to see detailed (and I mean detailed) HTTP traffic
#use LWP::Debug qw/+/;
use HTTP::Request::Common qw(POST);
# Needed to emit the curl-compatible form when DEBUG is enabled
#use URI::Escape;
use JSON ();
use MIME::Base64 qw(encode_base64);
use Data::Dumper;

our $VERSION = '0.2.1';
use vars qw($VERSION);

{
    # these should be moved to a config file (or not?)

    my $TIMEOUT = 60;

    # Never subject to configuration
    my $ZONE = 'iPlant Job Service';
    my $AGENT = "DNALCRobot/$VERSION";

    # Define API endpoints
    my $IO_ROOT = "files/2.0";
    my $IO_END = "$IO_ROOT";

    #my $AUTH_ROOT = "v2/auth";
    my $AUTH_END = "token";

    my $DATA_ROOT = "data-v1";
    my $DATA_END = "$DATA_ROOT/data";

    my $APPS_END = "apps/2.0";
    my $JOBS_END = "jobs/2.0";

    my $TRANSPORT = 'https';

    my %end_point = (
            auth => $AUTH_END,
            io => $IO_END,
            data => $DATA_END,
            apps => $APPS_END,
            #jobs => $JOBS_END,
            job  => $JOBS_END,
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
        unless ($END_POINT) {
            Agave::Exceptions::InvalidEndPoint->throw("do_get: invalid endpoint.");
        }
        print STDERR  $END_POINT, $/ if $self->debug;

        # Check for a request path
        unless (defined($path)) {
            Agave::Exceptions::InvalidArguments->throw(
                    "Please specify a RESTful path for $END_POINT"
                );
        }
        print STDERR  "::do_get: path: ", $path, $/ if $self->debug;

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

            if ($res->is_success) {
                return $data;
            }
            else {
                print STDERR $res->status_line, "\n" if $self->debug;
                Agave::Exceptions::HTTPError->throw(
                        code => $res->code,
                        message => $res->message,
                        content => $res->content,
                    );
            }
        }
        else {
            $req = HTTP::Request->new(GET => "$TRANSPORT://" . $self->hostname . "/" . $END_POINT . $path);
            $res = $ua->request($req);
        }
        
        print STDERR "\n$TRANSPORT://" . $self->hostname . "/" . $END_POINT . $path, "\n" if $self->debug;
        
        # Parse response
        my $message = $res->content;
        # success or we have a json resp
        my $headers = $res->headers;
        my $is_json = $headers->{'content-type'} =~ m'^application/json';
        if ($res->is_success || $is_json) {
            my $mref;
            print STDERR $message, "\n" if $self->debug;

            my $json = JSON->new->allow_nonref;
            try {
                 $mref = $json->decode( $message );
            }
            catch {
                Agave::Exceptions::HTTPError->throw(
                    code => $res->code,
                    message => 'Invalid response. Expecting JSON.',
                    content => $res->content,
                );
            };

            # check for API errors
            my $fault = $mref->{fault};
            if ($mref && $fault) {
                Agave::Exceptions::HTTPError->throw(
                    code => $fault->{code},
                    message => ($fault->{type} . ' ' . $fault->{message}) || 'do_get: error',
                    content => $message,
                );              
            }

            if ($mref && $mref->{status} eq 'success') {
                return $mref->{result};
            }
            else {
                Agave::Exceptions::HTTPError->throw(
                    code => $res->code,
                    message => $mref->{message} || 'do_get: error',
                    content => $res->content,
                );
            }
        }
        else {
            print STDERR $res->status_line, "\n" if $self->debug;
            print STDERR $req->content, "\n" if $self->debug;
            Agave::Exceptions::HTTPError->throw(
                code => $res->code,
                message => 'Invalid response. Expecting JSON.',
                content => $res->content,
            );
        }
    }

    sub do_put {

        my ($self, $path, %params) = @_;

        my $END_POINT = $self->_get_end_point;
        unless ($END_POINT) {
            Agave::Exceptions::InvalidEndPoint->throw("do_get: Invalid endpoint.");
        }
        
        # Check for a request path
        unless (defined($path)) {
            Agave::Exceptions::InvalidArguments->throw(
                    "Please specify a RESTful path for $END_POINT"
                );
        }

        print STDERR '::do_put: ', Dumper( \%params), $/ if $self->debug;
        my $content = '';
        while (my ($k, $v) = each %params) {
            $content .= "$k=$v&";
        }

        my $ua = _setup_user_agent($self);
        #print STDERR Dumper( $ua), $/;
        print STDERR "\n$TRANSPORT://" . $self->hostname . "/" . $END_POINT . $path, "\n" if $self->debug;
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
            my $json = JSON->new->allow_nonref;
            $mref = eval {$json->decode( $message );};
            return $mref;
        }
        else {
	    	print STDERR (caller(0))[3], " ", $res->status_line, "\n";
            Agave::Exceptions::HTTPError->throw(
                code => $res->code,
                message => $res->message,
                content => $res->content,
            );
        }
    }

    sub do_delete {

        my ($self, $path) = @_;

        my $END_POINT = $self->_get_end_point;
        unless ($END_POINT) {
            Agave::Exceptions::InvalidEndPoint->throw("do_get: Invalid endpoint.");
        }
        
        # Check for a request path
        unless (defined($path)) {
            Agave::Exceptions::InvalidArguments->throw(
                    "Please specify a RESTful path for $END_POINT"
                );
        }
        print STDERR  "DELETE Path: ", $path, $/ if $self->debug;

        my $ua = _setup_user_agent($self);
        my $req = HTTP::Request->new(DELETE => "$TRANSPORT://" . $self->hostname . "/" . $END_POINT . $path);
        my $res = $ua->request($req);
        
        print STDERR "\nDELETE => $TRANSPORT://" . $self->hostname . "/" . $END_POINT . $path, "\n" if $self->debug;
        
        # Parse response
        my $message;
        my $mref;
        
        if ($res->is_success) {
            $message = $res->content;
            print STDERR $message, "\n" if $self->debug;

            my $json = JSON->new->allow_nonref;
            $mref = eval { $json->decode( $message ); };
            if ($mref && $mref->{status} eq 'success') {
                return 1;
            }
            return $mref;
        }
        else {
            print STDERR (caller(0))[3], " ", $res->status_line, "\n";
            Agave::Exceptions::HTTPError->throw(
                code => $res->code,
                message => $res->message,
                content => $res->content,
            );
        }
    }

    sub do_post {

        my ($self, $path, %params) = @_;

        my $END_POINT = $self->_get_end_point;

        unless ($END_POINT) {
            Agave::Exceptions::InvalidRequest->throw("Invalid endpoint $END_POINT.");
        }
        
        # Check for a request path
        unless (defined($path)) {
            Agave::Exceptions::InvalidRequest->throw(
                    "Please specify a RESTful path for $END_POINT"
                );
        }

        $path =~ s'/$'';

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
        
        my $json = JSON->new->allow_nonref;
        if ($res->is_success) {
            $message = $res->content;
            if ($self->debug) {
                print STDERR '::do_post content: ', $message, "\n";
            }
            $mref = eval {$json->decode( $message );};
            if ($mref && $mref->{status} eq 'success') {
                return $mref->{result};
            }
            return $mref;
        }
        else {
            #print STDERR Dumper( $res ), $/;
            print STDERR "Status line: ", (caller(0))[3], " ", $res->status_line, "\n";
            my $content = $res->content;
            print STDERR "Content: ", $content, $/;
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
        $ua->timeout( $self->{http_timeout} || $TIMEOUT);
        if (($self->user ne '') && $self->token) {
            if ($self->debug) {
                print STDERR (caller(0))[3], ": Username/token authentication selected\n";
            }
            $ua->default_header( Authorization => 'Bearer ' . $self->token );
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
}

1;
