package Storm::Meta::Table;

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

has 'name' => (
    is   => 'ro' ,
    isa  => 'Str',
    required => 1,
);

sub sql {  $_[0]->name }

sub schema { undef }

no Moose;
__PACKAGE__->meta->make_immutable;

1;
