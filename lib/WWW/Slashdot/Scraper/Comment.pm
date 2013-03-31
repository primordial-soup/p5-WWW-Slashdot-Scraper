package WWW::Slashdot::Scraper::Comment;

use Moose;
use 5.012;

use overload 
  q("") => sub { my $self = shift; return "@{[$self->title // '(no title)']} (@{[$self->cid]})" };

use WWW::Slashdot::Scraper::User;

use MooseX::Types::DateTime;
use MooseX::Types::URI qw(Uri);

has uri => (
	is => 'rw',
	isa => 'URI',
);

has story => (
	is => 'rw',
	isa => 'WWW::Slashdot::Scraper::Story',
);

has cid => (
	is => 'rw',
	isa => 'Str',
	required => 1,
);

has title => (
	is => 'rw',
	isa => 'Str|Undef',
);

has body => (
	is => 'rw',
	isa => 'Str|Undef',
);

has sig => (
	is => 'rw',
	isa => 'Str|Undef',
);

has author => (
	is => 'rw',
	isa => 'WWW::Slashdot::Scraper::User',
);

has datetime => (
	is => 'rw',
	isa => 'DateTime',
);

has score => (
	is => 'rw',
	isa => 'Int'
);

has score_type => (
	is => 'rw',
	isa => 'Str|Undef',
);

sub score_string {
	my $self = shift;
	return unless $self->score;
	$self->score . ($self->score_type)?(', '.$self->score_type):("");
}

sub parse_content {
	my ($self, $content) = @_;
	return unless $content;
	my $div_title = $content->look_down( _tag => 'div', class => 'title' );
	return unless $div_title;
	use DDP; p $self->cid;

	my $comment_link = $content->look_down( _tag => 'a', id => qr/comment_link_\d+/);
	my $score        = $content->look_down( _tag => 'span', id => qr/comment_score_\d+/);
	my $body         = $content->look_down(_tag => 'div', id => qr/comment_body_\d+/);
	my $sig          = $content->look_down(_tag => 'div', id => qr/comment_sig_\d+/);
	my $by           = $content->look_down( _tag => 'span', class => 'by');
	my $details = $content->look_down(_tag => 'div', class => 'details');
	my $otherdetails = $content->look_down( _tag => 'span', id => qr/comment_otherdetails_\d+/);

#if(0) {
	my $substr;
	if($substr = $body->look_down(_tag => 'span', class => "substr")) {
		$substr->detach;
		my $len = length(join '', map { $_->as_HTML } $body->content_list);
		my $response = $self->story->login->mech->post(
			"http://slashdot.org/ajax.pl",
			{
				op => 'comments_fetch',
				cids => $self->cid,
				discussion_id => $self->story->comment_container->_data->{discussion_id},
				abbreviated => "$self->cid,$len",
				pieces => "$self->cid,1",
		});
		return -1 unless $response->decoded_content;
		my $fetch_data = $self->story->comment_container->_json($response->decoded_content);
		for my $html_push ($fetch_data->{html}, $fetch_data->{html_append_substr}) {
			for my $comment_key (keys $html_push) {
				print $comment_key;
				my $what = do { given($comment_key) {
					when( /comment_otherdetails_\d+/ ) { $otherdetails }
					when( /comment_body_\d+/ ) { $body }
				}};
				next unless $what;
				$what->push_content($html_push->{$comment_key});
			}
		}
	}
#}

	my $comment_title_txt = $comment_link->as_trimmed_text(extra_chars => '\xA0');
	$self->title($comment_title_txt) if $comment_title_txt ne 'Re:' and not $self->title;

	my $uri = URI->new($comment_link->attr('href'));
	$uri->scheme("http");
	$self->uri($uri) unless $self->uri;

	my $score_text = $score->as_trimmed_text(extra_chars => '\xA0');
	$score_text =~ /\(Score:(-?\d)(, (\w+))?\)/;
	my $score_num = $1;
	my $score_type = $3;
	$self->score($score_num) unless $self->score;
	$self->score_type($score_type) unless $self->score_type;

	my $user = $by->look_down( _tag => 'a');
	$self->author(WWW::Slashdot::Scraper::User->new()) unless $self->author;
	if($user) {
		my $user_uri = URI->new($user->attr('href'));
		my $user_text = $user->as_trimmed_text(extra_chars => '\xA0');
		$user_text =~ /^(.*) \((\d+)\)$/;
		my $user_name = $1;
		my $user_uid = $2;
		$user_uri->scheme('http');
		$self->author->uid($user_uid) if $user_uid and not $self->author->uid;
		$self->author->page($user_uri) if $user_uri and not $self->author->page;
		$self->author->name($user_name) if $user_name and not $self->author->name;
	} else {
		# anon
		$self->author->uid(666);
	}
	my $email = $details->look_down( _tag => 'a', href => qr/^mailto:/);
	$self->author->email(URI->new($email->attr('href'))) if $email;
	my $homepage = $details->look_down( _tag => 'a', class => 'user_homepage_display');
	$self->author->homepage(URI->new($homepage->attr('href'))) if $homepage;

	my $detail_string = $otherdetails->as_trimmed_text(extra_chars => '\xA0');
	$detail_string =~ /on (.*) \(#/;
	my $date_str = $1;
	$date_str =~ s/@//;
	$self->datetime($self->story->login->datetime->get_datetime($date_str));

	#use DDP; p $body;
	#use DDP; p $content->as_HTML;
	$self->body($body->as_HTML) if $body and not $self->body;
	$self->sig($sig->as_HTML) if $sig and not $self->sig;

	1;
}

no Moose;
__PACKAGE__->meta->make_immutable;
