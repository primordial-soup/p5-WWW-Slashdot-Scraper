package WWW::Slashdot::Scraper::TestHelper;

use WWW::Slashdot::Scraper::Login::User;
use Exporter 'import';
@EXPORT = qw(generate_login dump_commenttree);

# generate login session from environment variables
sub generate_login {
	if( length $ENV{WWW_SLASHDOT_SCRAPER_USER} && length $ENV{WWW_SLASHDOT_SCRAPER_PASSWD} ) {
		return WWW::Slashdot::Scraper::Login::User->new(
			nick => $ENV{WWW_SLASHDOT_SCRAPER_USER},
			password => $ENV{WWW_SLASHDOT_SCRAPER_PASSWD} );
	}
	return undef;
}

sub dump_commenttree {
	my $tree = shift;
	my $s = "";
	$tree->traverse(sub {
		my $t = shift;
		$s .= ( (($t->depth > 0)?('  ' x ($t->depth-1)) . "↳ " : "") . ($t->node || '\undef') . "\n");
	});
	return $s;
}

1;
