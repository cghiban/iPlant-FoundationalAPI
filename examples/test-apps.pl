#!/usr/bin/perl

use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Try::Tiny;

use iPlant::FoundationalAPI ();
use Data::Dumper; 

sub list_dir {
	my ($dir_contents) = @_;
	for (@$dir_contents) {
		print sprintf(" %6s\t%-40s\t%-40s", $_->type, $_->name, $_),  $/;
	}
	print "\n";
}

# this will read the configs from the ~/.iplant.foundationalapi.json file:
#	conf file content: 
#		{   "user":"iplant_username", 
#		    "password":"iplant_password", 
#		    "token":"iplant_token"
#		}
#		# set either the password or the token

# see examples/test-io.pl for another way to do auth
#
my $api_instance = iPlant::FoundationalAPI->new(debug => 0);
#$api_instance->debug(0);

unless ($api_instance->token) {
	print STDERR "Can't authenticate!" , $/;
	exit 1;
}

my $app_id = shift;
my $file_path = shift;

my $base_dir = '/' . $api_instance->user;
#print "Working in [", $base_dir, "]", $/;

#-----------------------------
# APPS
#

$api_instance->debug(0);
my $apps = $api_instance->apps;

unless ($app_id) {
    print "\n---------------------------------------------------------\n";
    print "Available applications (top 10):";
    print "\n---------------------------------------------------------\n";
    my @list = try {
            $apps->list;
        }
        catch {
            die $_ unless blessed $_ && $_->can('rethrow');
            if ( $_->isa('Agave::Exceptions') ) {
                warn $_->error, "\n", $_->trace->as_string, "\n";
                warn $_->content if $_->can('content');
                exit 1;
            }
            $_->rethrow;
        };
    @list = sort {$a->{id} cmp $b->{id}} @list;
    for my $ap (scalar @list > 10 ? @list[0..9] : @list) {
        print "\t", $ap, "    [", $ap->shortDescription, "]\n";
    }

    exit 0;
}

print "\n---------------------------------------------------------\n";
print "Looking for application $app_id";
print "\n---------------------------------------------------------\n";

my $ap_wc;
unless ($ap_wc) {
    ($ap_wc) = $apps->find_by_name($app_id);
    ($ap_wc) = $apps->find_by_id($ap_wc->id) if $ap_wc;
}
if ($ap_wc) {
	print "\nFound [", $ap_wc, "] - ", $ap_wc->name . ' | ', lc $ap_wc->shortDescription, "\n";
	print "\tInputs: \n";
	print "\t\t", $_->{id}, " - ", $_->{details}->{label} for ($ap_wc->inputs);
    if (@{$ap_wc->parameters}) {
    	print "\n\tParams: \n";
    	print "\t\t", $_->{id} for ($ap_wc->parameters);
    }
	print "\n\n";
}
else {
	print "\t No application found with name '$app_id'\n";

    exit 0;
}

#--------------------------
# JOB
#

unless (defined $file_path) {
    exit 0;
}
my $io = $api_instance->io;
my $file_info = $io->readdir($file_path);
unless ($file_info || 'iPlant::FoundationalAPI::Object::File' eq ref $file_info) {
    print STDERR  "File not found: ", $file_info, $/;
    exit 1;
}
#list_dir($file_info);

my $job_ep = $api_instance->job;
$job_ep->debug(1);

my $job_id = 0;
if ($ap_wc) {
	sleep 5;
	print "\n---------------------------------------------------------\n";
	print "Submitting a '$app_id' job; input = ", $file_path;
	print "\n---------------------------------------------------------\n";

    # for all the job options see documentation
    #  at http://agaveapi.co/job-management/
    my %job_arguments = (
            name => 'job ' . int(rand(1024)),
            archive => 'true',
        );

    my ($input) = ($ap_wc->inputs)[0];
    if ($input) {
        $job_arguments{$input->{id}} = $file_path;
    }
    print STDERR Dumper( \%job_arguments), $/ 
        if $job_ep->debug;

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

my $tries = 0;
while ($tries++ < 50) {
    my $j = $job_ep->job_details($job_id);
    #print STDERR Dumper( $j), $/ if $tries == 9;
    my $job_status = $j->status;
    print STDERR 'status: ', $job_status, $/;
    last if $job_status eq 'ARCHIVING_FINISHED' && $j->{archive};
    last if $job_status eq 'FINISHED' && !$j->{archive};

    if ($job_status =~ m/FAILED$/) {
        print STDERR  'message: ', $j->{message}, $/;
        last;
    }
    sleep 15 + $tries;
}

