package Data::Microformat::hFeed;

use strict;
use base qw(Data::Microformat);
use Data::Microformat::hFeed::hEntry;

sub class_name { "hfeed" }
sub singular_fields { qw(title base link tagline description author modified copyright generator) }
sub plural_fields { qw(entries categories) }

sub from_tree {
 	my $class = shift;
    my $tree  = shift;
	my $url   = shift;

	my @feeds;
	foreach my $feed_tree ($tree->look_down('class', qr/hfeed/)) {
		push @feeds, $class->_convert($feed_tree, $url);
	}
	# As per the spec :
    # "the Feed element is optional and, if missing, is assumed to be the page"
	push @feeds, $class->_convert($tree, $url) unless @feeds;

	return wantarray ? @feeds : $feeds[0];
}

sub generator { shift->SUPER::generator(@_) || __PACKAGE__ }

sub _convert {
	my $class = shift;
	my $tree  = shift;
	my $url   = shift;
	my $feed = $class->new;
	if (defined $url) {
		$feed->link($url);
		$feed->base($url);
	}
	my %tags;
	$tree->look_down(sub {
		my $bit = shift;
		my $feed_class = $bit->attr('class') || $bit->attr('rel') || $bit->tag || return 0;
		if (!$feed_class) {
			return 0;
		} elsif (_match($feed_class, 'hentry')) {
			$feed->entries(Data::Microformat::hFeed::hEntry->from_tree($bit, $url));
        } elsif (_match($feed_class, 'feed-title')) {
			$feed->title($bit->as_text);
        } elsif (_match($feed_class, 'title')) {
			$feed->title($bit->as_text);
        } elsif (_match($feed_class, 'feed-tagline')) {
			$feed->tagline($bit->as_text);
        } elsif (_match($feed_class, 'feed-description')) {
			$feed->description($bit->as_text);
		} elsif (_match($feed_class, 'updated')) {
			$feed->modified(_do_date($bit));
		} elsif (_match($feed_class, 'license')) {
			$feed->copyright({ href => $class->_url_decode($bit->attr('href')), text => $bit->as_text });
		} elsif (_match($feed_class,'vcard')) {
			my $card = Data::Microformat::hCard->from_tree($bit, $url);
			$feed->author($card);
		} elsif (_match($feed_class, 'bookmark')) {
			$feed->link($class->_url_decode($bit->attr('href')));
		} elsif (_match($feed_class, 'tag') && _match($feed_class, 'directory')) {
			$feed->categories($bit->as_text);
		} else {
			# print "Unknown class $feed_class\n";
		}
		return 0;
	});
	return $feed;
}

sub _do_date {
	my $element = shift;
	my $title   = $element->attr('title') || return;
	return DateTime::Format::W3CDTF->parse_datetime($title);
}

sub _match {
	my $field  = shift || return 0;
	my $target = shift;
	return $field =~ m!(^|\s)$target(\s|$)!;
}

sub to_html {
	my $feed = shift;

}

1;

__END__

=head1 NAME

Data::Microformat::hFeed - A module to parse and create hFeeds


=head1 SYNOPSIS

    use Data::Microformat::hFeed;

    my $feed = Data::Microformat::hFeed->parse($a_web_page);

	print "Feed title is ".$feed->title;
	print "Feed author is ".$feed->author->fullname;	
	foreach my $entry ($feed->entries) {
		print $entry->title."\n";
	}

	# Create a new feed from scratch
	my $feed = Data::Microformat::hFeed->new;
	$feed->id(rand().time().$$);
	$feed->title("A feedtitle");
	$feed->tagline("Some pithy tagline");
	$feed->description("Somebody did something");
	$feed->modified(DateTime->now);
	$feed->copyright({ href => $url, text => 'Some licence' });
	foreach my $category (qw(cat1 cat2 cat3)) {
		$feed->categoriess($tags);
	}
	$feed->author($hcard);
	$feed->entries($entry);

=head1 DESCRIPTION

An hFeed is a microformat used to contain hEntries.

This module exists both to parse existing hFeedss from web pages, and to create
new hFeeds so that they can be put onto the Internet.

To use it to parse an existing hFeed (or hFeedss), simply give it the content
of the page containing them (there is no need to first eliminate extraneous
content, as the module will handle that itself):

    my $feed = Data::Microformat::hFeed->parse($content);

If you would like to get all the feeds on the webpage, simply ask using an
array:

    my @feeds = Data::Microformat::hFeed->parse($content);

To create a new hFeed, first create the new object:

    my $feed = Data::Microformat::hFeed->new;

Then use the helper methods to add any data you would like. When you're ready
to output in the hFeed HTML format, simply write

    my $output = $feed->to_html;

And $output will be filled with an hFeed representation, using <div> tags
exclusively with the relevant class names.

=head1 SUBROUTINES/METHODS

=head2 class_name

The microformat class name for a feed; to wit, "hfeed"

=head2 singular_fields

This is a method to list all the fields on an address that can hold exactly one value.

=head2 plural_fields

This is a method to list all the fields on an address that can hold multiple values.

=head2 Data::Microformat::organization->from_tree($tree [, $source_url])

This method overrides but provides the same functionality as the
method of the same name in L<Data::Microformat>, with the optional
addition of $source_url. If present, this latter term will set the link
and the base of the feed automatically.

=head2 id

The id of this feed.

=head2 title

The title of this feed.

=head2 base

The base of this feed if available.

=head2 link

The permalink of this feed.

=head2 tagline

The tagline of this feed if available.

=head2 description

The description of this feed if available.

=head2 modified

When this feed was modified - returns a DateTime object.

=head2 copyright

Returns a hash ref containing the copyright information for this feed.

The hash ref may have any or all of the following keys: C<text>, C<href>.

=head2 generator

The name of the feed generator.

=head2 categories

All the categories for this feed.

=head2 author

The author of this feed. Returns a L<Data::Microformat::hCard|Data::Microformat::hCard> object.

=head2 entries

The entries for this feed. Returns L<Data::Microformat::hFeed::hEntry|Data::Microformat::hFeed::hEntry> objects.

=head2 to_html

Return this hFeed as HTML

=head1 BUGS

Please report any bugs or feature requests to
C<bug-data-microformat at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Microformat>.  I will be
notified,and then you'll automatically be notified of progress on your bug as I
make changes.

=head1 AUTHOR

Simon Wistow, C<< <swistow@sixapart.com> >>

=head1 COPYRIGHT

Copyright 2008, Six Apart Ltd. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but without any warranty; without even the
implied warranty of merchantability or fitness for a particular purpose.

=cut
