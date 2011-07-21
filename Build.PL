use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'iPlant::FoundationalAPI',
    license             => 'perl',
    dist_author         => q{Cornel Ghiban <ghiban@cshl.edu>},
    dist_version_from   => 'lib/iPlant/FoundationalAPI.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'iPlant-FoundationalAPI-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
