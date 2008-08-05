package Data::Microformat::hCard::name;
use base qw(Data::Microformat::hCard::base);

use strict;

use HTML::TreeBuilder;

sub from_tree
{
	my $class = shift;
	my $tree = shift;
	
	$tree = $tree->look_down("class", "n");
	
	return unless $tree;
	
	my $object = Data::Microformat::hCard::name->new;
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
	}
	return $object;
}

sub family_name { my $self = shift; if (@_) { $self->{family_name} = shift } return $self->{family_name}; }
sub given_name { my $self = shift; if (@_) { $self->{given_name} = shift } return $self->{given_name}; }
sub additional_name { my $self = shift; if (@_) { $self->{additional_name} = shift } return $self->{additional_name}; }
sub honorific_prefix { my $self = shift; if (@_) { $self->{honorific_prefix} = shift } return $self->{honorific_prefix}; }
sub honorific_suffix { my $self = shift; if (@_) { $self->{honorific_suffix} = shift } return $self->{honorific_suffix}; }

sub to_hcard
{
	my $self = shift;
	my $ret = "<div class=\"n\">\n";
	if ($self->honorific_prefix) {$ret .= "<div class=\"honorific-prefix\">".$self->honorific_prefix."</div>\n";}
	if ($self->given_name) {$ret .= "<div class=\"given-name\">".$self->given_name."</div>\n";}
	if ($self->additional_name) {$ret .= "<div class=\"additional-name\">".$self->additional_name."</div>\n";}
	if ($self->family_name) {$ret .= "<div class=\"family-name\">".$self->family_name."</div>\n";}
	if ($self->honorific_suffix) {$ret .= "<div class=\"honorific-suffix\">".$self->honorific_suffix."</div>\n";}
	$ret .= "</div>\n";
}

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