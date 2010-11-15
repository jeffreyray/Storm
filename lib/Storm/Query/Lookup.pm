package Storm::Query::Lookup;

use Moose;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;
use MooseX::Method::Signatures;

with 'Storm::Role::CanInflate';
with 'Storm::Role::Query';
with 'Storm::Role::Query::HasAttributeOrder';
with 'Storm::Role::Query::IsExecutable';


method _sql ( ) {    
    return join q[ ] ,
        $self->_select_clause,
        $self->_from_clause  ,
        $self->_where_clause ;
}


method lookup ( $id ) {

    # see if the object exists in the live object cache
    my $live = $self->orm->live_objects;
    my $cached  = $live->get_object( $self->class, $id );
    return $cached if $cached;
    
    # retrieve the object from the database because it was not in the cache
    my $sth  = $self->_sth;
    $sth->execute($id);
    my  @data = $sth->fetchrow_array;
    return undef if ! @data;
    
    # build the object from the data retrieved
    my %struct;
    my @attributes = $self->attribute_order;
    @data = $self->_inflate_values( \@attributes, \@data );
    @struct{ map { $_->name } $self->attribute_order } = @data;

    my $o = $self->class->new(%struct);
    $o->_set_orm( $self->orm );
    
    # store the object in the live object cache
    $live->insert( $o ) if $live->current_scope;
    
    return $o;
}


method _select_clause ( ) {
    return 'SELECT ' . join (', ', map { $_->column->sql } $self->attribute_order);
}

method _from_clause ( ) {
    return 'FROM ' . $self->class->meta->table->sql;
}

method _where_clause ( ) {
    return 'WHERE ' . $self->class->meta->primary_key->column->sql . ' = ?';
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

