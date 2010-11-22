use Test::More 'no_plan';


package Bazzle;
use Storm::Builder;
__PACKAGE__->meta->table( 'Bazzle' );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey )] );
has 'foo' => ( is => 'rw' );
has 'bar' => ( is => 'rw' );
has 'baz' => ( is => 'rw' );

has_many 'bizzles' => (
    foreign_class => 'Bizzle',
    junction_table => 'BizzleBazzles',
    local_match => 'bazzle',
    foreign_match => 'bizzle',
    
);

package Bizzle;
use Storm::Builder;
__PACKAGE__->meta->table( 'Bizzle' );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey )] );
has 'foo' => ( is => 'rw' );
has 'bar' => ( is => 'rw' );
has 'baz' => ( is => 'rw' );

has_many 'bazzles' => (
    foreign_class => 'Bazzle',
    junction_table => 'BizzleBazzles',
    local_match => 'bizzle',
    foreign_match => 'bazzle',
);

package Buzzle;
use Storm::Builder;
__PACKAGE__->meta->table( 'Buzzle' );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey )] );
has 'bizzle' => ( is => 'rw', isa => 'Bizzle' );

package main;
use Storm;

my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );
$storm->aeolus->start_fresh;
$storm->aeolus->install_class_table( 'Bazzle' );
$storm->aeolus->install_class_table( 'Bizzle' );
$storm->aeolus->install_class_table( 'Buzzle' );
$storm->aeolus->install_junction_tables( 'Bazzle' );

my %tables = map { $_ => 1 } $storm->source->tables;
ok $tables{ 'Bazzle' }, 'Bazzle table installed';
ok $tables{ 'Bizzle' }, 'Bizzle table installed';
ok $tables{ 'Bizzle' }, 'BizzleBazzle table installed';

