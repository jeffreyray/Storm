use Test::More 'no_plan';


package Bazzle;
use Storm::Builder;
__PACKAGE__->meta->set_table( 'Bazzle' );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey )] );
has 'foo' => ( is => 'rw' );
has 'bar' => ( is => 'rw' );
has 'baz' => ( is => 'rw' );


package main;
use Storm;
my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );
ok $storm->source->manager->install_class_table( 'Bazzle' ), 'install class returned true';
is ( ($storm->source->tables)[0], 'Bazzle', 'table installed' );