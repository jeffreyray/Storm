package Storm::Role::Query::HasOrderByClause;

use Moose::Role;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( ArrayRef );

with 'Storm::Role::Query::HasAttributeMap';

use Storm::SQL::Fragment::OrderBy;

has '_order_by' => (
    is => 'ro',
    isa => ArrayRef,
    default => sub { [] },
    traits => [qw( Array )],
    handles => {
        '_add_order_by_element' => 'push',
        'order_by_elements' => 'elements',
        '_has_no_order_by_elements' => 'is_empty',
    }
);

method order_by ( @args ) {
    my @elements;
    my $map = $self->_attribute_map;
    
    for ( @args ) {
        my ( $token, $order ) = ref $_ eq 'ARRAY' ? ( @$_ ) : ( $_ );
        ( $token ) = $self->args_to_sql_objects( $token );

        my $element = Storm::SQL::Fragment::OrderBy->new($token, $order);
        push @elements, $element;
    }
    
    $self->_add_order_by_element(@elements);
    return $self;
}

method _order_by_clause {
    return if $self->_has_no_order_by_elements;
    
    my $sql = 'ORDER BY ';
    $sql .= join q[, ], map { $_->sql } $self->order_by_elements;
    
    return $sql;
}



no Moose::Role;

1;
