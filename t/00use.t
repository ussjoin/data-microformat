#!perl -w

use strict;
use Test::NoWarnings;
use Test::More tests => 7;

use_ok("Data::Microformat::adr");
use_ok("Data::Microformat::geo");
use_ok("Data::Microformat::hCard::type");
use_ok("Data::Microformat::hCard::name");
use_ok("Data::Microformat::hCard::organization");
use_ok("Data::Microformat::hCard");