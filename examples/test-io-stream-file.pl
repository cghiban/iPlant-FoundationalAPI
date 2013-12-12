#!/usr/bin/perl
use common::sense;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use iPlant::FoundationalAPI ();

use Scalar::Util qw( blessed );

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
#print STDERR "Token: ", $api_instance->token, "\n";

my $base_dir = '/' . $api_instance->user;
print STDERR "Working in [", $base_dir, "]", $/;

my ($st, $dir_contents_href);

my $io = $api_instance->io;

$io->stream_file("$base_dir/$remote_file", stream_to_stdout => 1, limit_size => 500);


