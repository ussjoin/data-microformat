package Data::Microformat::hCard::organization;
use base qw(Data::Microformat::hCard::base);

use strict;

our $VERSION = "0.01";

use HTML::TreeBuilder;

sub class_name { "org" }
sub plural_fields { qw() }
sub singular_fields { qw(organization_name organization_unit) }

sub from_tree
{
	my $class = shift;
	my $tree = shift;
	
	$tree = $tree->look_down("class", qr/org/);
	
	return unless $tree;
	
	my $object = Data::Microformat::hCard::organization->new;
	my @bits = $tree->content_list;
	
	foreach my $bit (@bits)
	{
		if (ref($bit) eq "HTML::Element")
		{
			next unless $bit->attr('class');
			my @types = split(" ", $bit->attr('class'));
			foreach my $type (@types)
			{
				$type =~ s/\-/\_/;
				$type = $class->_trim($type);
				my @cons = $bit->content_list;
				my $data = $class->_trim($cons[0]);
				if ($bit->tag eq "abbr" && $bit->attr('title'))
				{
					$data = $class->_trim($bit->attr('title'));
				}
				$object->$type($data);
			}
		}
		else
		{
			$bit = $class->_trim($bit);
			if (length $bit > 0)
			{
				$object->organization_name($bit);
			}
		}
	}
	return $object;
}

1;

__END__

=head1 NAME

Data::Microformat::hCard::organization - A module to parse and create orgs within hCards

=head1 VERSION

This documentation refers to Data::Microformat::hCard::organization version 0.01.

=head1 DESCRIPTION

This module exists to assist the Data::Microformat::hCard module with handling
organizations in hCards.

=head1 SUBROUTINES/METHODS

=head2 Creation/Output Methods

=head3 Data::Microformat::organization->parse($content)

This method simply takes the content passed in and makes an HTML tree out of
it, then hands it off to the from_tree method to do the actual interpretation.
Should you have an L<HTML::Element|HTML::Element> tree already, there is no 
need to parse the content again; simply pass the tree's root to the from_tree
method.

=head3 Data::Microformat::organization->from_tree($tree)

This method takes an L<HTML::Element|HTML::Element> tree and finds organizations in
it. It is usually given a tree rooted with a name, but it can be given an
arbitrary tree instead.

=head3 $org->to_hcard

This method, called on an instance of Data::Microformat::hCard::organization, will return
an hCard HTML representation of the name data present. The returned organization is very 
lightly formatted; it uses only <div> tags for markup, rather than <span> tags, 
and is not indented.

=head2 Accessor Methods

=head3 $o->organization_name([$organization_name])

This method gets/sets the organization name, which is a string.

=head3 $o->organization_unit([$organization_unit])

This method gets/sets the organization unit, which is a string.

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