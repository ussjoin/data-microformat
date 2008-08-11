use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::Microformat',
    AUTHOR              => 'Brendan O\'Connor <perl@ussjoin.com>',
    VERSION_FROM        => 'lib/Data/Microformat/hCard/base.pm',
    ABSTRACT            => 'A module to parse and create hCards and related microformats',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'HTML::Stream' => 0,
        'HTML::TreeBuilder' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-Microformat-*' },
);
