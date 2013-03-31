package WWW::Slashdot::Scraper::CommentContainer;

use Moose;
use MooseX::Method::Signatures;

use JSON -support_by_pp;
use Scalar::Util qw/looks_like_number/;

use WWW::Slashdot::Scraper::CommentTree;
use WWW::Slashdot::Scraper::Comment;

has story => (
	is => 'ro',
	isa => 'WWW::Slashdot::Scraper::Story',
	required => 1,
);

has _tree => (
	is => 'ro',
	isa => 'HTML::TreeBuilder',
	lazy => 1,
	builder => '_build_tree',
);

has login => (
	is => 'ro',
	isa => 'WWW::Slashdot::Scraper::Login',
	lazy => 1,
	builder => '_build_login',
);

has comment_tree => (
	is => 'rw',
	isa => 'WWW::Slashdot::Scraper::CommentTree',
	lazy => 1,
	clearer   => '_clear_comment_tree',
	builder => '_build_comment_tree',
);

has comment_count => (
	is => 'rw',
	isa => 'Int',
	lazy => 1,
	builder => '_build_comment_count',
);

has _data => (
	is => 'ro',
	isa => 'HashRef',
	lazy => 1,
	builder => '_build_data',
);

has comment_hash => (
	is => 'rw',
	isa => 'HashRef',
	default => sub { {} },
);

has _root_comments_hash => (
	is => 'rw',
	isa => 'HashRef',
);

has _root_comments => (
	is => 'rw',
	isa => 'ArrayRef',
);

has _comments => (
	is => 'rw',
	isa => 'HashRef',
);

method update {
	$self->_init_comments unless $self->_comments;
	my $response = $self->login->mech->post(
		"http://slashdot.org/ajax.pl",
		{ abbreviated => '',
		  d2_seen => $self->_data->{d2_seen},
		  discussion_id => $self->_data->{discussion_id},
		  fetch_all => 1,
		  highlightthresh => $self->_data->{user_highlightthresh},
		  op => 'comments_fetch',
		  pieces => '',
		  threshold => $self->_data->{user_threshold}});
		 # fetch_num => 500
	#use DDP;p $response->decoded_content;
	#my $update = decode_json($self->_fix_json($response->decoded_content));
	return -1 unless $response->decoded_content;
	my $update = $self->_json($response->decoded_content);
	#use DDP;p $update;
	my $update_data = $self->_eval_data( $update->{eval_first} );
	#use DDP; p $self->_data;
	#use DDP; p $update_data;
	for my $update_data_k (keys $update_data) {
		$self->_data->{$update_data_k} = $update_data->{$update_data_k}
	}
	#use DDP; p $self->_data;
	#use DDP;p $update_data;
	$self->comment_count($update->{update_data}{totalcommentcnt})
		if defined $update->{update_data}{totalcommentcnt};
	if(defined $update->{update_data}{new_cids_data}) {
		for my $i (0..@{$update->{update_data}{new_cids_order}}-1) {
			my $cid = $update->{update_data}{new_cids_order}[$i];
			my $cid_data = $update->{update_data}{new_cids_data}[$i];
			my $pid = $cid_data->{pid};
			$self->_comments->{$cid} = $cid_data;
			if( $pid == 0 ) {
				unless(defined $self->_root_comments_hash->{$cid}) {
					push @{$self->_root_comments}, $cid;
					$self->_root_comments_hash->{$cid} = 1;
				}
			} else {
				push @{$self->_comments->{$pid}{kids}}, $cid
					unless grep {$_ == $cid} @{$self->_comments->{$pid}{kids}};
			}
		}
		$self->_clear_comment_tree;
		$self->_update_comments;
		my %comment = %{$self->comment_hash};
		for my $comment_key (keys $update->{html}) {
			my $cid = ($comment_key =~ /comment_(\d+)/)[0];
			next unless $cid;
			my $comment_content = $update->{html}{$comment_key};
			my $tree = HTML::TreeBuilder->new;
			$tree->parse($comment_content);
			$comment{$cid}->node->parse_content($tree);
		}
	}
	return $self->_data->{updateMoreNum} // 0;
}

sub _build_tree {
	my $self = shift;
	$self->story->_tree;
}

method _build_data {
	my $content = $self->story->_html_content;
	return $self->_eval_data($content);
}

method _eval_data($content) {
	my $data;
	$data->{d2_comment_order} = ($content =~ /D2.d2_comment_order\(([^)]*)\);/)[0];
	$data->{user_uid} = ($content =~ /D2.user_uid\(([^)]*)\);/)[0];
	$data->{user_is_anon} = ($content =~ /D2.user_is_anon\(([^)]*)\);/)[0];
	$data->{user_is_admin} = ($content =~ /D2.user_is_admin\(([^)]*)\);/)[0];
	$data->{user_is_subscriber} = ($content =~ /D2.user_is_subscriber\(([^)]*)\);/)[0];
	$data->{user_smallscreen} = ($content =~ /D2.user_smallscreen\(([^)]*)\);/)[0];
	$data->{user_threshold} = ($content =~ /D2.user_threshold\(([^)]*)\);/)[0];
	$data->{user_highlightthresh} = ($content =~ /D2.user_highlightthresh\(([^)]*)\);/)[0];
	$data->{user_d2asp} = ($content =~ /D2.user_d2asp\(([^)]*)\);/)[0];
	$data->{discussion_id} = ($content =~ /D2.discussion_id\(([^)]*)\);/)[0];
	$data->{d2_seen} = ($content =~ /D2.d2_seen\('([^)]*)'\);/)[0];
	$data->{more_comments_num} = ($content =~ /D2.more_comments_num\(([^)]*)\);/)[0] // 0;
	$data->{updateMoreNum} = ($content =~ /D2.updateMoreNum\(([^)]*)\);/)[0] // 0;
	delete $data->{$_} for grep {not defined $data->{$_}} keys $data;
	return $data;
}

method _build_comment_count {
	my $count = $self->_tree
		->look_down( _tag => 'span', class => qr/^comments commentcnt-\d+$/ )
		->as_trimmed_text(extra_chars => '\xA0');
	$count = 0 unless looks_like_number $count;
	return $count;
}

method _build_login {
	return $self->story->login;
}

sub _build_comment_tree {
	#return shift->_build_tree_html(@_);
	return shift->_build_tree_js(@_);
}

method _update_comments {
	my %comment = %{$self->comment_hash};
	my $tree = $comment{0};
	my $ctree = $self->_comments;
	my $croot = $self->_root_comments;
	for my $cid (keys $ctree) {
		unless($comment{$cid}) {
			$comment{$cid} = WWW::Slashdot::Scraper::CommentTree->new(
				node => WWW::Slashdot::Scraper::Comment->new(cid => $cid, story => $self->story));
		}
		#use DDP; p $comment{$cid};
		# TODO: should be in WWW::Slashdot::Scraper::Comment itself
		my $cur_comment = $comment{$cid}->node;
		$cur_comment->title($ctree->{$cid}{subject}) unless $cur_comment->title;
		$cur_comment->score($ctree->{$cid}{points});
		$cur_comment->author(WWW::Slashdot::Scraper::User->new()) unless $cur_comment->author;
		$cur_comment->author->uid($ctree->{$cid}{uid}) if $ctree->{$cid}{uid}
	}

	for my $cid (keys $ctree) {
		for my $child (@{$ctree->{$cid}{kids}}) {
			my $child_tree = $comment{$child};
			$comment{$cid}->add_child($child_tree)
				unless $child_tree->parent;
		}
		#$comment{$cid}->add_children( @comment{ @{$ctree->{$cid}{kids}} } )
			#if $ctree->{$cid}{kids};
	}
	$tree->remove_child_at(0) while $tree->child_count;
	$tree->add_children( @comment{@$croot} );
	$self->comment_hash(\%comment);
}

sub _init_comments {
	my $self = shift;

	my $script = $self->_tree->look_down( _tag => 'script', sub {
		my @c = $_[0]->content_list;
		$c[0] =~ /D2\.comments\(/ if @c;
	});

	(my $ctree_str = ($script->content_list)[0]) =~ s,.*^D2\.comments\((\N*)\);$ .*,$1,msx;
	(my $croot_str = ($script->content_list)[0]) =~ s,.*^D2\.root_comments\((\N*)\);$ .*,$1,msx;
	(my $croot_hash_str = ($script->content_list)[0]) =~ s,.*^D2\.root_comments_hash\((\N*)\);$ .*,$1,msx;

	my $ctree_json = $self->_json( $ctree_str );
	my $croot_json = $self->_json( $croot_str );
	my $croot_hash_json = $self->_json( $croot_hash_str );

	$self->_comments($ctree_json);
	$self->_root_comments($croot_json);
	$self->_root_comments_hash($croot_hash_json);



	my $ctree = WWW::Slashdot::Scraper::CommentTree->new( node => $self->story );
	$self->comment_hash->{0} = $ctree;
}

sub _build_tree_js {
	my $self = shift;
	$self->_init_comments unless $self->_comments;
	$self->_update_comments;
	my %comment = %{$self->comment_hash};
	for my $comment_content ($self->_tree->look_down(_tag => 'div', id => qr/^comment_\d+$/)) {
		my $cid = ($comment_content->attr('id') =~ /comment_(\d+)/)[0];
		$comment{$cid}->node->parse_content($comment_content);
	}
	return $self->comment_hash->{0};
}

# <div class="commentBody">
#  <div class="comment_body_\d+">
#  </div>
#  <div class="comment_sig_\d+">
#  --<br>
#  </div>
# </div>
sub _build_tree_html {
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

sub _json {
	my $self = shift;
	my $json = shift;
	$json = $self->_fix_json($json);
	my $data = eval { JSON->new->allow_barekey->decode($json) };
	if($@) {
		print STDERR "$@\n";
		return undef;
	}
	return $data;
}

sub _fix_json {
	my $self = shift;
	my $json_str = shift;
	#$json_str =~ s/(?:[{,]\s*)\K(\w+)(?=\s*[:])/"$1"/g;
	$json_str =~ s/(?:[:]\s*)\K(undefined)(?=\s*[,}])/null/g;
	return $json_str;
}

no Moose;
__PACKAGE__->meta->make_immutable;
