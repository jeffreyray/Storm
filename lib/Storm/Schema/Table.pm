package Storm::Schema::Table;

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;
use MooseX::Method::Signatures;

has 'name' => (
    is   => 'ro' ,
    isa  => 'Str',
    required => 1,
);

method sql ( ) {
    $self->name;
}

method schema {
    undef;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
