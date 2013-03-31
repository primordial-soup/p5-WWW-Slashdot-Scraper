package WWW::Slashdot::Scraper::Login;

use Moose::Role;
use WWW::Mechanize;

use WWW::Slashdot::Scraper::DateTime;

has mech => (
	is => 'ro',
	isa => 'WWW::Mechanize',
	lazy => 1,
	builder => '_build_mech',
);

has datetime => (
	is => 'ro',
	isa => 'WWW::Slashdot::Scraper::DateTime',
	lazy => 1,
	builder => '_build_datetime',
);

sub _build_mech {
	return WWW::Mechanize->new();
}

sub _build_datetime {
	my $self = shift;
	return WWW::Slashdot::Scraper::DateTime->new( login => $self );
}

requires 'login';

sub BUILD {}
after BUILD => sub {
	my $self = shift;
	$self->login();
};

no Moose::Role;
1;
