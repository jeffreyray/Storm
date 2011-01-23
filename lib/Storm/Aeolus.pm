package Storm::Aeolus;

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;
use MooseX::Method::Signatures;

use Storm::Types qw(
MooseAttribute
Storm
StormEnabledClassName
StormMetaRelationship
StormObjectTypeConstraint
StormSource );


has 'storm' => (
    is => 'rw',
    isa => Storm,
    required => 1,
    weak_ref => 1,
);


method column_definition ( MooseAttribute $attr ) {
    my $type_constraint = $attr->type_constraint;
    
    my $definition = $type_constraint ? undef : 'VARCHAR(64)';
    my $policy = $self->storm->policy;
    
    
    while ( ! $definition ) {
        # check to see if there is a definition for the type constraint
        if ( $policy->has_definition( $type_constraint->name ) ) {
            $definition = $policy->get_definition( $type_constraint->name );
        }
        # check to see if the type constraint is Storm enabled class
        elsif ( is_StormObjectTypeConstraint( $type_constraint ) ) {
            $definition = $self->column_definition( $type_constraint->class->meta->primary_key );
        }
        # if not, check the parent type constraint for definitions
        else {
            $type_constraint = $type_constraint->parent;
            $definition = 'VARCHAR(64)' if ! $type_constraint;
        }
    }
    
    return $definition;
}

method find_foreign_attributes ( StormEnabledClassName $class ) {
    my $meta = $class->meta;
    
    # find the foreign attributes
    my @foreign_attributes;
    for my $attr ( map { $meta->get_attribute($_) } $meta->get_attribute_list ) {
        next if ! $attr->column;
        
        my $type_constraint = $attr->type_constraint;
        
        while ( $type_constraint ) {
            if ( is_StormObjectTypeConstraint( $type_constraint ) ) {
                push @foreign_attributes, [$attr, $type_constraint->class];
                last;
            }
            else {
                $type_constraint = $type_constraint->parent;
            }
        }
    }
    return @foreign_attributes;
}

method install_class ( StormEnabledClassName $class ) {
    $self->install_class_table( $class );
    $self->install_junction_tables( $class );
    return 1;
}

method install_class_table ( StormEnabledClassName $class ) {
    my $sql = $self->table_definition( $class );
    
    my $dbh = $self->storm->source->dbh;
    $dbh->do( $sql );
    print $sql, "\n";
    confess $dbh->errstr if $dbh->err;
    return 1;
}


method install_foreign_keys ( StormEnabledClassName $class ) {
    $self->install_foreign_keys_to_class_table( $class );
    #$self->install_foreign_keys_to_junction_tables( $class );
}

method install_foreign_keys_to_class_table ( StormEnabledClassName $class ) {
    my $meta = $class->meta;
    
    # find the foreign attributes
    my @foreign_attributes = $self->find_foreign_attributes( $class );

    
    my $dbh = $self->storm->source->dbh;
    
    my @key_statements;
    
    for ( @foreign_attributes ) {
        my ( $attr, $foreign_class ) = @$_;
        
        my $string = "\tADD FOREIGN KEY (" . $attr->column->name . ")\n";
        $string .= "\t\tREFERENCES " . $foreign_class->meta->storm_table->name;
        $string .= '(' . $foreign_class->meta->primary_key->column->name . ')';
        push @key_statements, $string;
    }
    
    my $sql = 'ALTER TABLE ' . $class->meta->storm_table->name . "\n";
    $sql .= join ",\n", @key_statements;
    $sql .= ';';
    
    $dbh->do( $sql );
    confess $dbh->errstr if $dbh->err;
}

method install_junction_tables ( StormEnabledClassName $class ) {
    my $meta = $class->meta;
    my @relationships = map { $meta->get_relationship( $_ ) } $meta->get_relationship_list;
    
    my $dbh = $self->storm->source->dbh;
    
    for my $r ( @relationships ) {
        next if $r->isa( 'Storm::Meta::Relationship::OneToMany' );
        
        my $table = $r->junction_table;
        my $col1  = $r->local_match;
        my $col2  = $r->foreign_match;
        
        # skip if the table already exists in the database
        my $infosth = $dbh->table_info( undef, undef, $table, undef );
        my @tableinfo = $infosth->fetchrow_array;
        next if @tableinfo;
        
        my $sql = 'CREATE TABLE ' . $table . ' (' . "\n";
        $sql .= "\t" . $col1 . ' ' . $self->column_definition( $meta->primary_key ) . ",\n";
        $sql .= "\t" . $col2 . ' ' . $self->column_definition( $r->foreign_class->meta->primary_key ) . "\n";
        #$sql .= "\tFOREIGN KEY (" . $col1 . ") REFERENCES ";
        #$sql .= $r->foreign_class->meta->storm_table->name . '(' . $r->foreign_class->meta->primary_key->column->name . "),\n";
        #$sql .= "\tFOREIGN KEY (" . $col2 . ") REFERENCES ";
        #$sql .= $meta->storm_table->name . '(' . $meta->primary_key->column->name . ")\n";
        $sql .= ');';
        
        
        $dbh->do( $sql );
        confess $dbh->errstr if $dbh->err;
    }
}

method start_fresh ( ) {
    my $source = $self->storm->source;
    $source->disable_foreign_key_checks;
    $source->dbh->do("DROP TABLE $_") for $self->storm->source->tables;
    $source->enable_foreign_key_checks;
}


method table_definition ( StormEnabledClassName $class ) {
    my $meta = $class->meta;
    my $table = $meta->storm_table;
    
    
    my %defmap; # definition map
    
    # get the definition for each attribute
    for my $attr ( $meta->get_all_attributes ) {
        
        # TODO: Change how we identify a sotrm column here
        next if ! $attr->can('column') || ! $attr->column;
        
        $defmap{ $attr->name } = {
            column => $attr->column,
            definition => $self->column_definition( $attr ),
        };
    }
    
    my $sql = 'CREATE TABLE ' . $table->name . ' (' . "\n";
    
    my (@definitions, @key_statements);
    
    # primary key definition
    if ( $meta->primary_key ) {
        my $def = delete $defmap{ $meta->primary_key->name };
        my $string = "\t" . $def->{column}->name . " ";
        $string .= $def->{definition};
        $string .= ' PRIMARY KEY';
        $string .= ' ' . $self->storm->source->auto_increment_token if $meta->primary_key->does('AutoIncrement');
        push @definitions, $string;
    }
    
    # remaing attribute definitions
    for my $attname ( sort keys %defmap ) {
        my $string = "\t" . $defmap{ $attname }->{column}->name . " ";
        $string .= $defmap{ $attname }->{definition};
        push @definitions, $string;
    }
    
    # foreign key definitions
    #my @foreign_attributes = $self->find_foreign_attributes( $class );
    #for ( @foreign_attributes ) {
    #    my ( $attr, $foreign_class ) = @$_;
    #    
    #    my $string = "\tFOREIGN KEY (" . $attr->column->name . ") ";
    #    $string .= "REFERENCES " . $foreign_class->meta->storm_table->name;
    #    $string .= '(' . $foreign_class->meta->primary_key->column->name . ')';
    #    push @key_statements, $string;
    #}
   
    $sql .= join ",\n", @definitions;
    $sql .= ",\n" . join(",\n", @key_statements) if @key_statements;
    $sql .= "\n);";
    
    return $sql;
}


method install_model ( $model ) {
    for my $class ( $model->members ) {
        $self->install_class( $class );
    }
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Storm::Aeolus - Install classes to the database

=head1 SYNOPSIS

 $storm->aeolus->install_class_table( 'Person' );

 $storm->aeolus->install_junction_tables( 'Person' );

 $storm->aeolus->install_class( 'Person' );   


=head1 DESCRIPTION

Aeolus is the Greek god of the winds. C<Storm::Aeolus> can introspect your
object classes and create the appropriate definitions in the database. It is
important you setup a policy (see L<Storm::Policy>) for any custom types you
have created.

=head1 ATTRIBUTES

=over 4

=item storm

The L<Storm> storm instance that Aeolus should act on.

=back

=head1 METHODS

=over 4

=item install_class $class

Installs the all necessary tables for storing the class by calling
C<install_class_table> and C<install_junction_tables> on the C<$class>.

=item install_class_table $class

Installs the primary data table for the C<$class>.

=item install_junction_tables $class

Installs any junction tables necessary to store relationship information between
objects.

=item install_model $class

Calls C<install_class> for all members of the model;

=back

=head1 AUTHOR

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT

    Copyright (c) 2010 Jeffrey Ray Hallock. All rights reserved.
    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut
