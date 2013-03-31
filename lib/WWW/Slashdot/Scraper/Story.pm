package WWW::Slashdot::Scraper::Story;

use Moose;
use MooseX::Method::Signatures;

use MooseX::Types::DateTime;

use HTML::TreeBuilder;

use WWW::Slashdot::Scraper::Login::Anon;
use WWW::Slashdot::Scraper::CommentContainer;

has story_url => (
	is => 'rw',
	isa => 'Str',
	required => 1,
);

has canonical_uri => (
	is => 'ro',
	isa => 'URI',
	lazy => 1,
	builder => '_build_canonical_uri',
);

has title => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	builder => '_build_title',
);

has article_text => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	builder => '_build_article_text',
);

has article_HTML => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	builder => '_build_article_HTML',
);

has _article_tree => (
	is => 'ro',
	isa => 'HTML::Element',
	lazy => 1,
	builder => '_build_article_tree',
);

# robotics, etc.
has category => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	lazy => 1,
	builder => '_build_category',
);

# main, yro, games, etc.
has section => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	builder => '_build_section',
);

has topic => (
	is => 'ro',
	isa => 'ArrayRef[HashRef]',
	lazy => 1,
	builder => '_build_topic',
);


has discussion_id => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	builder => '_build_discussion_id',
);

# 
# <http://slashdot.org/~countertrolling/journal/267642>
# No comments: <http://slashdot.org/journal/128495/Tell-CongressWIPO-No-Bcast-Treaty-Without-Representation>
# Comments: <http://slashdot.org/journal/124853/Thanks-rodgster>
# journal, story
has type => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	builder => '_build_type',
);

has tag => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	lazy => 1,
	builder => '_build_tag',
);

has byline => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	builder => '_build_byline',
);

has comment_container => (
	is => 'ro',
	isa => 'WWW::Slashdot::Scraper::CommentContainer',
	lazy => 1,
	builder => '_build_comment_container',
);

has datetime => (
	is => 'ro',
	isa => 'DateTime',
	lazy => 1,
	builder => '_build_datetime',
);

has _html_content => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	builder => '_build_html_content',
);

has _http_response => (
	is => 'ro',
	isa => 'HTTP::Response',
	lazy => 1,
	builder => '_build_http_response',
);

has _tree => (
	is => 'ro',
	isa => 'HTML::TreeBuilder',
	lazy => 1,
	builder => '_build_tree',
);

has login => (
	is => 'rw',
	isa => 'WWW::Slashdot::Scraper::Login',
	default => sub {
		return WWW::Slashdot::Scraper::Login::Anon->new();
	}
);

method _build_title {
	return $self->_tree
		->look_down( _tag => 'span', id => qr/^title-\d+$/ )
		->as_trimmed_text(extra_chars => '\xA0');
}

method _build_article_text {
	return $self->_article_tree
		->as_trimmed_text(extra_chars => '\xA0');
}

method _build_article_HTML {
	$self->_article_tree->as_HTML;
}

method _build_article_tree {
	$self->_tree
		->look_down( _tag => 'div', class => 'body')
}

method _build_http_response {
	$self->login->mech->get($self->story_url);
}

method _build_html_content {
	$self->_http_response->content();
}

method _build_category {
	return "TODO";
}

method _build_section {
	my @parts = split /\./, $self->canonical_uri->host;
	my $first = shift @parts;
	return "main" if( $first eq 'slashdot' );
	return $first;
}

# TODO
method _build_type {

}

# TODO
method _build_byline {

}

method _build_tree {
	HTML::TreeBuilder->new_from_content( $self->_html_content );
}

method _build_datetime {
	my $time = $self->_tree->look_down( id => qr/^details-\d+/ )->as_HTML;
	$time =~ s/.*on\s*(.*?)\s*<br.*/$1/s;
	$time =~ s/,\s*@/ /;
	return $self->login->datetime->get_datetime($time);
}

method _build_canonical_uri {
	$self->_http_response->base;
}

method _build_tag {
	my $tags = [
		grep { length $_ }
		map {
			my $tag;
			if( defined ( $tag = $_->attr('href') ) ) {
				$tag =~ s,^/tag/,,;
				$tag;
			}
		}
		( $self->_tree
			->look_down( _tag => 'span', id => qr/^tagbar-\d+$/ )
			->look_down( _tag => 'a' ) )
	];
	return $tags;
}

method _build_topic {
	my $topic_info = [ map {
		my $topic_img = $_->look_down( _tag => 'img' );
		my $uri = URI->new( $topic_img->attr('src') );
		$uri->scheme("http");
		{
			image_URI => $uri,
			name => $topic_img->attr('title'),
		}
	} ( $self->_tree
		->look_down( _tag => 'span', class => 'topic')
		->look_down( _tag => 'a') ) ];
}

method _build_comment_container {
	return WWW::Slashdot::Scraper::CommentContainer->new( story => $self );
}

method _build_discussion_id {
	my $content = $self->_html_content;
	($content =~ /D2.discussion_id\(([^)]*)\);/)[0];
}

no Moose;
__PACKAGE__->meta->make_immutable;
