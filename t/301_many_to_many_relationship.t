use Test::More tests => 1;

    
# build the testing classes
package Artist;
use Storm::Builder;
__PACKAGE__->meta->table( 'Artists' );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey AutoIncrement )] );
has 'name' => ( is => 'rw' );

has_many 'albums' => (
    foreign_class => 'Album',
    junction_table => 'AlbumArtists',
    local_match => 'artist',
    foreign_match => 'album',
    handles => {
       'albums' => 'iter',
       'add_album' => 'add',
       'remove_album' => 'remove',
    } 
);



package Album;
use Storm::Builder;
__PACKAGE__->meta->table( 'Albums' );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey AutoIncrement )] );
has 'name' => ( is => 'rw' );

has_many 'artists' => (
    foreign_class => 'Artist',
    junction_table => 'AlbumArtists',
    local_match => 'album',
    foreign_match => 'artist',
    handles => {
       'artists' => 'iter',
       'add_artist' => 'add',
       'remove_artist' => 'remove',
    } 
);



package main;
   
use Storm;

my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );
$storm->aeolus->install_class( 'Album' );
$storm->aeolus->install_class( 'Artist' );


my @artists;
for (qw/Jimmy Janis Elton Ozzy/) {
    my $artist = Artist->new( name => $_ );
    push @artists, $artist;
    $storm->insert( $artist );
}



my $album1 = Album->new( name => 'Experience Hendrix' );
$storm->insert( $album1 );
$album1->add_artist( @artists[0,1] );


is scalar( $album1->artists->all ), 2, 'add/select artists via linking table ok';

