#!/usr/bin/perl

use common::sense;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use iPlant::FoundationalAPI ();
use File::Basename;
use Data::Dumper; 

my $remote_file = shift;

unless (defined $remote_file) {
    die "Usage: $0 <remote_file>\n";
}

# this will read the configs from the ~/.iplant.foundationalapi.v2.json file:
#	conf file content: 
#		{"user":"iplant_username", "password":"iplant_password", "ckey":"", "csecret":"", "token":""}

my $api_instance = iPlant::FoundationalAPI->new(debug => 0);

unless ($api_instance->token) {
	print STDERR "Can't authenticate!" , $/;
	exit 1;
}
print "Token: ", $api_instance->token, "\n" if $api_instance->debug;

my ($st, $dir_contents_href);

my $io = $api_instance->io;

my $finfo = eval {$io->ls($remote_file);};
if ($@) {
    warn "Error: ", $@, ": $remote_file\n";
    exit(1);
}

if (!$finfo || 1 != @$finfo || !$finfo->[0]->is_file ) {
    print STDERR "Not a regular file: ", Dumper($finfo->[0]), $/;
    exit(1);
}

my $local_file = "/tmp/" . basename($remote_file);
if (-f $local_file) {
    unlink $local_file or do {die "Can't remove existing file: " . $local_file;}
}
$io->stream_file($remote_file, save_to => $local_file);

if (-f $local_file) {
    print "Stored remote file to ", $local_file, ", size = ", -s $local_file, " bytes", $/;
}
else {
   print "For some reason the downloaded file is missing...\n" 
}
