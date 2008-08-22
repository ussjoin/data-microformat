use strict;
use warnings;

use Module::Build;

my $build = Module::Build
  ->new( module_name  => "Data::Microformat",
         license      => 'perl',
		 dist_author  => 'Brendan O\'Connor <perl@ussjoin.com>',
		 dist_abstrct => 'A module to parse and create hCards and related microformats',
		 dist_version => 0.03,
		 build_requires => {
							'Pod::Coverage'			=> '>= 0.18',
							'Test::More'            => 0,
							'Test::Pod'				=> '>= 1.22',
							'Test::Pod::Coverage'	=> '>= 1.08',
						},
         requires     => {
							'HTML::Entities' 		=> 0,
							'HTML::Stream' 			=> 0,
                            'HTML::TreeBuilder'     => 0,
                        },
         create_makefile_pl => 'traditional',
       );

$build->create_build_script;

