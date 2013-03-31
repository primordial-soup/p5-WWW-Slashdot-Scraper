package WWW::Slashdot::Scraper::CommentTree;

use Moose;

has child_comment_count => (
	is => 'ro',
	isa => 'Int',
	lazy => 1,
	builder => '_build_child_comment_count',
);

sub _build_child_comment_count {
	my $self = shift;
	my $count = 0;
	$self->traverse(sub { $count++; });
	return $count;
}

extends 'Forest::Tree';

no Moose;
__PACKAGE__->meta->make_immutable;
