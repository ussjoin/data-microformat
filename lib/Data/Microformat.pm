package Data::Microformat;

use strict;
use warnings;

our $VERSION = "0.03";

our $AUTOLOAD;

use HTML::Entities;
use HTML::TreeBuilder;
use HTML::Stream qw(html_escape);
use Carp;

sub new
{
	my $class = shift;
	my %opts  = @_;
	my $fields = ();
	my $singulars = ();
	foreach my $field ($class->singular_fields)
	{
		$fields->{$field} = undef;
		$singulars->{$field} = 1;
	}
	foreach my $field ($class->plural_fields)
	{
		$fields->{$field} = undef;
	}
	
	my $class_name = $class->class_name;
	
	my $self  = bless { _class_name => $class_name, _singulars => $singulars, %$fields, config => {%opts} }, $class;
	$self->_init();
	return $self;
}

sub _init
{
	my $self = shift;
}

sub AUTOLOAD 
{
	my $self = shift;
	my $parameter = shift;
	
	my $name = $AUTOLOAD;
	$name =~ s/.*://;

	my $class_name = $self->{_class_name};
	
	if (exists $self->{$name})
	{
		if (!$self->{_singulars}{$name})
		{
			if ($parameter)
			{
				if (!$self->{$name})
				{
					$self->{$name} = [];
				}
				my $temp = $self->{$name};
				$parameter =~ s/^\s//;
				$parameter =~ s/\s$//;
				push(@$temp, $parameter);
			}
			else
			{
				if (defined $self->{$name})
				{
					my $temp = $self->{$name};
					if (wantarray)
					{
						return @$temp;
					}
					else
					{
						return @$temp[0];
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
				if (!defined $self->{$name}) # Drop all but the first saved singular thing
				{
					$parameter =~ s/^\s//;
					$parameter =~ s/\s$//;
					$self->{$name} = $parameter;
				}
			}
			else
			{
				return $self->{$name};
			}
		}
	}
	else
	{
		# warn(ref($self)." does not have a parameter called $name.\n") unless $name =~ m/DESTROY/;
		# Do nothing here, as there's no need to warn that some parts of hCards aren't valid
	}
}

sub parse
{
	my $class = shift;
	my $content = shift;
	my $representative_url = shift;
	
	# These few transforms allow us to decode "psychotic" encodings, see t/03type.t for details
	$content =~ tr/+/ /;
	$content =~ s/%([a-fA-F0-9]{2,2})/chr(hex($1))/eg;
	$content =~ s/<!–(.|\n)*–>//g;
	decode_entities($content);
	$content =~ s/%(..)/pack("C",hex($1))/eg;
	
	my $tree = HTML::TreeBuilder->new_from_content($content);
	$tree->elementify;
	
	if (wantarray)
	{
		my @ret = $class->from_tree($tree, $representative_url);
		$tree->delete;
		return @ret;
	}
	else
	{
		my $ret = $class->from_tree($tree, $representative_url);
		$tree->delete;
		return $ret;		
	}
}

sub from_tree
{
	my $class = shift;
	my $tree = shift;
	
	my @objects;
	my $class_name = $class->class_name;
	my @object_trees = $tree->look_down("class", qr/(^|\s)$class_name($|\s)/);
	
	return unless (@object_trees);
	
	foreach my $object_tree (@object_trees)
	{
		my $object = $class->new;
		
		my @bits = $object_tree->descendants;
		
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
				$object->$type($data);
			}
		}
		push(@objects, $object)
	}
	if (wantarray)
	{
		return @objects;
	}
	else
	{
		return $objects[0];
	}
}

sub to_hcard
{
	my $self  = shift;
	
	my $tree = $self->_to_hcard_elements;
	my $ret = $tree->as_HTML('<>&', "\t", { });
	$tree->delete;
	
	return $ret;
}

sub to_text
{
	my $self  = shift;
	
	my $tree = $self->_to_hcard_elements;
	my $ret = _as_text($tree);
	$tree->delete;
	
	return $ret;
}

sub _as_text
{
	my $tree = shift;
	
	if (scalar $tree->descendants == 0)
	{
		return $tree->attr('class').": ".$tree->as_text;
	}
	
	my $ret = $tree->attr('class').": \n";
	
	foreach my $child ($tree->content_list)
	{
		next unless (ref($child) =~ m/HTML::Element/);		
		my $temp = _as_text($child);
		$temp .= "\n" unless ($temp =~ m/\n$/s);
		$temp =~ s/^/\t/gm;
		$ret .= $temp;
	}
	return $ret;
}

sub _to_hcard_elements
{
	my $self  = shift;
	
	my $class_name = $self->{_class_name};
	
	if (defined $self->{kind})
	{
		$class_name = $self->{kind};
	}
	my $root = HTML::Element->new('div', class => $class_name);
	for my $field ($self->singular_fields)
	{
		next unless defined $self->{$field};
		next if ($field eq "kind");
		if (ref($self->{$field}) =~ m/Data::Microformat/)
		{
			# Then take the return and root it to our root
			my $child = $self->{$field}->_to_hcard_elements;
			if ($child->attr('class') eq "vcard")
			{
				$child->attr('class', $field." vcard"); # Since we know it's a vcard
			}
			$root->push_content($child);
		}
		else
		{
			my $name = $field;
			$name =~ tr/_/-/;
			my $child = HTML::Element->new('div', class => $name);
			$child->push_content($self->{$field});
			$root->push_content($child);
		}
	}
	for my $field ($self->plural_fields)
	{
		next unless defined $self->{$field};
		my $name = $field;
		$name =~ tr/_/-/;
		my $fields = $self->{$field};
		foreach my $value (@$fields)
		{
			if (ref($value) =~ m/Data::Microformat/)
			{
				# Then take the return and root it to our root
				my $child = $value->_to_hcard_elements;
				if ($child->attr('class') eq "vcard")
				{
					$child->attr('class', $field." vcard"); # Since we know it's a vcard
				}
				$root->push_content($child);
			}
			else
			{
				my $child = HTML::Element->new('div', class => $name);
				$child->push_content($value);
				$root->push_content($child);
			}
		}
	}
	return $root;
}

sub _trim
{
	my $class = shift;
	my $content = shift;
	
	if ($content)
	{
		$content =~ s/^\s+//;
		$content =~ s/\s+$//;
	}
	return $content;
}

sub _remove_newlines
{
	my $class = shift;
	my $content = shift;
	if ($content)
	{
		$content =~ s/\n/ /g;
		$content =~ s/\r/ /g;
	}
	return $content;
}

1;

__END__

=head1 NAME

Data::Microformat - A base class for hCards and related modules

=head1 VERSION

This documentation refers to Data::Microformat version 0.03.

=head1 DESCRIPTION

This is the base class used for a variety of modules in Data::Microformat.
It contains several helpful methods to reduce code duplication. It shouldn't
be instantiated on its own (as it won't do anything useful), but can be used
as a base class for other Data::Microformat modules.

=head1 SUBROUTINES/METHODS

=head2 Data::Microformat->new

This method creates a new instance of whatever subclass on which it was called.

This method should not be called directly on Data::Microformat, as
it will not be particularly useful.

=head2 Data::Microformat->parse($content [, $url])

This method simply takes the content passed in and makes an HTML tree out of
it, then hands it off to the from_tree method to do the actual interpretation.
Should you have an L<HTML::Element|HTML::Element> tree already, there is no 
need to parse the content again; simply pass the tree's root to the from_tree
method.

If you are calling this method on the hCard class, you can pass an additional
parameter of the source URL, and this will allow the representative hCard to be
determined. This parameter is optional.

=head2 Data::Microformat->from_tree($tree)

This method takes an L<HTML::Element|HTML::Element> tree and finds microformats in
it. It will return one or many of the calling class (assuming it finds them) depending on
the call; if called in array context, it will return all that it finds, and if
called in scalar context, it will return just one.

The module tries hard not to require absolute adherence to the published specifications, but
there is only so much flexibility it can have. It does not require that all the
"required" information be present in a microformat-- just that what is there be
reasonably well-formatted, enough to make parsing possible.

Certain modules may override this if they have specific parsing concerns.

=head2 $base->to_hcard

This method, called on an instance of Data::Microformat or its subclasses, will return
an hCard HTML representation of the data present. This is most likely to be
used when building your own microformatted data, but can be called on parsed content as
well. The returned data is very lightly formatted, and it uses only <div> tags
for markup, rather than <span> tags.

=head2 $base->to_text

This method, called on an instance of Data::Microformat or its subclasses, will return
a plain text representation of the data present. This format uses indentation to show nesting,
and attempts to be easily human-readable.

=head1 DEPENDENCIES

This module relies upon the following other modules:

L<HTML::Entities|HTML::Entities>

L<HTML::TreeBuilder|HTML::TreeBuilder>

L<HTML::Stream|HTML::Stream>

Which can be obtained from CPAN.

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-data-microformat at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Microformat>.  I will be
notified,and then you'll automatically be notified of progress on your bug as I
make changes.

=head1 AUTHOR

Brendan O'Connor, C<< <perl at ussjoin.com> >>

=head1 COPYRIGHT

Copyright 2008, Six Apart Ltd. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but without any warranty; without even the
implied warranty of merchantability or fitness for a particular purpose.