package WWW::Slashdot::Scraper::Login::User;

use Moose;
use MooseX::Method::Signatures;

use Carp;
use WWW::Mechanize;
use WWW::Slashdot::Scraper::Preference;

use constant LOGIN_URI => 'http://slashdot.org/my/login';

# unickname
has nick => (
	is => 'rw',
	isa => 'Str',
	required => 1,
);

# upasswd
has password => (
	is => 'rw',
	isa => 'Str',
	required => 1,
);

# login_temp
has temporary_login => (
	is => 'rw',
	isa => 'Bool',
	default => sub { 1 },
);

has pref => (
	is => 'ro',
	isa => 'WWW::Slashdot::Scraper::Preference',
	default => sub { my $self = shift; WWW::Slashdot::Scraper::Preference->new( login => $self );  },
);

method login { 
	my $mech = $self->mech;
	$mech->get(LOGIN_URI);
	#$mech->tick( 'login_temp', undef, $self->temporary_login );
	my $response = $mech->submit_form(
		form_number => 2,
		fields => {
			unickname => $self->nick,
			upasswd => $self->password,
			login_temp => $self->temporary_login,
		}
	);
	carp("login failed") if $response->base eq LOGIN_URI; # still on login page

	# NOTE: this is here until the datetime algorithm in
	# WWW::Slashdot::Scraper::DateTime is complete, which may not happen because
	# having "automatic" DST makes little sense without the specific
	# timezone region
	$self->pref->set_utc_timezone;
}

method timezone {
	my $pref = $self->pref;
	return $pref->datetime->{tzcode}->{code};
}

with 'WWW::Slashdot::Scraper::Login';

no Moose;
__PACKAGE__->meta->make_immutable;
