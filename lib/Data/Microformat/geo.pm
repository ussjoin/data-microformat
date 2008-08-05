package Data::Microformat::geo;
use base qw(Data::Microformat::hCard::base);

use strict;

our $VERSION = "0.01";

use HTML::TreeBuilder;

sub from_tree
{
	my $class = shift;
	my $tree = shift;

	my @geo_trees = $tree->look_down("class", "geo");
	
	return unless @geo_trees;
	
	my @geos;
	
	foreach my $geo_tree (@geo_trees)
	{
		my $geo = Data::Microformat::geo->new;
		my @bits = $geo_tree->descendants;
	
		foreach my $bit (@bits)
		{
			next unless $bit->attr('class');
			my @types = split(" ", $bit->attr('class'));
			foreach my $type (@types)
			{
				$type = $class->_trim($type);
				my @cons = $bit->content_list;
				my $data = $class->_trim($cons[0]);
				if ($bit->tag eq "abbr" && $bit->attr('title'))
				{
					$data = $class->_trim($bit->attr('title'));
				}
				$geo->$type($data);
			}
		}
		push(@geos, $geo);
	}
	
	if (wantarray)
	{
		return @geos;
	}
	else
	{
		return $geos[0];
	}

}

sub latitude { my $self = shift; if (@_) { $self->{latitude} = shift } return $self->{latitude}; }
sub longitude { my $self = shift; if (@_) { $self->{longitude} = shift } return $self->{longitude}; }

sub to_hcard
{
	my $self = shift;
	my $ret = "<div class=\"geo\">\n";
	if ($self->latitude) {$ret .= "<div class=\"latitude\">".$self->latitude."</div>\n";}
	if ($self->longitude) {$ret .= "<div class=\"longitude\">".$self->longitude."</div>\n";}
	$ret .= "</div>\n";
}

1;

__END__

=head1 NAME

Data::Microformat::geo - A module to parse and create geos

=head1 VERSION

This documentation refers to Data::Microformat::geo version 0.01.

=head1 SYNOPSIS

	use Data::Microformat::geo;

	my $geo = Data::Microformat::geo->parse($a_web_page);

	print "The latitude we found in this geo was:\n";
	print $adr->latitude."\n";
	
	print "The longitude we found in this geo was:\n";
	print $adr->longitude."\n";

	# To create a new geo:
	my $new_geo = Data::Microformat::geo->new;
	$new_adr->latitude("37.779598");
	$new_adr->longitude("-122.398453");

	print "Here's the new adr I've just made:\n";
	print $new_adr->to_hcard."\n";

=head1 DESCRIPTION

A geo is the geolocation microformat used primarily in hCards. It exists as its
own separate specification.

This module exists both to parse existing geos from web pages, and to create
new geos so that they can be put onto the Internet.

To use it to parse an existing geo (or geos), simply give it the content
of the page containing them (there is no need to first eliminate extraneous
content, as the module will handle that itself):

	my $geo = Data::Microformat::geo->parse($content);

If you would like to get all the geos on the webpage, simply ask using an
array:

	my @geos = Data::Microformat::geo->parse($content);

To create a new geo, first create the new object:
	
	my $geo = Data::Microformat::geo->new;
	
Then use the helper methods to add any data you would like. When you're ready
to output the geo in the hCard HTML format, simply write

	my $output = $geo->to_hcard;

And $output will be filled with an hCard representation, using <div> tags
exclusively with the relevant class names.

=head1 SUBROUTINES/METHODS

=head2 Creation/Output Methods

=head3 Data::Microformat::geo->parse($content)

This method simply takes the content passed in and makes an HTML tree out of
it, then hands it off to the from_tree method to do the actual interpretation.
Should you have an L<HTML::Element|HTML::Element> tree already, there is no 
need to parse the content again; simply pass the tree's root to the from_tree
method.

=head3 Data::Microformat::geo->from_tree($tree)

This method takes an L<HTML::Element|HTML::Element> tree and finds geos in
it. It will return one or many geos (assuming it finds them) depending on
the call; if called in array context, it will return all that it finds, and if
called in scalar context, it will return just one.

The module tries hard not to require absolute adherence to the geo spec, but
there is only so much flexibility it can have. It does not require that all the
"required" information be present in an geo-- just that what is there be
reasonably well-formatted, enough to make parsing possible.

=head3 $card->to_hcard

This method, called on an instance of Data::Microformat::geo, will return
an hCard HTML representation of the geo data present. This is most likely to be
used when building your own geos, but can be called on parsed content as
well. The returned geo is very lightly formatted; it uses only <div> tags
for markup, rather than <span> tags, and is not indented.

=head2 Accessor Methods

=head3 $g->latitude([$latitude])

This method gets/sets the latitude of the geo, which is a string.

=head3 $g->longitude([$longitude])

This method gets/sets the longitude of the geo, which is a string.


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