package WWW::Slashdot::Scraper::Preference;

use Moose;
use MooseX::Method::Signatures;
use List::MoreUtils qw/zip/;

use constant PREF_URI => {
	thresholds  => 'http://slashdot.org/prefs/thresholds',
	datetime    => 'http://slashdot.org/prefs/timedate',
	slashboxes  => 'http://slashdot.org/prefs/slashboxes',
	discussions => 'http://slashdot.org/prefs/d2',
	posting     => 'http://slashdot.org/prefs/d2_posting',
};

has login => (
	is => 'rw',
	isa => 'WWW::Slashdot::Scraper::Login::User',	# can not be anonymous
	required => 1
);

has datetime => (
	is => 'ro',
	isa => 'HashRef',
	lazy => 1,
	clearer => '_clear_datetime',
	builder => '_build_datetime'
);

method _get_datetime_form {
	my $login = $self->login;
	my $r = $login->mech->get( PREF_URI->{datetime} );
	my $form = $login->mech->form_with_fields(qw/tzformat tzcode dst/);
	return $form;
}

method _build_datetime {
	my $form = $self->_get_datetime_form;
	my $opt_tzfmt = $form->find_input('tzformat');
	my $opt_tzcode = $form->find_input('tzcode');
	my $opt_dst = $form->find_input('dst');

	my %opt_tzfmt_vals = zip(@{[$opt_tzfmt->possible_values()]}, @{[$opt_tzfmt->value_names()]});
	my %opt_tzcode_vals = zip(@{[$opt_tzcode->possible_values()]}, @{[$opt_tzcode->value_names()]});
	my %opt_dst_vals = zip(@{[$opt_dst->possible_values()]}, @{[$opt_dst->value_names()]});

	return {
		tzformat => $opt_tzfmt_vals{$opt_tzfmt->value},
		tzcode => { code => $opt_tzcode->value, name => $opt_tzcode_vals{$opt_tzcode->value} },
		dst => $opt_dst_vals{$opt_dst->value},
	};
}

method set_utc_timezone {
	my $login = $self->login;
	my $r = $login->mech->get( PREF_URI->{datetime} );
	$login->mech->submit_form( with_fields => { tzcode => 'UTC', dst => 'off' } ); # 19
	$self->_clear_datetime;
}

method set_iso8601_datetime_tzformat {
	if($self->datetime()->{tzformat} ne '1999-03-19 14:14' ) {
		my $login = $self->login;
		my $r = $login->mech->get( PREF_URI->{datetime} );
		$login->mech->submit_form( with_fields => { tzformat => '1999-03-19 14:14' } ); # 19
		$self->_clear_datetime;
	}
}

method _set_invalid_datetime_tzformat {
	my $login = $self->login;
	my $r = $login->mech->get( PREF_URI->{datetime} );
	$login->mech->submit_form( with_fields => { tzformat => '6 ish'  } ); # 13
	$self->_clear_datetime;
}

no Moose;
__PACKAGE__->meta->make_immutable;
