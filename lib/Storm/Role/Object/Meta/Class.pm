package Storm::Role::Object::Meta::Class;

use Moose::Role;
use Storm::Meta::Relationship::ManyToMany;
use Storm::Meta::Relationship::OneToMany;
use Storm::Schema::Table;


use Storm::Types qw( SchemaTable StormMetaRelationship );
use MooseX::Types::Moose qw( HashRef );

has table => (
    is        => 'rw' ,
    isa       => SchemaTable ,
    predicate => 'has_table' ,
    writer    => 'set_table' ,
    reader    => 'table' ,
    coerce    => 1,
);

has 'primary_key' => (
    is        => 'rw',
    isa       => 'Moose::Meta::Attribute',
    reader    => 'primary_key'    ,
    writer    => 'set_primary_key',
    predicate => 'has_primary_key',
);

has 'relationships' => (
    is => 'rw',
    isa => HashRef,
    traits => [qw( Hash )],
    handles => {
        '_add_relationship' => 'set',
        'get_relationship' => 'get',
        'get_relationship_list' => 'keys',
        '_remove_relationship' => 'delete',
    }
);

after 'add_attribute' => sub {
    my ( $meta, $name ) = @_;
    my $att = blessed $name ? $name : $meta->get_attribute( $name );
    $att->column->set_table( $meta->table ) if $att->column;
    $meta->set_primary_key( $att ) if $att->does('PrimaryKey');
};

sub add_has_many {
    my $meta = shift;
    my %p    = @_;
    
    my $has_many = exists $p{linking_table} ?
    Storm::Meta::Relationship::ManyToMany->new(%p) :
    Storm::Meta::Relationship::OneToMany->new(%p) ;

    $has_many->attach_to_class($meta);
}

1;