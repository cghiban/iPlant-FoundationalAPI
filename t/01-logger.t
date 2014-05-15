#!/usr/bin/perl

use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use File::Basename;
#use JSON::Syck ();
use Log::UDP::Client ();
use iPlant::FoundationalAPI ();
use iPlant::FoundationalAPI::UDPLogger ();
use Data::Dumper; 
use Carp;

sub list_dir {
	my ($dir_contents) = @_;
	for (@$dir_contents) {
		print sprintf(" %6s\t%-30s\t%-30s", $_->type, $_->name, $_),  $/;
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

#my $logger = Log::UDP::Client->new;
my $logger = iPlant::FoundationalAPI::UDPLogger->new(pid => 111);
my $api_instance = iPlant::FoundationalAPI->new(logger => $logger);
#my $api_instance = iPlant::FoundationalAPI->new;

unless ($api_instance->token) {
	print STDERR "Can't authenticate!" , $/;
	exit 1;
}
print "Token: ", $api_instance->token, "\n";

my $base_dir = '/' . $api_instance->user;
print " + Working in [", $base_dir, "]", $/;

#-----------------------------
# IO
#
my $io = $api_instance->io;
#$io->debug(1);

my $tmp_dir = $base_dir . '/tmp';
my $x_dir;
my $dir_contents = eval {$io->readdir($base_dir);};
list_dir($dir_contents);

unless (grep {$_->name eq 'tmp'} @$dir_contents) {
    $io->mkdir($base_dir, 'tmp');
}
else {
    my $rnd = '000-' . int(rand(9_000_000));
    $io->mkdir($tmp_dir, $rnd);
    $x_dir = join '/', ($tmp_dir, $rnd);
}

$dir_contents = eval {$io->readdir($tmp_dir);};
list_dir($dir_contents);

if ($x_dir) {
    print STDERR  " + Removing dir [$x_dir]", $/;
    $io->remove($x_dir);

    $dir_contents = eval {$io->readdir($tmp_dir);};
    list_dir($dir_contents);
}

my $apps = $api_instance->apps;
#print STDERR Dumper( $apps), $/;

my ($app) = $apps->find_by_name("dnalc-fastqc-stampede");


my $job_id = 0;
if ($app) {
	
    my $file = '/ghiban/mouse_pe_sample_data/sham1_1.small.fastq';
	print "\n---------------------------------------------------------\n";
	print "Submitting a 'wc' job; input = ", $file;
	print "\n---------------------------------------------------------\n";

    my $job_ep = $api_instance->job;

	my %job_arguments = (
			jobName => 'job ' . basename($file),
			input => $file,
			printLongestLine => 0,
			archive => 1,
			#archivePath => "$base_dir/analyses/",
		);
	my $st = $job_ep->submit_job($app, %job_arguments);
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

print "\n---------------------------------------------------------\n";
print "Job submitted: API job id = ", $job_id;
print "\n---------------------------------------------------------\n";



