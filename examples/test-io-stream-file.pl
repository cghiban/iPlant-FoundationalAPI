#!/usr/bin/perl
use common::sense;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use iPlant::FoundationalAPI ();

use Scalar::Util qw( blessed );
use Try::Tiny;
use Data::Dumper;

my $remote_file = shift;

unless (defined $remote_file) {
    die "Usage: $0 <remote_file>\n";
}

# this will read the configs from the ~/.iplant.foundationalapi.v2.json file:
#	conf file content: 
#		{"user":"iplant_username", "password":"iplant_password", "ckey":"", "csecret":"", "token":""}
#		# set either the password or the token

my $api_instance = iPlant::FoundationalAPI->new(debug => 0);

unless ($api_instance->token) {
	print STDERR "Can't authenticate!" , $/;
	exit 1;
}

my ($st, $dir_contents_href);

my $io = $api_instance->io;

# in case of an error, we can get it in catch() or in $st;
my $st = try {
        $io->stream_file($remote_file, stream_to_stdout => 1);
    }
    catch {
        #print STDERR Dumper( $_), $/;
        if (ref($_) && $_->isa('Agave::Exceptions::HTTPError')) {
            warn "Error: ", $_->code . "\n" . $_->content, "\n";
        }
        else {
            warn $_;
        }
    };

warn '$st = ', Dumper( $st ), $/ if 'HASH' eq ref($st);
