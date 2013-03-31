package WWW::Slashdot::Scraper::User;

use Moose;

use URI;
use MooseX::Types::URI qw(Uri);

has uid => (
	is => 'rw',
	isa => 'Int',
	#required => 1,
);

has name => (
	is => 'rw',
	isa => 'Str|Undef',
	lazy => 1,
	builder => '_build_name',
);

has page => (
	is => 'rw',
	# TODO
	#isa => 'Uri',
);

has homepage => (
	is => 'rw',
	# TODO
	#isa => 'Uri',
);

has email => (
	is => 'rw',
	# TODO
	#isa => 'Uri',
);



sub is_anon {
	my $self = shift;
	$self->uid == 666;
}

sub _build_name {
	my $self = shift;
	if($self->is_anon) {
		return 'Anonymous Coward';
	}
	undef;
}

no Moose;
__PACKAGE__->meta->make_immutable;
