use Test::More 'no_plan';


package Artist;
use Storm::Builder;
__PACKAGE__->meta->set_table( 'Artists' );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey AutoIncrement )] );
has 'name' => ( is => 'rw' );

has_many 'albums' => (
    foreign_class => 'Album',
    primary_key => 'artist',
    foreign_key => 'album',
    linking_table => 'AlbumArtists',
    handles => {
       'albums' => 'iter',
       'add_album' => 'add',
       'remove_album' => 'remove',
    } 
);



package Album;
use Storm::Builder;
__PACKAGE__->meta->set_table( 'Albums' );

has 'identifier' => ( is => 'rw', traits => [qw( PrimaryKey AutoIncrement )] );
has 'name' => ( is => 'rw' );

has_many 'artists' => (
    foreign_class => 'Artist',
    primary_key => 'album',
    foreign_key => 'artist',
    linking_table => 'AlbumArtists',
    handles => {
       'artists' => 'iter',
       'add_artist' => 'add',
       'remove_artist' => 'remove',
    } 
);


package main;
use Storm;
my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );
$storm->source->manager->install_linking_tables( 'Artist' );

# skip if the table already exists in the database
my $infosth = $storm->source->dbh->table_info( undef, undef, 'AlbumArtists', undef);
my @tableinfo = $infosth->fetchrow_array;
ok scalar(@tableinfo), 'table created';
