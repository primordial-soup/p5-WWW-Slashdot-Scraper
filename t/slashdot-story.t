#!/usr/bin/perl

use Test::More;
use Test::Deep;
use lib 't/lib';

BEGIN { use_ok( 'WWW::Slashdot::Scraper::Story' ); }
require_ok( 'WWW::Slashdot::Scraper::Story' );

BEGIN { use_ok( 'WWW::Slashdot::Scraper::TestHelper' ); }
require_ok( 'WWW::Slashdot::Scraper::TestHelper' );

BEGIN { use_ok( 'WWW::Slashdot::Scraper::Login::User' ); }
require_ok( 'WWW::Slashdot::Scraper::Login::User' );

BEGIN { use_ok( 'DateTime' ); }
require_ok( 'DateTime' );

my $uzebox_article_info = {
	title => 'The Uzebox: an Open Source Hardware Games Console',
	section => 'games',
	comment_count => 104,
	anon_tag => [qw/games hardware opensource/],
	user_tag => [qw/games hardware opensource console uzebox/],
	topic => [
		{ image_URI => URI->new("http://a.fsdn.com/sd/topics/opensource_64.png"),
			name => "Open Source" },
		{ image_URI => URI->new("http://a.fsdn.com/sd/topics/games_64.png"),
			name => "Games" },
		{ image_URI => URI->new("http://a.fsdn.com/sd/topics/hardware_64.png"),
			name => "Hardware" },
	],
	article_text_length => 387, # length of just the non-whitespace characters
	datetime => DateTime->new(year => 2011, month => 7, day => 6, hour => 07, minute => 31, time_zone => "UTC"),
};

my $pd_article_info = {
	title => "What Could Have Been In the Public Domain Today, But Isn't",
	section => 'yro',
	comment_count => 412,
	anon_tag => [qw/publicdomain books movies/],
	user_tag => [qw/publicdomain books movies yro court/],
	topic => [ { image_URI => URI->new("http://a.fsdn.com/sd/topics/books_64.png"), name => "Books" },
			{ image_URI => URI->new("http://a.fsdn.com/sd/topics/movies_64.png"), name => "Movies" },
			{ image_URI => URI->new("http://a.fsdn.com/sd/topics/entertainment_64.png"), name => "Entertainment" },
			{ image_URI => URI->new("http://a.fsdn.com/sd/topics/yro_64.png"), name => "Your Rights Online" } ],
	article_text_length => 376,
	datetime => DateTime->new(year => 2012, month => 01, day => 01, hour => 15, minute => 28, time_zone => "UTC"),
};

my $info = {
	'http://games.slashdot.org/story/11/07/06/0524247/The-Uzebox-an-Open-Source-Hardware-Games-Console'
		=> $uzebox_article_info,
	#'http://games.slashdot.org/article.pl?sid=11/07/06/0524247' =>
		#$uzebox_article_info,
	#'http://slashdot.org/article.pl?sid=11/07/06/0524247' =>
		#$uzebox_article_info,
	'http://yro.slashdot.org/story/12/01/01/1523221/what-could-have-been-in-the-public-domain-today-but-isnt' =>
		$pd_article_info,

};
# http://science.slashdot.org/story/11/07/11/1559219/CmdrTaco-Watches-Atlantis-Liftoff
# http://science.slashdot.org/story/05/01/19/1646239/Do-You-Want-to-Live-Forever
# http://web.archive.org/web/20090629062745/http://science.slashdot.org/story/05/01/19/1646239/Do-You-Want-to-Live-Forever

my $user_login = generate_login();
warn "Not testing user login" unless defined $user_login;

for my $url (keys %$info) {
	subtest "Test $url", sub {
		my $anon_story, $user_story;
		ok( defined ($anon_story = WWW::Slashdot::Scraper::Story->new(
			story_url => $url )),
			"create anonymous story @ $url");
		if( defined $user_login ) {
			ok( defined ($user_story = WWW::Slashdot::Scraper::Story->new(
				story_url => $url,
				login => $user_login )),
			"create user story @ $url");
		}

		is( $anon_story->title , $info->{$url}{title}, 'anon title' );
		is( $user_story->title , $info->{$url}{title}, 'user title' ) if defined $user_login;

		is( $anon_story->section , $info->{$url}{section}, 'anon section' );
		is( $user_story->section , $info->{$url}{section}, 'user section' ) if defined $user_login;

		is( $anon_story->comment_count, $info->{$url}{comment_count}, 'anon comment count');
		is( $user_story->comment_count, $info->{$url}{comment_count}, 'user comment count') if defined $user_login;

		cmp_set( $anon_story->tag, $info->{$url}{anon_tag}, "anon tags");
		cmp_set( $user_story->tag, $info->{$url}{user_tag}, "user tags") if defined $user_login;

		cmp_set( $anon_story->topic, $info->{$url}{topic}, "anon topic");
		cmp_set( $user_story->topic, $info->{$url}{topic}, "user topic") if defined $user_login;
		
		(my $anon_text = $anon_story->article_text) =~ s/\s//gs;
		is( length $anon_text, $info->{$url}{article_text_length}, 'anon article text');
		if( defined $user_login ) {
			(my $user_text = $user_story->article_text) =~ s/\s//gs;
			is( length $user_text, $info->{$url}{article_text_length}, 'user article text');
		}

		#{ use DDP; p $anon_story->datetime; }
		#{ use DDP; p $user_story->datetime; }
		is( $anon_story->datetime, $info->{$url}{datetime}, 'anon datetime');
		is( $user_story->datetime, $info->{$url}{datetime}, 'user datetime') if defined $user_story;

		#p $anon_story->_html_content;
		done_testing;
	};
}

done_testing;
