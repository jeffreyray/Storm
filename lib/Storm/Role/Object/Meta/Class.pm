package Storm::Role::Object::Meta::Class;

use Moose::Role;
use Storm::Meta::Relationship::ManyToMany;
use Storm::Meta::Relationship::OneToMany;
use Storm::Meta::Table;


use Storm::Types qw( SchemaTable StormMetaRelationship );
use Storm::Meta::Attribute::Trait::PrimaryKey;
use MooseX::Types::Moose qw( HashRef Undef );
use MooseX::Method::Signatures;

has storm_table => (
    is        => 'rw' ,
    isa       => SchemaTable|Undef,
    lazy_build => 1,
    coerce    => 1,
);

method _build_storm_table {
    my $table;
    for my $class ( ($self->class_precedence_list)[0..-1] ) {
        my $meta = $class->meta;
        print $meta->name, ' - ';
        if ( $meta->can('storm_table') && $meta->has_storm_table ) {
            $table = $meta->storm_table;
            last if $table;
        }
    }
}

#has 'primary_key' => (
#    is        => 'rw',
#    isa       => 'Moose::Meta::Attribute',
#    reader    => 'primary_key'    ,
#    writer    => 'set_primary_key',
#    predicate => 'has_primary_key',
#);


# TODO: Cache this function, maybe rename it?
method primary_key {
    for my $att ( $self->get_all_attributes ) {
        return $att if $att->does( 'PrimaryKey' );
    }
}

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
    $att->column->set_table( $meta->storm_table ) if $att->column && $meta->storm_table;
    #$meta->set_primary_key( $att ) if $att->does('PrimaryKey');
};

method many_to_many ( %params ) {
    my $relationship = Storm::Meta::Relationship::ManyToMany->new( %params );
    $relationship->attach_to_class( $self );
}

method one_to_many ( %params ) {
    my $relationship = Storm::Meta::Relationship::OneToMany->new( %params );
    $relationship->attach_to_class( $self );
}

sub add_has_many {
    my $meta = shift;
    my %p    = @_;
    
    warn q[Storm::Role::Object::Meta::add_has_many is deprecated - ] .
    q[use Storm::Role::Object::Meta::one_to_many or ] .
    q[Storm::Role::Object::Meta::many_to_many instead.];
    
    my $has_many = exists $p{junction_table} ?
    Storm::Meta::Relationship::ManyToMany->new(%p) :
    Storm::Meta::Relationship::OneToMany->new(%p) ;

    $has_many->attach_to_class($meta);
}

1;