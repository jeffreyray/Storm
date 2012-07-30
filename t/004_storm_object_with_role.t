


package Foo;
use Moose::Role;

use MooseX::Types::Moose qw( Int Str );



has 'foo' => (
    is => 'rw',
    isa => Str,
);


package Bar;
use Storm::Object;
use MooseX::Types::Moose qw( Int Str );
use Test::More;

storm_table( 'Bazzle' );

with 'Foo';

has 'identifier' => (
    is => 'rw',
    isa => Str,
    traits => [qw( PrimaryKey )],
);



package main;
use Test::More tests => 1;



is (Bar->meta->get_attribute( 'foo' )->column->sql( Bar->meta->storm_table ), 'Bazzle.foo', 'attribute added from role');



