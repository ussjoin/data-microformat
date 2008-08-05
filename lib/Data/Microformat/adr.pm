package Data::Microformat::adr;
use base qw(Data::Microformat::hCard::base);

use strict;

use HTML::TreeBuilder;

sub from_tree
{
	my $class = shift;
	my $tree = shift;
	
	my @addresses;
	
	my @address_trees = $tree->look_down("class", "adr");
	
	return unless (@address_trees);
	
	foreach my $adr_tree (@address_trees)
	{
		my $adr = Data::Microformat::adr->new;
		
		my @bits = $adr_tree->descendants;
		
		foreach my $bit (@bits)
		{
			next unless $bit->attr('class');
			
			my @types = split(" ", $bit->attr('class'));
			foreach my $type (@types)
			{
				$type =~ s/\-/\_/g;
				$type = $class->_trim($type);
				my @cons = $bit->content_list;
				
				my $data = $class->_trim($cons[0]);
				if ($bit->tag eq "abbr" && $bit->attr('title'))
				{
					$data = $class->_trim($bit->attr('title'));
				}
				$adr->$type($data);
			}
		}
		push(@addresses, $adr)
	}
	if (wantarray)
	{
		return @addresses;
	}
	else
	{
		return $addresses[0];
	}
}

sub type
{ 
	my $self = shift;
	if (!$self->{type})
	{
		$self->{type} = [];
	}
	my $type = $self->{type};
	
	if (@_) 
	{ 
		my $new = shift;
		push (@$type, $new);
	} 
	if (wantarray)
	{
		return @$type; 
	}
	else
	{
		return @$type[0];
	}
}

sub post_office_box { my $self = shift; if (@_) { $self->{post_office_box} = shift } return $self->{post_office_box}; }
sub extended_address { my $self = shift; if (@_) { $self->{extended_address} = shift } return $self->{extended_address}; }
sub street_address { my $self = shift; if (@_) { $self->{street_address} = shift } return $self->{street_address}; }
sub locality { my $self = shift; if (@_) { $self->{locality} = shift } return $self->{locality}; }
sub region { my $self = shift; if (@_) { $self->{region} = shift } return $self->{region}; }
sub postal_code { my $self = shift; if (@_) { $self->{postal_code} = shift } return $self->{postal_code}; }
sub country_name { my $self = shift; if (@_) { $self->{country_name} = shift } return $self->{country_name}; }

sub to_hcard
{
	my $self = shift;
	my $ret = "<div class=\"adr\">\n";
	foreach my $t ($self->type)
	{
		$ret .= "<div class=\"type\">".$t."</div>\n";
	}
	if ($self->post_office_box) {$ret .= "<div class=\"post-office-box\">".$self->post_office_box."</div>\n";}
	if ($self->street_address) {$ret .= "<div class=\"street-address\">".$self->street_address."</div>\n";}
	if ($self->extended_address) {$ret .= "<div class=\"extended-address\">".$self->extended_address."</div>\n";}
	if ($self->locality) {$ret .= "<div class=\"locality\">".$self->locality."</div>\n";}
	if ($self->region) {$ret .= "<div class=\"region\">".$self->region."</div>\n";}
	if ($self->postal_code) {$ret .= "<div class=\"postal-code\">".$self->postal_code."</div>\n";}
	if ($self->country_name) {$ret .= "<div class=\"country-name\">".$self->country_name."</div>\n";}
	$ret .= "</div>\n";
}

1;

__END__

=head1 NAME

Data::Microformat::adr - A module to parse and create adrs

=head1 VERSION

This documentation refers to Data::Microformat::adr version 0.01.

=head1 SYNOPSIS

	use Data::Microformat::adr;

	my $adr = Data::Microformat::adr->parse($a_web_page);

	print "The street address we found in this adr was:\n";
	print $adr->street_address."\n";

	# To create a new adr:
	my $new_adr = Data::Microformat::adr->new;
	$new_adr->street_address("548 4th St.");
	$new_adr->locality("San Francisco");
	$new_adr->region("CA");
	$new_adr->postal_code("94107");
	$new_adr->country_name("USA");

	print "Here's the new adr I've just made:\n";
	print $new_adr->to_hcard."\n";

=head1 DESCRIPTION

An adr is the address microformat used primarily in hCards. It exists as its
own separate specification.

This module exists both to parse existing adrs from web pages, and to create
new adrs so that they can be put onto the Internet.

To use it to parse an existing adr (or adrs), simply give it the content
of the page containing them (there is no need to first eliminate extraneous
content, as the module will handle that itself):

	my $adr = Data::Microformat::adr->parse($content);

If you would like to get all the adrs on the webpage, simply ask using an
array:

	my @adrs = Data::Microformat::adr->parse($content);

To create a new adr, first create the new object:
	
	my $adr = Data::Microformat::adr->new;
	
Then use the helper methods to add any data you would like. When you're ready
to output the adr in the hCard HTML format, simply write

	my $output = $adr->to_hcard;

And $output will be filled with an hCard representation, using <div> tags
exclusively with the relevant class names.

=head1 SUBROUTINES/METHODS

=head2 Creation/Output Methods

=head3 Data::Microformat::adr->parse($content)

This method simply takes the content passed in and makes an HTML tree out of
it, then hands it off to the from_tree method to do the actual interpretation.
Should you have an L<HTML::Element|HTML::Element> tree already, there is no 
need to parse the content again; simply pass the tree's root to the from_tree
method.

=head3 Data::Microformat::hCard->from_tree($tree)

This method takes an L<HTML::Element|HTML::Element> tree and finds adrs in
it. It will return one or many adrs (assuming it finds them) depending on
the call; if called in array context, it will return all that it finds, and if
called in scalar context, it will return just one.

The module tries hard not to require absolute adherence to the adr spec, but
there is only so much flexibility it can have. It does not require that all the
"required" information be present in an adr-- just that what is there be
reasonably well-formatted, enough to make parsing possible.

=head3 $adr->to_hcard

This method, called on an instance of Data::Microformat::adr, will return
an hCard HTML representation of the adr data present. This is most likely to be
used when building your own adrs, but can be called on parsed content as
well. The returned adr is very lightly formatted; it uses only <div> tags
for markup, rather than <span> tags, and is not indented.

=head2 Accessor Methods

=head3 $a->type([$type])

This method gets the type(s) of address (such as "Home" or "Work"), which is
a string. It can also add a new type to the address.

Adrs can have any number of types.

=head3 $a->post_office_box([$post_office_box])

This method gets/sets the Post Office box of the address, which is a string.

=head3 $a->street_address([$street_address])

This method gets/sets the street address, which is a string.

=head3 $a->extended_address([$extended_address])

This method gets/sets the second line of the address, which is a string.

=head3 $a->locality([$locality])

This method gets/sets the locality/city of the address, which is a string.

=head3 $a->region([$region])

This method gets/sets the region/state of the address, which is a string.

=head3 $a->postal_code([$postal_code])

This method gets/sets the postal code of the address, which is a string.

=head3 $a->country_name([$country_name])

This method gets/sets the country name of the address, which is a string.

=head1 DEPENDENCIES

This module relies upon the following other modules:

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