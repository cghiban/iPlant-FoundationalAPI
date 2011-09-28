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

if (0) {
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

}
## or

# this will read the configs from the ~/.iplant.foundationalapi.json file:
#	conf file content: 
#		{"user":"iplant_username", "password":"iplant_password", "token":"iplant_token"}
my $api_instance = iPlant::FoundationalAPI->new;
$api_instance->debug(0);

if ($api_instance->token eq kExitError) {
	print STDERR "Can't authenticate!" , $/;
	exit 1;
}
print "Token: ", $api_instance->token, "\n";

my $base_dir = '/' . $api_instance->user;
print "Working in [", $base_dir, "]", $/;

my ($st, $dir_contents_href);

__END__

#-----------------------------
# IO
#
my $io = $api_instance->io;
#print STDERR Dumper( $io), $/;
if (0) {
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

	$st = $io->upload($base_dir, fileType =>'FASTA-0', fileToUpload => "$Bin/../t/A.fasta", fileName => "Bx.fa");
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

my $ap_wc;
if (1) {
	$api_instance->debug(0);
	my $apps = $api_instance->apps;
	my @list = $apps->list;
	print "\nAvailable applications:\n";
	for my $ap (@list) {
		print "\t", $ap, "  (", $ap->shortDescription, ")\n";
	}
	print "\nLooking for applications 'wc':\n";
	($ap_wc) = $apps->find_by_name("wc");
	if ($ap_wc) {
		#print STDERR Dumper( $ap_wc), $/;
		print "\nFound [", $ap_wc, "] - ", lc $ap_wc->shortDescription, $/;

		print "\tInputs: \n";
		print "\t\t", $_->{id}, " - ", $_->{label} for ($ap_wc->inputs);
		print "\n\tParams: \n";
		print "\t\t", $_->{id}, " - ", $_->{label} for ($ap_wc->parameters);
		print "\n";
	}
	else {
		print "\t No application found with name 'wc'\n";
	}

}

#--------------------------
# JOB
#

my $job_ep = $api_instance->job;
$job_ep->debug(1);

my $job_id = 0;
if ($ap_wc) {
	#print STDERR  Dumper($job_ep), $/;
	my %job_arguments = (
			jobName => 'job22',
			query1 => '/ghiban/A.txt',
			printLongestLine => 1,
			archive => 1,
			archivePath => '/ghiban/analyses/',
		);
	my $job = $job_ep->submit_job($ap_wc, %job_arguments), $/;
	#print STDERR Dumper($job), $/; 
	if ($job != kExitError) {
		$job_id = $job->{id};
	}

}
else {
	$job_id = 181;
}
print STDERR  "Job ID: $job_id", $/;

$st = $job_ep->job_details($job_id);
#print STDERR Dumper( $st ), $/;
print STDERR  'status: ', $st->{status}, $/;

#$st = $job_ep->input($job_id);
#print STDERR Dumper( $st ), $/;

my $job_list = $job_ep->jobs;
#print STDERR Dumper( $st ), $/;
for (@$job_list) {
	print $_->{id}, "\t", $_->{name}, "\t", $_->{endTime}/1000, $/;
}

# # delete oldest job..
# $job_id = @$job_list ? $job_list->[scalar @$job_list - 1] : undef;
# if ($job_ep) {
# 	$st = $job_ep->delete_job(84);
# 	print STDERR  Dumper($st), $/;
# }



