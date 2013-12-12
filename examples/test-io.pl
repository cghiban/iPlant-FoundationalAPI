#!/usr/bin/perl

use common::sense;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use iPlant::FoundationalAPI ();
use Data::Dumper; 

sub list_dir {
	my ($dir_contents) = @_;
	for (@$dir_contents) {
		print sprintf(" %6s\t%-40s\t%-40s", $_->type, $_->name, $_),  $/;
	}
	print "\n";
}

# one way to authenticate
if (0) {
	unless (defined $ENV{IPLANT_USERNAME} && (defined $ENV{IPLANT_PASSWORD} || $ENV{IPLANT_TOKEN})) {
		print "Env variables IPLANT_USERNAME and IPLANT_PASSWORD or IPLANT_TOKEN are undefined", $/;
		exit;
	}

	my $api_instance = iPlant::FoundationalAPI->new(
			hostname => 'agave.iplantc.org',
            ckey => '...',
            csecret => '...',
			user => $ENV{IPLANT_USERNAME},
			token => $ENV{IPLANT_TOKEN},
			debug => 1,
			password => $ENV{IPLANT_PASSWORD},
		);
}
## or

# this will read the configs from the ~/.iplant.foundationalapi.v2.json file:
#	conf file content: 
#		{"user":"iplant_username", "password":"iplant_password", "ckey":"", "csecret":"", "token":""}
#		# set either the password or the token

#my $api_instance = iPlant::FoundationalAPI->new(debug => 1);
my $api_instance = iPlant::FoundationalAPI->new(debug => 0);

unless ($api_instance->token) {
    warn "\nError: Authentication failed!\n";
    exit 1;
}
print "Token: ", $api_instance->token, "\n" if $api_instance->debug;

my $base_dir = '/' . $api_instance->user;
print "Working in [", $base_dir, "]", $/;

my ($st, $dir_contents_href);

#-----------------------------
# IO
#
    my $io = $api_instance->io;
    $io->debug(0);

	print "---------------------------------------------------------\n";
	print "\t** Listing of directory: ", $base_dir, $/;
	print "---------------------------------------------------------\n";

	$dir_contents_href = $io->readdir($base_dir);
    #print STDERR Dumper( $dir_contents_href), $/;
	list_dir($dir_contents_href);

exit 0;
	my $new_dir = 'Agave_API_test_' . rand(1000);
	my $new_dir_renamed = $new_dir;
	$new_dir_renamed =~ s/Agave_API_test/API_renamed_test/;


	print "---------------------------------------------------------\n";
	print "\t** Creating directory: ", $new_dir, $/;
	print "---------------------------------------------------------\n";

	$st = $io->mkdir($base_dir, $new_dir);
	$dir_contents_href = $io->readdir($base_dir);

	list_dir($dir_contents_href);

	sleep 3;
	print "---------------------------------------------------------\n";
	print "\t** Renaming it to: ", $new_dir_renamed, $/;
	print "---------------------------------------------------------\n";

	$st = $io->rename($base_dir . '/' . $new_dir, $new_dir_renamed);
	if ($st eq "-1") {
		print STDERR  "Unable to rename forlder..", $/;
		exit -1;
	}

	$dir_contents_href = $io->readdir($base_dir), $/;
	#print STDERR Dumper( $dir_contents_href), $/;
	list_dir($dir_contents_href);

	sleep 3;

    my $new_file_name = "Bx_" . int(rand(99)) . '.fa';
	print "---------------------------------------------------------\n";
	print "\t** Removing the new dir & adding a new file, ", $new_file_name, $/;
	print "---------------------------------------------------------\n";
	$st = $io->remove($base_dir . '/' . $new_dir_renamed);

	$st = $io->upload($base_dir, fileType =>'FASTA-0', fileToUpload => "$Bin/../t/A.fasta", fileName => $new_file_name);
	#print STDERR 'upload status: ', Dumper( $st ), $/;

	sleep 3;
	$dir_contents_href = $io->readdir($base_dir), $/;
	list_dir($dir_contents_href);

