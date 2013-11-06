#!/usr/bin/perl

use strict;

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

my $path = shift;
my $user = shift;

unless (defined $path) {
    die "Usage: $0 <remote_file> [user]\n";
}

my $api_instance = iPlant::FoundationalAPI->new(hostname => 'iplant-dev.tacc.utexas.edu', debug => 0);
#$api_instance->debug(1);

unless ($api_instance->token) {
    warn "\nError: Authentication failed!\n";
    exit 1;
}

my $io = $api_instance->io;

if ($user) {
    #$io->debug(1);
    my $st = $io->share($path, $user, read => 1);
    #$io->debug(0);
    print STDERR Dumper( $st), $/;
}

my $perms = $io->get_perms($path);
#print STDERR Dumper( $perms), $/;
for my $p (@{$perms->{permissions}}) {
    print $p->{username}, "\t", join(",", map {"$_"} grep {$p->{permission}->{$_}} keys %{$p->{permission}}), $/;
}
