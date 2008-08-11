#!perl -w

use strict;
use Data::Microformat::hCard::type;

use Test::More tests => 13;

#Basic type taken from the microformats wiki: http://microformats.org/wiki/hcard
my $simple = << 'EOF';
<span class="tel">
	<span class="type">Home</span>
	<span class="value">+1.415.555.1212</span>
</span>
EOF

ok(my $type = Data::Microformat::hCard::type->parse($simple));

is($type->kind, "tel");
is($type->type, "Home");
is($type->value, "+1.415.555.1212");

my $comparison = << 'EOF';
<div class="tel">
<div class="value">+1.415.555.1212</div>
<div class="type">Home</div>
</div>
EOF
is ($type->to_hcard, $comparison);

my $medium = << 'EOF';
<span class="email"><span class="type">Work</span> test@example.com</span>
EOF

ok($type = Data::Microformat::hCard::type->parse($medium));

is($type->kind, "email");
is($type->type, "Work");
is($type->value, 'test@example.com');

$comparison = << 'EOF';
<div class="email">
<div class="value">test@example.com</div>
<div class="type">Work</div>
</div>
EOF

is($type->to_hcard, $comparison);

my $hard = << 'EOF';
<a class="email" href="mailto:test@example.com">Email</a>
EOF

ok($type = Data::Microformat::hCard::type->parse($hard));

is ($type->value, 'test@example.com');

$comparison = << 'EOF';
<div class="email">
<div class="value">test@example.com</div>
</div>
EOF

is($type->to_hcard, $comparison);