use Test::More tests => 1;

    
# build the testing classes
package Frizzle;
use Storm::Builder;
__PACKAGE__->meta->set_table( 'Frizzle' );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey AutoIncrement )] );
has 'frazzle' => ( is => 'rw', isa => 'Frazzle' );



package Frazzle;
use Storm::Builder;
__PACKAGE__->meta->set_table( 'Frazzle' );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey AutoIncrement )] );


package main;
   
use Storm;

my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );
$storm->source->manager->install_class( 'Frizzle' );
$storm->source->manager->install_class( 'Frazzle' );


my $fraz = Frazzle->new;
$storm->insert( $fraz );

my $friz = Frizzle->new( frazzle => $fraz );
$storm->insert( $friz );

$friz = $storm->lookup( 'Frizzle', $friz->identifier );
isa_ok $friz->frazzle, 'Frazzle', 'inflated attribute';


