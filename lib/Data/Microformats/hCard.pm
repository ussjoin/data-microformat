package Data::Microformats::hCard;
use base qw(Data::Microformats::hCard::base);

use strict;

use HTML::TreeBuilder;
use Data::Microformats::adr;
use Data::Microformats::geo;
use Data::Microformats::hCard::type;
use Data::Microformats::hCard::name;
use Data::Microformats::hCard::organization;

sub from_tree
{
	my $class = shift;
	my $tree = shift;
	
	my @all_cards;
	my @cards = $tree->look_down("class", qr/vcard/);

	foreach my $card_tree (@cards)
	{
		# Walk the tree looking for useless bits
		# Where class is undefined
		my @useless = $card_tree->look_down("class", undef);
		foreach my $element (@useless)
		{
			my @kids = $element->detach_content;
			my $parent = $element->detach;
			if (@kids)
			{
				$parent->push_content(@kids);
			}
			$element->delete;
		}
		
		my $card = Data::Microformats::hCard->new;
		my @bits = $card_tree->content_list;
		
		foreach my $bit (@bits)
		{
			if (ref($bit) eq "HTML::Element")
			{
				my $nested_goes_here;
				my $hcard_class = $bit->attr('class');
				next unless $hcard_class;
				#Check for nested vcard.
				if ($hcard_class =~ m/vcard/)
				{
					#We have a nested class in here. Mark where it needs to go.
					my $temp_hcard_class = $hcard_class;
					$temp_hcard_class =~ s/vcard//;
					$temp_hcard_class = $class->_trim($temp_hcard_class);
					my @types = split(" ", $temp_hcard_class);
					if (scalar @types > 0)
					{
						$nested_goes_here = $types[0];
						$hcard_class =~ s/$nested_goes_here//;
						$hcard_class = $class->_trim($hcard_class);
						#We do this so that if the type is, for instance,
						# "agent vcard," that we just put the vcard in
						# agent, and not anywhere else.
						# vcard *MUST* have another class, otherwise we'll
						# discard it.
					}
				}
				my @types = split(" ", $hcard_class);
				foreach my $type (@types)
				{
					$type =~ s/\-/\_/;
					$type = $class->_trim($type);
					
					my $data;
					my @cons = $bit->content_list;
					
					if (scalar @cons > 1)
					{
						#print STDERR "DATA: Possible failure for bit $bit from type $type.\n";
					}
					else
					{
						$data = $class->_trim($cons[0]);
						if ($bit->tag eq "abbr" && $bit->attr('title'))
						{
							$data = $class->_trim($bit->attr('title'));
						}
						elsif ($bit->tag eq "a" && $bit->attr('href'))
						{
							if ($type =~ m/(photo|logo|agent|sound|url)/)
							{
								$data = $class->_trim($bit->attr('href'));
							}
						}
						elsif ($bit->tag eq "object" && $bit->attr('data'))
						{
							if ($type =~ m/(photo|logo|agent|sound|url)/)
							{
								$data = $class->_trim($bit->attr('data'));
							}
						}
						elsif ($bit->tag eq "img")
						{
							if ($type =~ m/(photo|logo|agent|sound|url)/ && $bit->attr('src'))
							{
								$data = $class->_trim($bit->attr('src'));
							}
							elsif ($bit->attr('alt'))
							{
								$data = $class->_trim($bit->attr('alt'));
							}
						}
					}
					
					if ($type eq "vcard")
					{
						my $nestedcard = $class->from_tree($bit);
						if ($nested_goes_here)
						{
							$card->$nested_goes_here($nestedcard);
						}
					}
					elsif ($type eq "tel")
					{
						my $tel = Data::Microformats::hCard::type->from_tree($bit);
						$card->tel($tel);
					}
					elsif ($type eq "email")
					{
						my $email = Data::Microformats::hCard::type->from_tree($bit);
						$card->email($email);
					}
					elsif ($type eq "n")
					{
						my $name = Data::Microformats::hCard::name->from_tree($bit);
						$card->n($name);
					}
					elsif ($type eq "adr")
					{
						my $adr = Data::Microformats::adr->from_tree($bit);
						$card->adr($adr);
					}
					elsif ($type eq "geo")
					{
						my $geo = Data::Microformats::geo->from_tree($bit);
						$card->geo($geo);
					}
					elsif ($type eq "org")
					{
						my $org = Data::Microformats::hCard::organization->from_tree($bit);
						$card->org($org);
					}
					elsif ($type eq "url" && $bit->attr('href'))
					{
							$card->url($class->_trim($bit->attr('href')));
					}
					else
					{
						eval { $card->$type($data); };
						if ($@)
						{
							print STDERR "Didn't recognize type $type.\n";
						}
					}
				}
			}
		}
		
		# Check: Implied N Optimization?
		if (!$card->n && $card->fn && (!$card->org || (!$card->fn eq $card->org)))
		{
			my $n = Data::Microformats::hCard::name->new;
			my @arr = split(" ", $card->fn);
			if ($arr[1])
			{
				$arr[1] =~ s/\.//;
			}
			if ($arr[0] =~ m/\,/ && length $arr[1] == 1)
			{
				$arr[0] =~ s/\,//;
				$n->family_name($class->_trim($arr[0]));
				$n->given_name($class->_trim($arr[1]));
			}
			else
			{
				$n->family_name($class->_trim($arr[1]));
				$n->given_name($class->_trim($arr[0]));
			}
			$card->n($n);
		}
		
		# Check: Org?
		if (($card->org) && (($card->fn || "") eq $card->org->organization_name))
		{
			my $name = Data::Microformats::hCard::name->new;
			$name->family_name("");
			$name->given_name("");
			$name->additional_name("");
			$name->honorific_prefix("");
			$name->honorific_suffix("");
			$card->n($name);
		}
		
		# Check: Nickname Optimization?
		if ($card->fn)
		{
			my @words = split(" ", $card->fn);
			if (($card->org && (!$card->org->organization_name eq $card->fn)) && (!$card->n) && (scalar @words == 1))
			{
				$card->nickname($card->fn);
				my $name = Data::Microformats::hCard::name->new;
				$name->family_name("");
				$name->given_name("");
				$name->additional_name("");
				$name->honorific_prefix("");
				$name->honorific_suffix("");
				$card->n($name);
			}
		}
		push (@all_cards, $card);
	}
	
	$tree->delete;
	
	if (wantarray)
	{
		return @all_cards;
	}
	else
	{
		return $all_cards[0];
	}
}

# Singular Only
sub fn { my $self = shift; if (@_ && !$self->{fn}) { $self->{fn} = shift } return $self->{fn}; }

sub n { my $self = shift; if (@_ && !$self->{n}) { $self->{n} = shift } return $self->{n}; }

sub bday { my $self = shift; if (@_ && !$self->{bday}) { $self->{bday} = shift } return $self->{bday}; }

sub tz { my $self = shift; if (@_ && !$self->{tz}) { $self->{tz} = shift } return $self->{tz}; }

sub geo { my $self = shift; if (@_ && !$self->{geo}) { $self->{geo} = shift } return $self->{geo}; }

sub sort_string { my $self = shift; if (@_ && !$self->{sort_string}) { $self->{sort_string} = shift } return $self->{sort_string}; }

sub uid { my $self = shift; if (@_ && !$self->{uid}) { $self->{uid} = shift } return $self->{uid}; }

sub class { my $self = shift; if (@_ && !$self->{class}) { $self->{class} = shift } return $self->{class}; }

#Possibly Plural

sub adr
{ 
	my $self = shift;
	if (!$self->{adr})
	{
		$self->{adr} = [];
	}
	my $adr = $self->{adr};
	
	if (@_) 
	{ 
		my $new = shift;
		push (@$adr, $new);
	} 
	if (wantarray)
	{
		return @$adr; 
	}
	else
	{
		return @$adr[0];
	} 
}

sub agent
{ 
	my $self = shift;
	if (!$self->{agent})
	{
		$self->{agent} = [];
	}
	my $agent = $self->{agent};
	if (@_) 
	{ 
		my $new = shift;
		push (@$agent, $new);
	}
	if (wantarray)
	{
		return @$agent; 
	}
	else
	{
		return @$agent[0];
	}
}

sub category
{ 
	my $self = shift;
	if (!$self->{category})
	{
		$self->{category} = [];
	}
	my $category = $self->{category};
	if (@_) 
	{ 
		my $new = shift;
		push (@$category, $new);
	}
	if (wantarray)
	{
		return @$category; 
	}
	else
	{
		return @$category[0];
	}
}

sub email
{ 
	my $self = shift;
	if (!$self->{email})
	{
		$self->{email} = [];
	}
	my $email = $self->{email};
	
	if (@_) 
	{ 
		my $new = shift;
		push (@$email, $new);
	} 
	if (wantarray)
	{
		return @$email; 
	}
	else
	{
		return @$email[0];
	}
}

sub key
{ 
	my $self = shift;
	if (!$self->{key})
	{
		$self->{key} = [];
	}
	my $key = $self->{key};
	if (@_) 
	{ 
		my $new = shift;
		push (@$key, $new);
	}
	if (wantarray)
	{
		return @$key; 
	}
	else
	{
		return @$key[0];
	}
}

sub label
{ 
	my $self = shift;
	if (!$self->{label})
	{
		$self->{label} = [];
	}
	my $label = $self->{label};
	if (@_) 
	{ 
		my $new = shift;
		push (@$label, $new);
	}
	if (wantarray)
	{
		return @$label; 
	}
	else
	{
		return @$label[0];
	}
}

sub logo
{ 
	my $self = shift;
	if (!$self->{logo})
	{
		$self->{logo} = [];
	}
	my $logo = $self->{logo};
	if (@_) 
	{ 
		my $new = shift;
		push (@$logo, $new);
	}
	if (wantarray)
	{
		return @$logo; 
	}
	else
	{
		return @$logo[0];
	}
}
 
sub mailer
{ 
	my $self = shift;
	if (!$self->{mailer})
	{
		$self->{mailer} = [];
	}
	my $mailer = $self->{mailer};
	if (@_) 
	{ 
		my $new = shift;
		push (@$mailer, $new);
	}
	if (wantarray)
	{
		return @$mailer; 
	}
	else
	{
		return @$mailer[0];
	}
}

sub nickname
{ 
	my $self = shift;
	if (!$self->{nickname})
	{
		$self->{nickname} = [];
	}
	my $nickname = $self->{nickname};
	if (@_) 
	{ 
		my $new = shift;
		push (@$nickname, $new);
	}
	if (wantarray)
	{
		return @$nickname; 
	}
	else
	{
		return @$nickname[0];
	}
}

sub note
{ 
	my $self = shift;
	if (!$self->{note})
	{
		$self->{note} = [];
	}
	my $note = $self->{note};
	if (@_) 
	{ 
		my $new = shift;
		push (@$note, $new);
	}
	if (wantarray)
	{
		return @$note; 
	}
	else
	{
		return @$note[0];
	}
}

sub org
{ 
	my $self = shift;
	if (!$self->{org})
	{
		$self->{org} = [];
	}
	my $org = $self->{org};
	if (@_) 
	{ 
		my $new = shift;
		push (@$org, $new);
	}
	if (wantarray)
	{
		return @$org; 
	}
	else
	{
		return @$org[0];
	}
}

sub photo
{ 
	my $self = shift;
	if (!$self->{photo})
	{
		$self->{photo} = [];
	}
	my $photo = $self->{photo};
	if (@_) 
	{ 
		my $new = shift;
		push (@$photo, $new);
	}
	if (wantarray)
	{
		return @$photo; 
	}
	else
	{
		return @$photo[0];
	}
}

sub rev
{ 
	my $self = shift;
	if (!$self->{rev})
	{
		$self->{rev} = [];
	}
	my $rev = $self->{rev};
	if (@_) 
	{ 
		my $new = shift;
		push (@$rev, $new);
	}
	if (wantarray)
	{
		return @$rev; 
	}
	else
	{
		return @$rev[0];
	}
}

sub role
{ 
	my $self = shift;
	if (!$self->{role})
	{
		$self->{role} = [];
	}
	my $role = $self->{role};
	if (@_) 
	{ 
		my $new = shift;
		push (@$role, $new);
	}
	if (wantarray)
	{
		return @$role; 
	}
	else
	{
		return @$role[0];
	}
}

sub sound
{ 
	my $self = shift;
	if (!$self->{sound})
	{
		$self->{sound} = [];
	}
	my $sound = $self->{sound};
	if (@_) 
	{ 
		my $new = shift;
		push (@$sound, $new);
	}
	if (wantarray)
	{
		return @$sound; 
	}
	else
	{
		return @$sound[0];
	}
}

sub tel
{ 
	my $self = shift;
	if (!$self->{tel})
	{
		$self->{tel} = [];
	}
	my $tel = $self->{tel};
	if (@_) 
	{ 
		my $new = shift;
		push (@$tel, $new);
	}
	if (wantarray)
	{
		return @$tel; 
	}
	else
	{
		return @$tel[0];
	}
}

sub title
{ 
	my $self = shift;
	if (!$self->{title})
	{
		$self->{title} = [];
	}
	my $title = $self->{title};
	if (@_) 
	{ 
		my $new = shift;
		push (@$title, $new);
	}
	if (wantarray)
	{
		return @$title; 
	}
	else
	{
		return @$title[0];
	}
}

sub url
{ 
	my $self = shift;
	if (!$self->{url})
	{
		$self->{url} = [];
	}
	my $url = $self->{url};
	if (@_) 
	{ 
		my $new = shift;
		push (@$url, $new);
	}
	if (wantarray)
	{
		return @$url; 
	}
	else
	{
		return @$url[0];
	}
}

sub to_hcard
{
	my $self = shift;
	my $ret = "<div class=\"vcard\">\n";
	if ($self->fn) {$ret .= "<div class=\"fn\">".$self->fn."</div>\n"};
	if ($self->n) {$ret .= $self->n->to_hcard};
	if ($self->bday) {$ret .= "<div class=\"bday\">".$self->bday."</div>\n"};
	if ($self->tz) {$ret .= "<div class=\"tz\">".$self->tz."</div>\n"};
	if ($self->geo) {$ret .= $self->geo->to_hcard};
	if ($self->sort_string) {$ret .= "<div class=\"sort-string\">".$self->sort_string."</div>\n"};
	if ($self->uid) {$ret .= "<div class=\"uid\">".$self->uid."</div>\n"};
	if ($self->class) {$ret .= "<div class=\"class\">".$self->class."</div>\n"};
	
	foreach my $t ($self->adr) {if (ref($t) =~ /Data::Microformats/) {$ret .=$t->to_hcard;} else {$ret .= "<div class=\"adr\">".$t."</div>\n"}};
	foreach my $t ($self->agent) {if (ref($t) =~ /Data::Microformats/) {$ret .=$t->to_hcard} else {$ret .= "<div class=\"agent\">".$t."</div>\n"}};
	foreach my $t ($self->category) {if (ref($t) =~ /Data::Microformats/) {$ret .=$t->to_hcard;} else {$ret .= "<div class=\"category\">".$t."</div>\n"}};
	foreach my $t ($self->email) {if (ref($t) =~ /Data::Microformats/) {$ret .=$t->to_hcard;} else {$ret .= "<div class=\"email\">".$t."</div>\n"}};
	foreach my $t ($self->key) {if (ref($t) =~ /Data::Microformats/) {$ret .=$t->to_hcard;} else {$ret .= "<div class=\"key\">".$t."</div>\n"}};
	foreach my $t ($self->label) {if (ref($t) =~ /Data::Microformats/) {$ret .=$t->to_hcard;} else {$ret .= "<div class=\"label\">".$t."</div>\n"}};
	foreach my $t ($self->logo) {if (ref($t) =~ /Data::Microformats/) {$ret .=$t->to_hcard;} else {$ret .= "<div class=\"logo\">".$t."</div>\n"}};
	foreach my $t ($self->mailer) {if (ref($t) =~ /Data::Microformats/) {$ret .=$t->to_hcard;} else {$ret .= "<div class=\"mailer\">".$t."</div>\n"}};
	foreach my $t ($self->nickname) {if (ref($t) =~ /Data::Microformats/) {$ret .=$t->to_hcard;} else {$ret .= "<div class=\"nickname\">".$t."</div>\n"}};
	foreach my $t ($self->note) {if (ref($t) =~ /Data::Microformats/) {$ret .=$t->to_hcard;} else {$ret .= "<div class=\"note\">".$t."</div>\n"}};
	foreach my $t ($self->org) {if (ref($t) =~ /Data::Microformats/) {$ret .=$t->to_hcard;} else {$ret .= "<div class=\"org\">".$t."</div>\n"}};
	foreach my $t ($self->photo) {if (ref($t) =~ /Data::Microformats/) {$ret .=$t->to_hcard;} else {$ret .= "<div class=\"photo\">".$t."</div>\n"}};
	foreach my $t ($self->rev) {if (ref($t) =~ /Data::Microformats/) {$ret .=$t->to_hcard;} else {$ret .= "<div class=\"rev\">".$t."</div>\n"}};
	foreach my $t ($self->role) {if (ref($t) =~ /Data::Microformats/) {$ret .=$t->to_hcard;} else {$ret .= "<div class=\"role\">".$t."</div>\n"}};
	foreach my $t ($self->sound) {if (ref($t) =~ /Data::Microformats/) {$ret .=$t->to_hcard;} else {$ret .= "<div class=\"sound\">".$t."</div>\n"}};
	foreach my $t ($self->tel) {if (ref($t) =~ /Data::Microformats/) {$ret .=$t->to_hcard;} else {$ret .= "<div class=\"tel\">".$t."</div>\n"}};
	foreach my $t ($self->title) {if (ref($t) =~ /Data::Microformats/) {$ret .=$t->to_hcard;} else {$ret .= "<div class=\"title\">".$t."</div>\n"}};
	foreach my $t ($self->url) {if (ref($t) =~ /Data::Microformats/) {$ret .=$t->to_hcard;} else {$ret .= "<div class=\"url\">".$t."</div>\n"}};
	$ret .="</div>\n";
}

1;

__END__

=head1 NAME

Data::Microformats::hCard - A module to parse and create hCards

=head1 VERSION

This documentation refers to Data::Microformats::hCard version 0.0.1.

=head1 SYNOPSIS

	use Data::Microformats::hCard;

	my $card = Data::Microformats::hCard->parse($a_web_page);

	print "The nickname we found in this hCard was:\n";
	print $card->nickname."\n";

	# To create a new hCard:
	my $new_card = Data::Microformats::hCard->new;
	$new_card->fn("Brendan O'Connor");
	$new_card->nickname("USSJoin");

	my $new_email = Data::Microformats::hCard::type;
	$new_email->kind = "email";
	$new_email->type = "Perl";
	$new_email->value = "perl@ussjoin.com";
	$new_card->email($new_email);

	print "Here's the new hCard I've just made:\n";
	print $new_card->to_hcard."\n";

=head1 DESCRIPTION

This module exists both to parse existing hCards from web pages, and to create
new hCards so that they can be put onto the Internet.

To use it to parse an existing hCard (or hCards), simply give it the content
of the page containing them (there is no need to first eliminate extraneous
content, as the module will handle that itself):

	my $card = Data::Microformats::hCard->parse($content);

If you would like to get all the hCards on the webpage, simply ask using an
array:

	my @cards = Data::Microformats::hCard->parse($content);
	
The module respects nested hCards using the parsing rules defined in the spec,
so if one hCard contains another, it will return one hCard with the other held
in the relevant subpart, rather than two top-level hCards.

To create a new hCard, first create the new object:
	
	my $card = Data::Microformats::hCard->new;
	
Then use the helper methods to add any data you would like. When you're ready
to output the hCard, simply write

	my $output = $card->to_hcard;

And $output will be filled with an hCard representation, using <div> tags
exclusively with the relevant class names.

For information on precisely what types of strings are intended for each
hCard property, it is recommended to consult the vCARD specification, RFC 2426.

=head1 SUBROUTINES/METHODS

=head2 Creation/Output Methods

=head3 Data::Microformats::hCard->parse($content)

This method simply takes the content passed in and makes an HTML tree out of
it, then hands it off to the from_tree method to do the actual interpretation.
Should you have an L<HTML::Element|HTML::Element> tree already, there is no 
need to parse the content again; simply pass the tree's root to the from_tree
method.

=head3 Data::Microformats::hCard->from_tree($tree)

This method takes an L<HTML::Element|HTML::Element> tree and finds hCards in
it. It will return one or many hCards (assuming it finds them) depending on
the call; if called in array context, it will return all that it finds, and if
called in scalar context, it will return just one.

The module tries hard not to require absolute adherence to the hCard spec, but
there is only so much flexibility it can have. It does implement all the spec
optimizations (such as the fn and nickname optimizations), for hCards with
less information than might be standard. It does not require that all the
"required" information be present in an hCard-- just that what is there be
reasonably well-formatted, enough to make parsing possible.

=head3 $card->to_hcard

This method, called on an instance of Data::Microformats::hCard, will return
an HTML representation of the hCard data present. This is most likely to be
used when building your own hCards, but can be called on parsed content as
well. The returned hCard is very lightly formatted; it uses only <div> tags
for markup, rather than <span> tags, and is not indented.

=head2 Accessor Methods

=head3 $h->adr([$adr])

This method gets the address(es) of the hCard, which should be L<Data::Microformats::adr|Data::Microformats::adr>
objects. It can also add an additional address to the hCard.

When no parameter is given, this method returns one item if called in scalar
context, and an array of items if called in array context.

hCards can have any number of addresses.

=head3 $h->agent([$agent])

This method gets the agent(s) of the hCard, which can be strings, but are often
hCards themselves. It can also add an additional agent to the card.

When no parameter is given, this method returns one item if called in scalar
context, and an array of items if called in array context.

hCards can have any number of agents.

=head3 $h->bday([$bday])

This method gets/sets the Birthday of the hCard, a string.

hCards can have only one Birthday.

=head3 $h->category([$category])

This method gets the category(ies) of the hCard, which are strings. 
It can also add an additional category to the card.

When no parameter is given, this method returns one item if called in scalar
context, and an array of items if called in array context.

hCards can have any number of categories.

=head3 $h->class([$class])

This method gets/sets the Class of the hCard, a string.

hCards can have only one Class.

=head3 $h->email([$email])

This method gets the email(s) of the hCard, which should be 
L<Data::Microformats::hCard::type|Data::Microformats::hCard::type>
objects with kind = "email". It can also add an additional email to the hCard.

When no parameter is given, this method returns one item if called in scalar
context, and an array of items if called in array context.

hCards can have any number of emails.

=head3 $h->fn([$fn])

This method gets/sets the Familiar Name of the hCard, a string.

hCards can have only one Familiar Name.

=head3 $h->geo([$geo])

This method gets/sets the Geolocation of the hCard, which should be a L<Data::Microformats::geo|Data::Microformats::geo>
object.

hCards can have only one Geolocation.

=head3 $h->key([$key])

This method gets the key(s) of the hCard, which are strings. 
It can also add an additional key to the card.

When no parameter is given, this method returns one item if called in scalar
context, and an array of items if called in array context.

hCards can have any number of keys.

=head3 $h->label([$key])

This method gets the label(s) of the hCard, which are strings. 
It can also add an additional label to the card.

When no parameter is given, this method returns one item if called in scalar
context, and an array of items if called in array context.

hCards can have any number of label.

=head3 $h->logo([$logo])

This method gets the key(s) of the hCard, which are strings. 
It can also add an additional logo to the card. Logos are usually URIs,
according to the spec.

When no parameter is given, this method returns one item if called in scalar
context, and an array of items if called in array context.

hCards can have any number of logos.

=head3 $h->mailer([$mailer])

This method gets the mailer(s) of the hCard, which are strings. 
It can also add an additional mailer to the card.

When no parameter is given, this method returns one item if called in scalar
context, and an array of items if called in array context.

hCards can have any number of mailers.

=head3 $h->n([$n])

This method gets/sets the Name of the hCard, which should be a L<Data::Microformats::hCard::name|Data::Microformats::hCard::name>
object.

hCards can have only one Name.

=head3 $h->nickname([$nickname])

This method gets the nickname(s) of the hCard, which are strings. 
It can also add an additional nickname to the card.

When no parameter is given, this method returns one item if called in scalar
context, and an array of items if called in array context.

hCards can have any number of nicknames.

=head3 $h->note([$note])

This method gets the note(s) of the hCard, which are strings. 
It can also add an additional note to the card.

When no parameter is given, this method returns one item if called in scalar
context, and an array of items if called in array context.

hCards can have any number of notes.

=head3 $h->org([$org])

This method gets the organization(s) of the hCard, which should be 
L<Data::Microformats::hCard::organization|Data::Microformats::hCard::organization>
objects. It can also add an additional organization to the hCard.

When no parameter is given, this method returns one item if called in scalar
context, and an array of items if called in array context.

hCards can have any number of organizations.

=head3 $h->photo([$photo])

This method gets the photo(s) of the hCard, which are strings. 
It can also add an additional photo to the card. Photos are usually URIs,
according to the spec.

When no parameter is given, this method returns one item if called in scalar
context, and an array of items if called in array context.

hCards can have any number of photos.

=head3 $h->rev([$rev])

This method gets the revision(s) of the hCard, which are strings. 
It can also add an additional revision to the card.

When no parameter is given, this method returns one item if called in scalar
context, and an array of items if called in array context.

hCards can have any number of revisions.

=head3 $h->role([$role])

This method gets the role(s) of the hCard, which are strings. 
It can also add an additional note to the card.

When no parameter is given, this method returns one item if called in scalar
context, and an array of items if called in array context.

hCards can have any number of roles.

=head3 $h->sort_string([$sort_string])

This method gets/sets the Sort String of the hCard, a string.

hCards can have only one Sort String.

=head3 $h->sound([$sound])

This method gets the sound(s) of the hCard, which are strings. 
It can also add an additional sound to the card. Sounds are usually URIs,
according to the spec.

When no parameter is given, this method returns one item if called in scalar
context, and an array of items if called in array context.

hCards can have any number of sounds.

=head3 $h->tel([$tel])

This method gets the telephone number(s) of the hCard, which should be 
L<Data::Microformats::hCard::type|Data::Microformats::hCard::type>
objects with kind = "tel". It can also add an additional telephone number to the hCard.

When no parameter is given, this method returns one item if called in scalar
context, and an array of items if called in array context.

hCards can have any number of telephone numbers.

=head3 $h->title([$title])

This method gets the title(s) of the hCard, which are strings. 
It can also add an additional title to the card.

When no parameter is given, this method returns one item if called in scalar
context, and an array of items if called in array context.

hCards can have any number of titles.

=head3 $h->tz([$tz])

This method gets/sets the Time Zone of the hCard, a string.

hCards can have only one Time Zone.

=head3 $h->uid([$uid])

This method gets/sets the Globally Unique Identifier of the hCard, a string.

hCards can have only one UID.

=head3 $h->url([$url])

This method gets the url(s) of the hCard, which are strings. 
It can also add an additional url to the card.

When no parameter is given, this method returns one item if called in scalar
context, and an array of items if called in array context.

hCards can have any number of urls.

=head1 DEPENDENCIES

This module relies upon the following other modules:

L<Data::Microformats::adr|Data::Microformats::adr>

L<Data::Microformats::geo|Data::Microformats::geo>

They are distributed in the same distribution as this module.

It also relies upon:

L<HTML::TreeBuilder|HTML::TreeBuilder>

Which can be obtained from CPAN.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to Brendan O'Connor (perl@ussjoin.com).
Patches are most welcome.

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but without any warranty; without even the
implied warranty of merchantability or fitness for a particular purpose.

=head1 AUTHOR

Brendan O'Connor (perl@ussjoin.com)
