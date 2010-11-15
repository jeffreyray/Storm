package Storm::Schema::Column;

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;
use MooseX::Method::Signatures;

use MooseX::Types::Moose qw( Bool Str Undef );

has 'table' => (
    is => 'rw',
    isa => 'Storm::Schema::Table',
);

has 'name' => (
    is       => 'ro' ,
    isa      => Str  ,
    required => 1    ,
);

has 'auto_increment' => (
    is       => 'rw'  ,
    isa      => Bool  ,
    default  => 0     ,
);


method sql {
    $self->table ?
    $self->table->name . '.' . $self->name :
    $self->name;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
