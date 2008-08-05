package Data::Microformats::hCard::base;

use strict;

use HTML::TreeBuilder;

sub new
{
	my $class = shift;
	my %opts  = @_;
	my $self  = bless { config => {%opts} }, $class;
	$self->_init();
	return $self;
}

sub _init
{
	my $self = shift;
}

sub parse
{
	my $class = shift;
	my $content = shift;
	my $tree = HTML::TreeBuilder->new_from_content($content);
	$tree->elementify;
	
	if (wantarray)
	{
		my @ret = $class->from_tree($tree);
		$tree->delete;
		return @ret;
	}
	else
	{
		my $ret = $class->from_tree($tree);
		$tree->delete;
		return $ret;		
	}
}

sub _trim
{
	my $class = shift;
	my $content = shift;
	if ($content)
	{
		$content =~ s/^\s//;
		$content =~ s/\s$//;
	}
	return $content;
}

sub from_tree
{
	die("Subclass has not implemented from_tree\n");
}

sub to_hcard
{
	die("Subclass has not implemented to_hcard\n");
}

1;

__END__

=head1 NAME

Data::Microformats::hCard::base - A base class for hCards and related modules

=head1 VERSION

This documentation refers to Data::Microformats::hCard::base version 0.0.1.

=head1 DESCRIPTION

This is the base class used for a variety of modules in Data::Microformats.
It contains several helpful methods to reduce code duplication. It shouldn't
be instantiated on its own (as it won't do anything useful), but can be used
as a base class for other Data::Microformats modules.

=head1 SUBROUTINES/METHODS

=head2 Creation/Output Methods

=head3 Data::Microformats::hCard::base->parse($content)

This method simply takes the content passed in and makes an HTML tree out of
it, then hands it off to the from_tree method to do the actual interpretation.
Should you have an L<HTML::Element|HTML::Element> tree already, there is no 
need to parse the content again; simply pass the tree's root to the from_tree
method.

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