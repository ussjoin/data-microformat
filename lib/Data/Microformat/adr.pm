package Data::Microformat::adr;
use base qw(Data::Microformat::hCard::base);

use strict;

our $VERSION = "0.01";

use HTML::TreeBuilder;

sub class_name { "adr" }
sub plural_fields { qw(type) }
sub singular_fields { qw(post_office_box street_address extended_address locality region postal_code country_name) }

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

=head2 Data

=head3 class_name

The hCard class name for an address; to wit, "adr."

=head3 singular_fields

This is a method to list all the fields on an address that can hold exactly one value.

On address, they are as follows:

=head4 post_office_box

The Post Office box, such as "P.O. Box 1234."

=head4 street_address

The street address, such as "1234 Main St."

=head4 extended_address

The second line of the address, such as "Suite 1."

=head4 locality

The city.

=head4 region

The region/state.

=head4 postal_code

The postal code.

=head4 country_name

The name of the country, such as "U.S.A."

=head3 plural_fields

This is a method to list all the fields on an address that can hold multiple values.

On address, they are as follows:

=head4 type

The type of address, such as "Home" or "Work."

=head1 DEPENDENCIES

This module relies upon the following other modules:

L<HTML::TreeBuilder|HTML::TreeBuilder>

Which can be obtained from CPAN.

=head1 AUTHOR

Brendan O'Connor, C<< <perl at ussjoin.com> >>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-data-microformat at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Microformat>.  I will be
notified,and then you'll automatically be notified of progress on your bug as I
make changes.

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but without any warranty; without even the
implied warranty of merchantability or fitness for a particular purpose.