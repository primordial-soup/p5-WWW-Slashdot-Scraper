package WWW::Slashdot::Scraper::CommentTreeBuilder;

use Moose;
use HTML::TreeBuilder;
use WWW::Slashdot::Scraper::CommentTree;
use WWW::Slashdot::Scraper::Comment;
use JSON;

has story => (
	is => 'rw',
	isa => 'WWW::Slashdot::Scraper::Story',
	required => 1,
);

has _tree => (
	is => 'ro',
	isa => 'HTML::TreeBuilder',
	lazy => 1,
	builder => '_build_tree',
);

sub _build_tree {
	my $self = shift;
	$self->story->_tree;
}

# <div class="commentBody">
#  <div class="comment_body_\d+">
#  </div>
#  <div class="comment_sig_\d+">
#  --<br>
#  </div>
# </div>
sub build_tree_html {
	my $self = shift;
	my $comment_listing = $self->_tree->look_down(_tag => 'ul', id => 'commentlisting');
	my @comment_trees = $comment_listing->content_list;
	my $ctree = WWW::Slashdot::Scraper::CommentTree->new( node => $self->story );
	for my $c (@comment_trees) { $ctree->add_children($self->_build_tree_r_html($c,0)); }
	return $ctree;
}

sub _build_tree_r_html {
	my $self = shift;
	my $comment_tree = shift;
	my $depth = shift;
	my $tree = WWW::Slashdot::Scraper::CommentTree->new();
	my @generation = ();
	for my $desc ($comment_tree->content_list) {
		if(ref $desc) {
			if( ($desc->attr('id') // '') =~ /comment_(\d+)/) {
				my $cid = $1;
				my $comment_title = $desc->look_down( _tag => 'div', class => 'title' );
				next unless defined $comment_title;
				my $comment_title_txt = $comment_title->as_trimmed_text(extra_chars => '\xA0');
				my $comment = WWW::Slashdot::Scraper::Comment->new( title => $comment_title_txt,
					cid => $cid,
			       		story => $self->story );
				push @generation, WWW::Slashdot::Scraper::CommentTree->new( node => $comment );
				#print( ($depth > 0)? (("  " x ($depth-1)) . "↳ "):(""),"$comment_title_txt ($cid)\n");
			} elsif( ($desc->attr('id') // '') =~ /commtree_(\d+)/ ) {
				my @comment_trees = $desc->content_list;
				#print  "  " x $depth, $desc->tag , ":" ,  ( $desc->attr('id') // "(noattr)") , "\n";
				if(@generation) {
					for my $c (@comment_trees) { $generation[-1]->add_children( $self->_build_tree_r_html( $c, $depth + 1) ); }
				}
			}
		}
	}
	return @generation;
}

no Moose;
__PACKAGE__->meta->make_immutable;
