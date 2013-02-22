#!/usr/bin/perl

use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use iPlant::FoundationalAPI::Constants ':all';
use iPlant::FoundationalAPI ();
use Data::Dumper; 

sub list_dir {
	my ($dir_contents) = @_;
	for (@$dir_contents) {
		print sprintf(" %6s\t%-40s\t%-40s", $_->type, $_->name, $_),  $/;
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
#		# set either the password or the token

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
my $new_file_name = "Bx_" . int(rand(99)) . '.fa';


#-----------------------------
# IO
#
my $io = $api_instance->io;
if (1) {
	my $new_dir = 'API_test_' . rand(1000);
	my $new_dir_renamed = $new_dir;
	$new_dir_renamed =~ s/API_test/API_renamed_test/;


	print "---------------------------------------------------------\n";
	print "\t** Creating directory: ", $new_dir, $/;
	print "---------------------------------------------------------\n";

	$st = $io->mkdir($base_dir, $new_dir);
	$dir_contents_href = $io->readdir($base_dir);

	#print STDERR Dumper( $dir_contents_href), $/;
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
	print "---------------------------------------------------------\n";
	print "\t** Removing the new dir & adding a new file, ", $new_file_name, $/;
	$st = $io->remove($base_dir . '/' . $new_dir_renamed);

	$st = $io->upload($base_dir, fileType =>'FASTA-0', fileToUpload => "$Bin/../t/A.fasta", fileName => $new_file_name);
	#print STDERR 'upload status: ', Dumper( $st ), $/;

	sleep 3;
	print "---------------------------------------------------------\n";
	$dir_contents_href = $io->readdir($base_dir), $/;
	list_dir($dir_contents_href);

	sleep 5;
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
	sleep 3;
	print "\n---------------------------------------------------------\n";
	print "Available applications (top 30):";
	print "\n---------------------------------------------------------\n";
	my @list = sort {$a->{id} cmp $b->{id}} $apps->list;
	for my $ap (@list[0..30]) {
		print "\t", $ap, "    [", $ap->shortDescription, "]\n";
	}

	sleep 3;
	print "\n---------------------------------------------------------\n";
	print "Looking for application 'wc' - Word Count:";
	print "\n---------------------------------------------------------\n";

	($ap_wc) = $apps->find_by_name("wc");
	if ($ap_wc) {
		print "\nFound [", $ap_wc, "] - ", lc $ap_wc->shortDescription, $/;

		print "\tInputs: \n";
		print "\t\t", $_->{id} for ($ap_wc->inputs);
		print "\n\tParams: \n";
		print "\t\t", $_->{id} for ($ap_wc->parameters);
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
$job_ep->debug(0);

my $job_id = 0;
if ($ap_wc) {
	sleep 5;
	print "\n---------------------------------------------------------\n";
	print "Submitting a 'wc' job; input = ", $new_file_name;
	print "\n---------------------------------------------------------\n";


	#print STDERR  Dumper($job_ep), $/;
	my %job_arguments = (
			jobName => 'job ' . $new_file_name,
			query1 => "$base_dir/$new_file_name",
			printLongestLine => 0,
			archive => 1,
			#archivePath => "$base_dir/analyses/",
		);
	my $st = $job_ep->submit_job($ap_wc, %job_arguments);
	my $job = $st->{status} eq 'success' ? $st->{data} : undef;
	if ($job) {
		$job_id = $job->id;
	}
	else {
		print "\n---------------------------------------------------------\n";
		print "Job status: ", Dumper($st);
		print "\n---------------------------------------------------------\n";
	}
}
else {
	exit 0;
}

sleep 3;
print "\n---------------------------------------------------------\n";
print "Job submitted: API job id = ", $job_id;
print "\n---------------------------------------------------------\n";

$job_ep->debug(0);

my $tries = 10;
while ($tries--) {
	my $j = $job_ep->job_details($job_id);
	#print STDERR "\t", ref $j, $/;
	#print STDERR Dumper( $j), $/ if $tries == 9;
	print STDERR 'status: ', $j->status, $/;
	last if $j->status =~ /^(ARCHIVING_)?FINISHED$/;

	sleep 30;
}

__END__
my $job_list = $job_ep->jobs;
#print STDERR Dumper( $st ), $/;
for (@$job_list) {
	print $_->{id}, "\t", $_->{name}, "\t", $_->{endTime}/1000, $/;
}

# # delete oldest job..
# $job_id = @$job_list ? $job_list->[scalar @$job_list - 1] : undef;
# if ($job_ep) {
# 	$st = $job_ep->delete_job($job_id);
# 	print STDERR  Dumper($st), $/;
# }



