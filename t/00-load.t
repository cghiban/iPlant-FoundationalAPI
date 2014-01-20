#!/usr/bin/env perl

use Test::More tests => 5;

BEGIN {
    use_ok( 'iPlant::FoundationalAPI' );
    use_ok( 'iPlant::FoundationalAPI::IO' );
    use_ok( 'iPlant::FoundationalAPI::Auth' );
    use_ok( 'iPlant::FoundationalAPI::Apps' );
    use_ok( 'iPlant::FoundationalAPI::Job' );
}

diag( "Testing iPlant::FoundationalAPI $iPlant::FoundationalAPI::VERSION, Perl $], $^X" );
