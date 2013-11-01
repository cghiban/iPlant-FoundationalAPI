#!/usr/bin/perl

use common::sense;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use IO::File ();
use File::Spec ();
use AnyEvent ();
use iPlant::FoundationalAPI::Constants ':all';
use iPlant::FoundationalAPI ();
use Data::Dumper; 

my $output_dir = shift;
my $file = shift;
my $input_file;

unless ($output_dir) {
	usage("Ouput dir not specified!");
}

unless ($file) {
	usage("File not specified!");
}

unless (-d $output_dir ) {
	unless (mkdir $output_dir) {
		print STDERR  "Can't mkdir '$output_dir'", $/;
		exit -1;
	}
}

sub usage {
	my ($msg) = @_;
	print STDERR $msg, $/ if $msg;
	print STDERR "\n $0 <output_dir> <file_to_process>\n";
	print STDERR "\n\t(<file_to_process> 'sits' in iRods)\n", $/;
	exit -1;
}

sub list_dir {
	my ($dir_contents) = @_;
	for (@$dir_contents) {
		print $_, "\t", $_->size, "\t", $_->owner,  $/;
	}
	print "\n";
}

# this will read the configs from the ~/.iplant.foundationalapi.json file:
#	conf file content: 
#		{"user":"iplant_username", "password":"iplant_password", "token":"iplant_token"}
my $api_instance = iPlant::FoundationalAPI->new();
$api_instance->debug(1);
die "Can't auth.." unless $api_instance->auth;

if ($api_instance->token eq kExitError) {
	print STDERR "Can't authenticate!" , $/;
	exit 1;
}
print "Token: ", $api_instance->token, "\n";

my $base_dir = '/' . $api_instance->user;
print "Working in [", $base_dir, "]", $/;

my ($st, $dir_contents_href);

my $io = $api_instance->io;

# chech if file exists
$dir_contents_href = $io->readdir($base_dir . '/' . $file);
if (@$dir_contents_href && $dir_contents_href->[0]->is_file) {
	$input_file = $dir_contents_href->[0];
}
else {
	print STDERR  "File [$file] not found!!", $/;
	exit -1;
}
#print STDERR Dumper( $input_file), $/;
#list_dir($dir_contents_href);

#if (1) {
#----------------------------------------------------
# APPS end point
my $apps = $api_instance->apps;
my ($th) = $apps->find_by_name("tophat");
if ($th) {
	print STDERR Dumper( $th ), $/;
}
else {
	print STDERR  "App [tophat] not found!!", $/;
	exit -1;
}

#----------------------------------------------------
# JOBS end point
my $job_ep = $api_instance->job;
$job_ep->debug(0);

my $job_id = 0;
my %job_arguments = (
			jobName => 'TH-job40-' . int(rand(100)),
			archive => 1,
			query1 => $input_file->path,
			genome => '/shared/iplantcollaborative/genomeservices/legacy/0.30/genomes/arabidopsis_thaliana/col-0/v10/genome.fas',
			annotation => '/shared/iplantcollaborative/genomeservices/legacy/0.30/genomes/arabidopsis_thaliana/col-0/v10/annotation.gtf',
			processors => '1',
			requestedTime => '1:10:00',
			softwareName => $th->id,
			archive => 1,

			'max_insertion_length' => '3',
			'mate_inner_dist' => '200',
			'min_intron_length' => '70',
			'min_anchor_length' => '8',
			'max_multihits' => '20',
			'library_type' => 'fr-unstranded',
			'max_deletion_length' => '3',
			'splice_mismatches' => '0',
			'max_intron_length' => '50000',
			'min_isoform_fraction' => '0.15',
			'mate_std_dev' => '20',
			'segment_length' => '20',
		);

my $job = $job_ep->submit_job($th, %job_arguments), $/;
print STDERR Dumper($job), $/; 
if ($job != kExitError) {
	$job_id = $job->{id};
	print STDERR  "JOB_ID: ", $job_id, $/;
}
else {
	print STDERR  "Failed to submit job..", $/;
}

print STDERR  "Polling for job status..", $/;

my $i = 40; #number of trials..
my $cv = AnyEvent->condvar;
my $w = AnyEvent->timer (after => 30, interval => 60,
		cb => sub {

			# check if auth tocken will soon expire
			#unless ($api_instance->auth->is_token_valid()) {
			#	print STDERR "Tadaaahh.. auth failed?!", $/;
			#	$cv->send;
			#}

			my $st = $job_ep->job_details($job_id);
			$i--;
			#$cv->send($st->{outputUrl}) if $st->{status} =~ /FINISHED$/;
			$cv->send($job_id) if $st->{status} =~ /FINISHED$/;
			$cv->send unless $i;
			print $job_id, "\t", $st->{status}, $/;
		}
	);

my ($file_list_path) = $cv->recv;
# or simply
# AnyEvent->condvar->recv;
undef $w;

#} # end if 0

#my $file_list_path = "https://foundation.iplantc.org/apps-v1//job/318/output/list";
#my $job_id = 318;

if ($file_list_path || $job_id) {
	$file_list_path =~ s|/+|/|g;
	#print "\nFile list for this job availabale \@:\n\t", $file_list_path, $/;

	my $job_ep = $api_instance->job;

	$dir_contents_href = $job_ep->job_output_files($job_id);
	#print STDERR Dumper( $dir_contents_href), $/;
	my $th_output_dir = '';
	if ($dir_contents_href && @$dir_contents_href) {
		($th_output_dir) = map {$_->{name}} grep {$_->{name} =~ /tophat_out\/?/ && $_->{type} eq 'dir' } @$dir_contents_href;
	}

	my $fh = IO::File->new;
	if ($fh->open(File::Spec->catfile($output_dir, 'th_output'), 'w')) {
		print $fh $th_output_dir;
		undef $fh;
	}
}
