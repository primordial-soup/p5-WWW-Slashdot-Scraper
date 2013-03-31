#!/usr/bin/env perl

use Test::More;
use lib 't/lib';

BEGIN { use_ok( 'WWW::Slashdot::Scraper::Preference' ); }
require_ok( 'WWW::Slashdot::Scraper::Preference' );

BEGIN { use_ok( 'WWW::Slashdot::Scraper::TestHelper' ); }
require_ok( 'WWW::Slashdot::Scraper::TestHelper' );

my $user_login = generate_login() or die "could not login";
ok( defined $user_login, "logged in");

my $pref;
ok( $pref = WWW::Slashdot::Scraper::Preference->new( login => $user_login ), "preference created" );
ok( $pref->datetime, "datetime is retrieved");
$pref->_set_invalid_datetime_tzformat;
is( $pref->datetime()->{tzformat}, '6 ish', 'can set invalid tzformat');
$pref->set_iso8601_datetime_tzformat;
is( $pref->datetime()->{tzformat}, '1999-03-19 14:14', 'can set ISO 8601 tzformat');
#{ use DDP; p $pref->datetime; }

done_testing;
