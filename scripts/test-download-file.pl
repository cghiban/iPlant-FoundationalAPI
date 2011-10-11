#!/usr/bin/perl

use common::sense;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use iPlant::FoundationalAPI::Constants ':all';
use iPlant::FoundationalAPI ();
use Data::Dumper; 

sub list_dir {
	my ($dir_contents) = @_;
	for (@$dir_contents) {
		print $_->name, "\t", $_,  $/;
	}
	print "\n";
}

# this will read the configs from the ~/.iplant.foundationalapi.json file:
#	conf file content: 
#		{"user":"iplant_username", "password":"iplant_password", "token":"iplant_token"}
my $api_instance = iPlant::FoundationalAPI->new;
$api_instance->debug(1);

if ($api_instance->token eq kExitError) {
	print STDERR "Can't authenticate!" , $/;
	exit 1;
}
print STDERR "Token: ", $api_instance->token, "\n";

my $base_dir = '/' . $api_instance->user;
print STDERR "Working in [", $base_dir, "]", $/;

my ($st, $dir_contents_href);

my $io = $api_instance->io;

#$dir_contents_href = $io->readdir($base_dir);
#print STDERR Dumper( $dir_contents_href), $/;
#list_dir($dir_contents_href);

my $data = $io->stream_file("$base_dir/selected_ESTs_arabidopsis_thaliana.fasta", download => 1);
#my $data = $io->stream_file("$base_dir/A.txt", limit_size => 500);
print STDERR  "DATA:", $/;
print $data;
