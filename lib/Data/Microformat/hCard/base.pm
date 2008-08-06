package Data::Microformat::hCard::base;

use strict;

our $VERSION = "0.01";

use HTML::TreeBuilder;
use Carp;

sub fields { return { latitude => undef, longitude => undef, }; }

sub new
{
	my $class = shift;
	my %opts  = @_;
	my $fields = ();
	my $singulars = ();
	foreach my $field ($class->singular_fields)
	{
		print STDERR "Adding SINGULAR $field.\n";
		$fields->{$field} = undef;
		$singulars->{$field} = 1;
	}
	foreach my $field ($class->plural_fields)
	{
		print STDERR "Adding PLURAL $field.\n";
		$fields->{$field} = undef;
	}
	
	my $self  = bless { _singulars => $singulars, %$fields, config => {%opts} }, $class;
	$self->_init();
	return $self;
}

sub _init
{
	my $self = shift;
}

our $AUTOLOAD;

sub AUTOLOAD 
{
	my $self = shift;
	my $parameter = shift;
	
	my $name = $AUTOLOAD;
	$name =~ s/.*://;

	my $class_name = $self->class_name;
	
	if (exists $self->{$name})
	{
		if ($self->{_singulars}{$name})
		{
			if ($parameter)
			{
				if (!$self->{$name})
				{
					$self->{$name} = [];
				}
				my $temp = $self->{$name};
				push(@$temp, $parameter);
			}
			else
			{
				if (defined $self->{$name})
				{
					if (wantarray)
					{
						return $self->{$name};
					}
					else
					{
						return $self->{$name}[0];
					}
				}
				else
				{
					return undef;
				}
			}
		}
		else
		{
			if ($parameter)
			{
				$self->{$name} = $parameter;
			}
			else
			{
				return $self->{$name};
			}
		}
	}
	else
	{
		carp(ref($self)." does not have a parameter called $name.\n") unless $name =~ m/DESTROY/;
	}
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

Data::Microformat::hCard::base - A base class for hCards and related modules

=head1 VERSION

This documentation refers to Data::Microformat::hCard::base version 0.01.

=head1 DESCRIPTION

This is the base class used for a variety of modules in Data::Microformat.
It contains several helpful methods to reduce code duplication. It shouldn't
be instantiated on its own (as it won't do anything useful), but can be used
as a base class for other Data::Microformat modules.

=head1 SUBROUTINES/METHODS

=head2 Creation/Output Methods

=head3 Data::Microformat::hCard::base->parse($content)

This method simply takes the content passed in and makes an HTML tree out of
it, then hands it off to the from_tree method to do the actual interpretation.
Should you have an L<HTML::Element|HTML::Element> tree already, there is no 
need to parse the content again; simply pass the tree's root to the from_tree
method.

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