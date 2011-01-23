package Storm::Role::Query::HasAttributeOrder;

use Moose::Role;
use MooseX::Method::Signatures;
use MooseX::Types::Moose qw( ArrayRef );


has 'attribute_order' => (
    isa => ArrayRef,
    traits => [qw( Array )],
    lazy_build => 1,
    handles => {
        'attribute_order' => 'elements',
    }
);

method _build_attribute_order {
    my $meta = $self->class->meta;
    
    # make sure the primary key is the first entry in the order
    my @order = ( $self->class->meta->primary_key );
    
    # create the attribute order
    for my $attribute ( $meta->get_all_attributes ) {
        next if $attribute->name eq $order[0]->name; # skip if this is the primary key
        next if ! $attribute->can('column') || ! $attribute->column;
        push @order, $attribute;
    }

    return \@order; 
}

no Moose::Role;
1;
