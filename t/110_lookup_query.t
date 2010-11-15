use Test::More 'no_plan';


# build the testing class
package Bazzle;
use Storm::Builder;
__PACKAGE__->meta->set_table( 'Bazzle' );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey )] );
has 'foo' => ( is => 'rw' );
has 'bar' => ( is => 'rw' );
has 'baz' => ( is => 'rw' );


# run the tests
package main;

use Storm;
my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );
$storm->source->manager->install( *main::DATA );

my $query = Storm::Query::Insert->new( $storm, 'Bazzle' );
my $o = Bazzle->new( identifier => 1, foo => 'foo', bar => 'bar', baz => 'baz' );
$query->insert( $o );

$query = Storm::Query::Lookup->new( $storm, 'Bazzle' );
$o = $query->lookup( 1 );
ok $o, 'retrieved object from database';
isa_ok $o, 'Bazzle';

# test schema
__DATA__

CREATE TABLE Bazzle (
    identifier VARCHAR(10) NOT NULL,
    foo VARCHAR(30),
    bar VARCHAR(30),
    baz VARCHAR(30),
    PRIMARY KEY (identifier)
);