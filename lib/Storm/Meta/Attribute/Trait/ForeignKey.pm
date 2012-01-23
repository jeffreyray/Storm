package Storm::Meta::Attribute::Trait::ForeignKey;
use Moose::Role;

use MooseX::Types::Moose qw(Undef);
use Storm::Types qw(StormForeignKeyConstraintValue);

has 'on_update' => (
    is => 'rw',
    isa => StormForeignKeyConstraintValue,
    default => 'CASCADE',
);

has 'on_delete' => (
    is => 'rw',
    isa => StormForeignKeyConstraintValue,
    default => 'RESTRICT',
);

package Moose::Meta::Attribute::Custom::Trait::ForeignKey;
sub register_implementation { 'Storm::Meta::Attribute::Trait::ForeignKey' };
1;
