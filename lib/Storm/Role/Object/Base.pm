package Storm::Role::Object::Base;

use Moose::Role;
use Storm::Schema::Table;

use Storm::Types qw( Storm );
use MooseX::Types::Moose qw( Undef );

has 'orm' => (
    reader => 'orm',
    writer => '_set_orm',
    isa => Storm|Undef,
    default => undef,
);

1;