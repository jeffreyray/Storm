


package MyRole;
use Moose::Role;

use MooseX::Types::Moose qw( Int Str );

has 'foo' => (
    is => 'rw',
    isa => Str,
);


package Bazzle;
use Storm::Object;
use MooseX::Types::Moose qw( Int Str );
use Test::More;

storm_table( 'Bazzle' );

with 'MyRole';

has 'identifier' => (
    is => 'rw',
    isa => Str,
    traits => [qw( PrimaryKey )],
);



package main;
use Test::More tests => 1;
is (Bazzle->meta->get_attribute( 'foo' )->column->sql, 'Bazzle.foo', 'attribute added from role');


