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
#print STDERR Dumper( $dir_contents_href), $/;
#__END__
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
my ($cl) = $apps->find_by_name("dnalc-cufflinks-lonestar-2.0.2");
if ($cl) {
	print STDERR Dumper( $cl ), $/;
}
else {
	print STDERR  "App [dnalc-cufflinks-lonestar-2.0.2] not found!!", $/;
	exit -1;
}

#----------------------------------------------------
# JOBS end point
my $job_ep = $api_instance->job;
$job_ep->debug(1);

my $job_id = 0;
my %job_arguments = (
			jobName => 'CL-job-random' . int(rand(100)),
			archive => 1,
			query1 => $input_file->path,
			BIAS_FASTA => '/shared/iplantcollaborative/genomeservices/legacy/0.30/genomes/arabidopsis_thaliana/col-0/v10/genome.fas',
			ANNOTATION => '/shared/iplantcollaborative/genomeservices/legacy/0.30/genomes/arabidopsis_thaliana/col-0/v10/annotation.gtf',
			processors => '1',
			requestedTime => '2:10:00',
			softwareName => $cl->id,

			compatibleHitsNorm => 0,
			preMrnaFraction => '0.15',
			smallAnchorFraction => '0.09',
			noFauxReads => 0,
			trim3avgcovThresh => '10',
			trim3dropoffFrac => '0.1',
			minIsoformFraction => '0.1',
			minFragsPerTransfrag => '10',
			intronOverhangTolerance => '10',
			libraryType => 'fr-unstranded',
			minIntronLength => '50',
			maxIntronLength => '300000',
			maxBundleLength => '3500000',
			overhangTolerance => '10',
			overhangTolerance3 => '600',
			totalHitsNorm => 1,
			upperQuartileNorm => 0,
			multiReadCorrect => 0,
		);

my $job = $job_ep->submit_job($cl, %job_arguments), $/;
#print STDERR Dumper($job), $/; 
if ($job != kExitError) {
	$job_id = $job->{data} ? $job->{data}->{id} : $job->{id};
	print STDERR  "JOB_ID: ", $job_id, $/;
}
else {
	print STDERR  "Failed to submit job..", $/;
}

unless ($job_id) {
	die "Job not submitted..\n";
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
