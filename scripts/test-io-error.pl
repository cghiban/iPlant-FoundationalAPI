#!/usr/bin/perl

use strict;
use Carp;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use iPlant::FoundationalAPI ();
use Data::Dumper; 

# this will read the configs from the ~/.iplant.foundationalapi.json file:
#       conf file content: 
#               {"user":"iplant_username", "password":"iplant_password", "token":"iplant_token"}
#               # set either the password or the token (use valid token)

my $api_instance = iPlant::FoundationalAPI->new;
$api_instance->debug(0);

unless ($api_instance->token) {
    warn "\nError: Authentication failed!\n";
    exit 1;
}


my $io = $api_instance->io;

my $file_info = eval {$io->ls("/invalid-file-path.dat");};
if (my $err = $@) {
    $err =~ s/ at .*? line \d+\.$//;
    print STDERR  "Error: ", $err, $/;
    exit 1;
}

# we should never get here
print STDERR Dumper( $file_info), $/;

