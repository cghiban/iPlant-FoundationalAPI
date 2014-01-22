#!/usr/bin/perl -w

use Test::More;

my $TNUM = 11;
plan tests => $TNUM;

use FindBin;
use iPlant::FoundationalAPI ();

my $conf_file = "$FindBin::Bin/agave-auth.json";

diag <<EOF


********************* WARNING ********************************
The t/agave-auth.json is missing. Here's the structure:
    {
        "user"      :"", 
        "password"  :"",
        "csecret"   :"",
        "ckey"      :""
    }

For more details go to http://agaveapi.co/authentication-token-management/


EOF
unless (-f $conf_file);

SKIP: {
    skip "Create the t/agave-auth.json file for tests to run", $TNUM
        unless (-f $conf_file);

    my $api = iPlant::FoundationalAPI->new( config_file => $conf_file, http_timeout => 40);

    ok( defined $api, "API object created");
    ok( defined $api->token, "Authentication succeeded" );

    unless ($api && $api->token) {
        skip "Auth failed. No reason to continue..", $TNUM - 2;
    }

    my $io = $api->io;
    ok( defined $io, "IO endpoint successfully created");

    # read users directory 
    my $base_dir = '/' . $api->user;
	my $dir_data = eval {$io->readdir($base_dir);};
    if (my $err = $@) {
        diag(ref $err ? $err->message . "\n" . $err->content : $err);
    }
    ok( defined $dir_data, "Received IO response");
    ok( 'ARRAY' eq ref $dir_data, "IO response is valid");
    ok( @$dir_data > 0, "We have at least one file/dir");

    # First file is the directory itself
    my $dir = $$dir_data[0];
    ok( $dir && ref($dir), "We received an object");
    ok( $dir->isa('iPlant::FoundationalAPI::Object::File'),  "We received the right kind of object");
    is( $dir->name, '.', "We received the user's directory");

	my $new_dir = '000-automated-test-' . rand(1000);
	my $st = $io->mkdir($base_dir, $new_dir);
    is( $st->{status}, 'success', "Directory created successfully");
    diag("Directory not removed: " . $st->{message})
        unless( $st->{status} eq 'success' );

	$st = $io->remove($base_dir . '/' . $new_dir);
    ok ( $st, "Directory removed successfully");

}

