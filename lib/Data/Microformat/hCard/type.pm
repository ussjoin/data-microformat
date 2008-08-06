package Data::Microformat::hCard::type;
use base qw(Data::Microformat::hCard::base);

use strict;

our $VERSION = "0.01";

use HTML::TreeBuilder;

sub from_tree
{
	my $class = shift;
	my $tree = shift;
	
	$tree = $tree->look_down("class", qr/./);
	
	return unless $tree;
	
	my $object = Data::Microformat::hCard::type->new;
	$object->kind($tree->attr('class'));
	my @bits = $tree->content_list;
	
	foreach my $bit (@bits)
	{
		if (ref($bit) eq "HTML::Element")
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
				elsif ($tree->attr('class') =~ m/(email|tel)/ && $bit->tag =~ m/(a|area)/ && $bit->attr('href'))
				{
					$data = $class->_trim($bit->attr('href'));
					$data =~ s/^(mailto|tel)\://;
				}
				$object->$type($data);
			}
		}
		else
		{
			$bit = $class->_trim($bit);
			if (length $bit > 0 && !$object->value)
			{
				$object->value($bit);
			}
		}
	}
	return $object;
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

sub value { my $self = shift; if (@_) { $self->{value} = shift } return $self->{value}; }
sub kind { my $self = shift; if (@_) { $self->{kind} = shift } return $self->{kind}; }

sub to_hcard
{
	my $self = shift;
	my $ret = "<div class=\"".$self->kind."\">\n";
	foreach my $t ($self->type)
	{
		$ret .= "<div class=\"type\">".$t."</div>\n";
	}
	if ($self->value) {$ret .= "<div class=\"value\">".$self->value."</div>\n";}
	$ret .= "</div>\n";
}

1;

__END__

=head1 NAME

Data::Microformat::hCard::type - A module to parse and create typed things within hCards

=head1 VERSION

This documentation refers to Data::Microformat::hCard::type version 0.01.

=head1 DESCRIPTION

This module exists to assist the Data::Microformat::hCard module with handling
typed things (emails and phone numbers) in hCards.

=head1 SUBROUTINES/METHODS

=head2 Creation/Output Methods

=head3 Data::Microformat::hCard::type->parse($content)

This method simply takes the content passed in and makes an HTML tree out of
it, then hands it off to the from_tree method to do the actual interpretation.
Should you have an L<HTML::Element|HTML::Element> tree already, there is no 
need to parse the content again; simply pass the tree's root to the from_tree
method.

=head3 Data::Microformat::hCard::type->from_tree($tree)

This method takes an L<HTML::Element|HTML::Element> tree and finds typed things in
it. It is usually given a tree rooted with a typed thing, but it can be given an
arbitrary tree instead.

=head3 $card->to_hcard

This method, called on an instance of Data::Microformat::hCard::type, will return
an hCard HTML representation of the typed data present. The returned name is very 
lightly formatted; it uses only <div> tags for markup, rather than <span> tags, 
and is not indented.

=head2 Accessor Methods

=head3 $t->type([$type])

This method gets the type(s), which are strings. It can also add an additional
type to the object. It returns one type in scalar context, or an array of all
the types in array context.

=head3 $t->value([$value])

This method gets/sets the value, which is a string.

=head3 $t->kind([$kind])

This method gets/sets the kind ("email" or "tel"), which is a string.

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