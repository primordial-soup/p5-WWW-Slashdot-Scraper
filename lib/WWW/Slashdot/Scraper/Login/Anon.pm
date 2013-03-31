package WWW::Slashdot::Scraper::Login::Anon;

use Moose;
use WWW::Mechanize;

sub login {}

# this is the default timezone
sub timezone { return "-0400"; }

with 'WWW::Slashdot::Scraper::Login';

no Moose;
__PACKAGE__->meta->make_immutable;
