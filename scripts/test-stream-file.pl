#!/usr/bin/perl
use common::sense;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use iPlant::FoundationalAPI::Constants ':all';
use iPlant::FoundationalAPI ();

my $remote_file = shift;

unless (defined $remote_file) {
    die "Usage: $0 <remote_file>\n";
}

# this will read the configs from the ~/.iplant.foundationalapi.json file:
#	conf file content: 
#		{"user":"iplant_username", "password":"iplant_password", "token":"iplant_token"}
my $api_instance = iPlant::FoundationalAPI->new(hostname => 'iplant-dev.tacc.utexas.edu');
$api_instance->debug(0);

if ($api_instance->token eq kExitError) {
	print STDERR "Can't authenticate!" , $/;
	exit 1;
}
#print STDERR "Token: ", $api_instance->token, "\n";

my $base_dir = '/' . $api_instance->user;
print STDERR "Working in [", $base_dir, "]", $/;

my ($st, $dir_contents_href);

my $io = $api_instance->io;

$io->stream_file("$base_dir/$remote_file", stream_to_stdout => 1, limit_size => 500);

