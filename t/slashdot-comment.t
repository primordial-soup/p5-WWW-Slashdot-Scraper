#!/usr/bin/perl

use Test::More;
use Test::Deep;
use lib 't/lib';

BEGIN { use_ok( 'WWW::Slashdot::Scraper::Story' ); }
require_ok( 'WWW::Slashdot::Scraper::Story' );

BEGIN { use_ok( 'WWW::Slashdot::Scraper::TestHelper' ); }
require_ok( 'WWW::Slashdot::Scraper::TestHelper' );

my $info = {
	'http://games.slashdot.org/story/11/07/06/0524247/The-Uzebox-an-Open-Source-Hardware-Games-Console' =>
		{ comment_count => 104 },
	'http://science.slashdot.org/story/10/05/07/2242254/climate-change-and-the-integrity-of-science' =>
		{ comment_count => 1046 },
};
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

		my $anon_ctree = $anon_story->comment_container->comment_tree;
		my $user_ctree = $user_story->comment_container->comment_tree if defined $user_login;

		my $ret = 1;
		while($ret != 0) {
			$ret = $anon_story->comment_container->update;
		}
		if($user_login) {
			$ret = 1;
			while($ret != 0) {
				$ret = $user_story->comment_container->update if $user_login;
			}
		}

		is( $anon_ctree->child_comment_count, $info->{$url}{comment_count}, 'anon comment count');
		is( $user_ctree->child_comment_count, $info->{$url}{comment_count}, 'user comment count') if defined $user_login;

		print dump_commenttree($user_ctree) if $user_ctree;

		done_testing;
	};
}

done_testing;
