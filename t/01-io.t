#!/usr/bin/perl -w

use Test::More;

plan tests => 10;

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
    skip "Create the t/agave-auth.json file for tests to run", 2
        unless (-f $conf_file);

    my $api = iPlant::FoundationalAPI->new( config_file => $conf_file, http_timeout => 40);

    ok( defined $api, "API object created");
    ok( defined $api->token, "Authentication succeeded" );

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
    ok( ref($dir) =~ /::Object::File$/, "We received a File object");
    ok( $dir->name eq '.', "We received the user directory");


	my $new_dir = '000-automated-test-' . rand(1000);
	my $st = $io->mkdir($base_dir, $new_dir);
    ok( $st->{status} eq 'success', "Directory created successfully");
    diag("Directory not removed: " . $st->{message})
        unless( $st->{status} eq 'success' );

	$st = $io->remove($base_dir . '/' . $new_dir);
    ok ( $st, "Directory removed successfully");

}

