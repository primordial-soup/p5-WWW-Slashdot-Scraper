package WWW::Slashdot::Scraper::DateTime;

use Moose;
use MooseX::Method::Signatures;

use DateTime;
use Date::Parse;

# tzcode to tzdata
use constant CODE_TO_REGION => {
	IDLW => '',			# -1200 International Date Line West
	NT => 'America/Nome',		# -1100 Nome
	HAST => 'Pacific/Honolulu',	# -1000 Hawaii-Aleutian
	AKST => 'America/Anchorage',	# -0900 Alaska
	PST => 'America/Los_Angeles',	# -0800 Pacific
	MST => 'America/Denver',	# -0700 Mountain
	CST => 'America/Chicago',	# -0600 Central
	EST => 'America/New_York',	# -0500 Eastern
	AST => 'America/Halifax',	# -0400 Atlantic
	NST => 'America/St_Johns',	# -0330 Newfoundland
	GST => '',			# -0300 Greenland
	AT => 'Atlantic/Azores',	# -0200 Azores
	WAT => '',			# -0100 West Africa
	UTC => 'UTC',			# +0000 Universal Coordinated
	GMT => 'Etc/GMT',		# +0000 Greenwich Mean
	WET => '',			# +0000 Western European
	CET => '',			# +0100 Central European
	EET => '',			# +0200 Eastern European
	BT => '',			# 0300 Baghdad, USSR Zone 2
	IT => '',			# +0330 Iran
	ZP4 => '',			# +0400 USSR Zone 3
	ZP5 => '',			# +0500 USSR Zone 4
	IST => '',			# +0530 Indian
	ZP6 => '',			# +0600 USSR Zone 5
	ZP7 => '',			# +0700 USSR Zone 6
	JT => '',			# +0730 Java
	AWST => '',			# +0800 Western Australian
	CCT => '',			# +0800 China Coast, USSR Zone 7
	KST => '',			# +0900 Korean
	JST => '',			# +0900 Japan, USSR Zone 8
	ACST => '',			# +0930 Central Australian
	AEST => '',			# +1000 Eastern Australian
	MAGS => '',			# +1100 Magadan
	IDLE => '',			# +1200 International Date Line East
	NZST => '',			# +1200 New Zealand
};

has login => (
	is => 'rw',
	isa => 'WWW::Slashdot::Scraper::Login',
	required => 1
);

has timezone => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	builder => '_build_timezone',
);


method _build_timezone {
	my $tzcode = $self->login->pref->datetime->{tzcode};
	return CODE_TO_REGION->{$tzcode};
}

method get_datetime(Str $time) {
	return DateTime->from_epoch( epoch => str2time($time, $self->login->timezone) );
}


no Moose;
__PACKAGE__->meta->make_immutable;
