package Storm::Policy::Object;

use Moose;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;
use MooseX::Method::Signatures;

use MooseX::Types::Moose qw( :all );


has '_definitions' => (
    is => 'ro',
    isa => HashRef,
    default => sub { { } },
    init_arg => undef,
    traits => [qw( Hash )],
    handles => {
        add_definition => 'set',
        get_definition => 'get',
        has_definition => 'exists',
    }
);

has '_transformations' => (
    is       => 'ro',
    isa      => 'HashRef[HashRef]',
    default  => sub { { } },
    init_arg => undef,
    traits   => [ 'Hash' ],
    handles  => {
        add_transformation => 'set',
        get_transformation => 'get',
        transformations    => 'elements',
        has_transformation => 'exists'  ,
    }
);

sub BUILD {
    my ( $self ) = @_;
    $self->add_definition( Any , 'CHAR(64)' );
    $self->add_definition( Num , 'DECIMAL(32,16)' );
    $self->add_definition( Int , 'INTEGER' );
}


method inflate_value ( $orm, $attr, $value, @args ) {
    
    # do nothing if there is not a type constraint
    return $value if ! $attr->has_type_constraint;
    
    my $type_constraint = $attr->type_constraint;
    
    # traverse the type contraints to see if we need to do anything
    while (1) {
        
        # we need to account for how maybe types work
        if ($type_constraint->parent &&
            $type_constraint->parent->name eq 'Maybe') {
            
            # return undef if it is a maybe type and there is no value
            return undef if ! defined $value;
            
            # otherwise, set the type constraint to the real type
            use Moose::Util::TypeConstraints;
            $type_constraint = find_type_constraint($type_constraint->{type_parameter});
        }
        
        # check to see if there is a custom inflator for this attribute
        if ( $attr->transform ) {
            my $function = $attr->transform->{inflate};
            {
                local $_ = $value;
                return &$function(@args);
            }
        }
        
        # check to see if it is a Storm enabled class
        if ($type_constraint->can( 'class' ) &&
            $type_constraint->class &&
            $type_constraint->class->can( 'meta' ) &&
            $type_constraint->class->meta->does_role( 'Storm::Role::Object' ) ) {
            
            my $class = $type_constraint->class;
            my $key = $value;
            $value = $orm->lookup($class, $value);
            
            confess "could not inflate value for attribute " . $attr->name .
                    " because we could not locate a $class object in the database" .
                    " with the identifier $key"
                    if ! defined $value;
            
            return $value;
        }
            
        # if not, see if there is a transformation for this type constraint
        elsif ( $self->has_transformation($type_constraint->name) ) {
            my $function = $self->get_transformation($type_constraint->name)->{inflate};
            {
                local $_ = $value;
                return &$function(@args);
            }
        }
        
        # if not, check the parent type constraint for transformations
        else {
            $type_constraint = $type_constraint->parent;
            
            # no more type constraints = no inflation
            return $value if ! $type_constraint;
        }
    }
}

method deflate_value ( $attr, $value, @args ) {
    
    # do nothing if there is not type constraint
    return $value if ! $attr->has_type_constraint;
    
    my $type_constraint = $attr->type_constraint;
    
    # traverse the type contraints to see if we need to do anything
    while (1) {
        
        # we need to account for how maybe types work
        if ($type_constraint->parent &&
            $type_constraint->parent->name eq 'Maybe') {
            
            # return undef if it is a maybe type and the value is undef
            return undef if ! defined $value;
            
            # otherwise, set the type constraint to the real type
            use Moose::Util::TypeConstraints;
            $type_constraint = find_type_constraint($type_constraint->{type_parameter});
        }
        
        # check to see if there is a custom deflator for this attribute
        if ( $attr->transform ) {
            my $function = $attr->transform->{deflate};
            {
                local $_ = $value;
                return &$function(@args);
            }
        }
        
        
        # check to see if it is a Storm enabled class
        if ($type_constraint->can('class') &&
            $type_constraint->class &&
            $type_constraint->class->can('meta') &&
            $type_constraint->class->meta->does_role('Storm::Role::Object')) {
            
            my $class = $type_constraint->class;
            return undef unless defined $value;
            return $class->meta->primary_key->get_value($value);
        }
        
        # if not, see if there is a transformation for this type constraint
        elsif ($self->has_transformation($type_constraint->name) ) {
            my $function = $self->get_transformation($type_constraint->name)->{deflate};
            {
                local $_ = $value;
                return &$function(@args);
            }
        }
        
        # if not, perform the check on the parent
        else {
            $type_constraint = $type_constraint->parent;
            
            # just return the value if no more type constraints to check
            return $value if ! $type_constraint;
        }
    }
}



no Moose;
__PACKAGE__->meta()->make_immutable();

1;
