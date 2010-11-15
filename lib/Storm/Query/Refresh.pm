package Storm::Query::Refresh;

use Moose;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;
use MooseX::Method::Signatures;

with 'Storm::Role::CanInflate';
with 'Storm::Role::Query';
with 'Storm::Role::Query::HasAttributeOrder';
with 'Storm::Role::Query::IsExecutable';


method _sql {
    return join q[ ] ,
        $self->_select_clause,
        $self->_from_clause  ,
        $self->_where_clause ;
}


method refresh ( @objects ) {

    for my $o (@objects) {
        my $id = $o->meta->primary_key->get_value( $o );
        
        # retrieve the object from the database
        my $sth  = $self->_sth;
        $sth->execute($id);
        my  @data = $sth->fetchrow_array;
        return undef if ! @data;
        
        # build the object from the data retrieved
        my %struct;
        my @attributes = $self->attribute_order;
        @data = $self->_inflate_values(\@attributes, \@data);
        @struct{map {$_->name } $self->attribute_order} = @data;
        
        for (keys %struct) {
            $o->meta->get_attribute($_)->set_value( $o, $struct{$_} );
        }
    }
    
    return 1;
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

