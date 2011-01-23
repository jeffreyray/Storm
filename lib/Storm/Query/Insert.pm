package Storm::Query::Insert;

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;
use MooseX::Method::Signatures;

with 'Storm::Role::CanDeflate';
with 'Storm::Role::Query';
with 'Storm::Role::Query::HasAttributeOrder';
with 'Storm::Role::Query::IsExecutable';

method insert ( @objects ) {
    
    my $sth = $self->_sth; # exists in Storm::Role::Query::IsExecutable
    
    my @attributes = $self->attribute_order;
    my $primary_key = $self->class->meta->primary_key;
    my $orm = $self->orm;
    
    my $autoinc = 1 if $primary_key->column->auto_increment;
    
    for my $o ( @objects ) {
        
        # throw exception if no primary key (and does not auto-increment )
        my $key_value = $primary_key->get_value( $o );
        
        if ( (! defined $key_value || $key_value eq '') && ! $autoinc ) {
            "could not insert object " . $o . " into database: " .
            "primary key not set (or AutoIncrement trait not used)";
        }
        
        # insert the object into the database
        my @data = map { $_->get_value( $o ) } $self->attribute_order;
        @data = $self->_deflate_values( \@attributes, \@data );
        $sth->execute( @data );
        
        # throw exception if insert failed
        if ( $sth->err ) {
            confess qq[could not insert $o into database: ] . $sth->err
        }
        
        # discover primary key if auto_increment
        if ( $autoinc ) {
            my $key = $orm->source->dbh->last_insert_id( undef, undef, $o->meta->storm_table, undef );
            $primary_key->set_value( $o, $key );
        }
        
        # add the object the live objects cache
        my $live = $orm->live_objects;
        $live->insert( $o ) if $live->current_scope;
        
        # set the orm of the object (necessary for relationships)
        $o->_set_orm( $orm );
    }
    
    return 1;
}




method _sql {   
    return (
        join ' ',
        $self->_insert_clause,
        $self->_columns_clause,
        $self->_values_clause,,
    );
}


method _insert_clause {
    my $table = $self->class->meta->storm_table;
    
    return 'INSERT INTO ' . $self->dbh->quote_identifier( $table->sql );
}

method _columns_clause {
    my $dbh  = $self->dbh;
    
    return '(' .
    join (q[, ], map { $dbh->quote_identifier( $_->column->name ) } $self->attribute_order) .
    ')';
}

method _values_clause {
    my $dbh  = $self->dbh;
    
    return 'VALUES (' .
    join (',', ('?') x scalar $self->attribute_order) .
    ')';
}



1;
