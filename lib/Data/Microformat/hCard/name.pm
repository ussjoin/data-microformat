package Data::Microformat::hCard::name;
use base qw(Data::Microformat::hCard::base);

use strict;

our $VERSION = "0.01";

use HTML::TreeBuilder;

sub class_name { "n" }
sub plural_fields { qw() }
sub singular_fields { qw(honorific_prefix given_name additional_name family_name honorific_suffix) }

1;

__END__

=head1 NAME

Data::Microformat::hCard::name - A module to parse and create names within hCards

=head1 VERSION

This documentation refers to Data::Microformat::hCard::name version 0.01.

=head1 DESCRIPTION

This module exists to assist the Data::Microformat::hCard module with handling
names in hCards.

=head1 SUBROUTINES/METHODS

=head2 Creation/Output Methods

=head3 Data::Microformat::hCard::name->parse($content)

This method simply takes the content passed in and makes an HTML tree out of
it, then hands it off to the from_tree method to do the actual interpretation.
Should you have an L<HTML::Element|HTML::Element> tree already, there is no 
need to parse the content again; simply pass the tree's root to the from_tree
method.

=head3 Data::Microformat::hCard::name->from_tree($tree)

This method takes an L<HTML::Element|HTML::Element> tree and finds names in
it. It is usually given a tree rooted with a name, but it can be given an
arbitrary tree instead.

=head3 $name->to_hcard

This method, called on an instance of Data::Microformat::hCard::name, will return
an hCard HTML representation of the name data present. The returned name is very 
lightly formatted; it uses only <div> tags for markup, rather than <span> tags, 
and is not indented.

=head2 Accessor Methods

=head3 $n->family_name([$family_name])

This method gets/sets the family name, which is a string.

=head3 $n->given_name([$given_name])

This method gets/sets the given name, which is a string.

=head3 $n->additional_name([$additional_name])

This method gets/sets the additional name (such as a middle name), which is a string.

=head3 $n->honorific_prefix([$honorific_prefix])

This method gets/sets the honorific prefix (such as "Dr."), which is a string.

=head3 $n->honorific_suffix([$honorific_suffix])

This method gets/sets the honorific suffix (such as "Ph.D."), which is a string.

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