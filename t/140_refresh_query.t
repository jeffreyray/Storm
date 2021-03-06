use Test::More 'no_plan';


# build the testing class
package Bazzle;
use Storm::Object;
storm_table( 'Bazzle' );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey )] );
has 'foo' => ( is => 'rw' );
has 'bar' => ( is => 'rw' );
has 'baz' => ( is => 'rw' );


# run the tests
package main;

use Storm;
my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );
$storm->aeolus->install_class( 'Bazzle' );

my $query = Storm::Query::Insert->new( $storm, 'Bazzle' );
my $o = Bazzle->new( identifier => 1, foo => 'foo', bar => 'bar', baz => 'baz' );
$query->insert( $o );

my $original = $o;

$o->foo( 'foobar' );
$o->bar( 'foobar' );
$o->baz( 'foobar' );

$query = Storm::Query::Update->new( $storm, 'Bazzle' );
$query->update( $o );
ok $o, 'update query returned true';

$query = Storm::Query::Refresh->new( $storm, 'Bazzle' );
$query->refresh( $original );
is_deeply [$o->foo, $o->bar, $o->baz], [qw/foobar foobar foobar/], 'refresh successful';


# test schema
__DATA__

CREATE TABLE Bazzle (
    identifier VARCHAR(10) NOT NULL,
    foo VARCHAR(30),
    bar VARCHAR(30),
    baz VARCHAR(30),
    PRIMARY KEY (identifier)
);