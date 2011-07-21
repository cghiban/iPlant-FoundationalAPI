#!/usr/bin/perl

use common::sense;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use iPlant::FoundationalAPI ();
use Data::Dumper; 

sub list_dir {
	my ($dir_contents) = @_;
	for (@$dir_contents) {
		print $_->name, "\t", $_,  $/;
	}
	print "\n";
}

unless (defined $ENV{IPLANT_USERNAME} && (defined $ENV{IPLANT_PASSWORD} || $ENV{IPLANT_TOKEN})) {
	print "Env variables IPLANT_USERNAME and IPLANT_PASSWORD or IPLANT_TOKEN are undefined", $/;
	exit;
}

my $api_instance = iPlant::FoundationalAPI->new(
			user => $ENV{IPLANT_USERNAME},
			token => $ENV{IPLANT_TOKEN},
			debug => 1,
			password => $ENV{IPLANT_PASSWORD},
		);

## or

# this will read the configs from the ~/.iplant.foundationalapi.json file:
#	conf file content: 
#		{"user":"iplant_username", "password":"iplant_password", "token":"iplant_token"}
#my $api_instance = iPlant::FoundationalAPI->new;

print "Token: ", $api_instance->token, "\n";

my $base_dir = '/' . $api_instance->user;
print "Working in [", $base_dir, "]", $/;

my ($st, $dir_contents_href);


#-----------------------------
# IO
#
my $io = $api_instance->io;
print STDERR Dumper( $io), $/;
if (1) {
	my $new_dir = 'API_test_' . rand(1000);
	my $new_dir_renamed = $new_dir;
	$new_dir_renamed =~ s/API_test/API_renamed_test/;

	$st = $io->mkdir($base_dir, $new_dir);
	$dir_contents_href = $io->readdir($base_dir);

	#print STDERR Dumper( $dir_contents_href), $/;
	list_dir($dir_contents_href);

	$st = $io->rename($base_dir . '/' . $new_dir, $new_dir_renamed);
	if ($st eq "-1") {
		print STDERR  "Unable to rename forlder..", $/;
		exit -1;
	}

	$dir_contents_href = $io->readdir($base_dir), $/;
	#print STDERR Dumper( $dir_contents_href), $/;
	list_dir($dir_contents_href);

	$st = $io->remove($base_dir . '/' . $new_dir_renamed);

	$st = $io->upload($base_dir, fileType =>'FASTA-0', fileToUpload => './t/A.fasta', fileName => 'A.fa');
	print STDERR 'upload status: ', Dumper( $st ), $/;

	$dir_contents_href = $io->readdir($base_dir), $/;
	#print STDERR Dumper( $dir_contents_href), $/;
	list_dir($dir_contents_href);
}

#-----------------------------
# DATA
# -not working yet?!

#my $data = $api_instance->data;
#$st = $data->transforms;
#print STDERR Dumper( $st ), $/;

#-----------------------------
# APPS
#

my $apps = $api_instance->apps;
$st = $apps->list(1);
print STDERR Dumper( $st ), $/;



