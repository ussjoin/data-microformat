#!perl -w

use strict;
use Data::Microformat::hCard::name;

use Test::More tests => 7;

my $simple = << 'EOF';
<span class="n">
	<span class="family-name">Pag</span>
	<span class="given-name">Zipo</span>
	<span class="additional-name">Judiciary</span>
	<span class="honorific-prefix">His High Judgmental Supremacy</span>
	<span class="honorific-suffix">Learned, Impartial, and Very Relaxed</span>
</span>
EOF

ok(my $name = Data::Microformat::hCard::name->parse($simple));


is($name->family_name, "Pag");
is($name->given_name, "Zipo");
is($name->additional_name, "Judiciary");
is($name->honorific_prefix, "His High Judgmental Supremacy");
is($name->honorific_suffix, "Learned, Impartial, and Very Relaxed");

my $comparison = << 'EOF';
<div class="n">
<div class="honorific-prefix">His High Judgmental Supremacy</div>
<div class="given-name">Zipo</div>
<div class="additional-name">Judiciary</div>
<div class="family-name">Pag</div>
<div class="honorific-suffix">Learned, Impartial, and Very Relaxed</div>
</div>
EOF

is($name->to_hcard, $comparison);