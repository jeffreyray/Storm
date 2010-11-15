package Storm::Source::Manager;

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;
use MooseX::Method::Signatures;

use Storm::Types qw( MooseAttribute StormEnabledClassName StormMetaRelationship StormSource );

use Storm::Source::Manager::SQL;

has 'source' => (
    is => 'rw',
    isa => StormSource,
    required => 1,
    weak_ref => 1,
);

has 'install_notice' => (
    is        => 'rw'     ,
    isa       => 'Maybe[CodeRef]',
    reader    => '_install_notice',
    writer    => 'set_install_notice',
);

has 'uninstall_notice' => (
    is        => 'rw'       ,
    isa       => 'Maybe[CodeRef]',
    reader    => '_uninstall_notice',
    writer    => 'set_uninstall_notice',
);

has 'error_prompt' => (
    is        => 'rw'       ,
    isa       => 'Maybe[CodeRef]',
    reader    => '_error_prompt',
    writer    => 'set_error_prompt',
);


sub BUILDARGS {
    my $class = shift;
    
    # one argument form, just a datasource
    if (@_ == 1 && ! ref $_[0] ) {
        return { data_source => $_[0] };
    }
    else {
        return $class->SUPER::BUILDARGS(@_);
    } 
}

method install_class ( StormEnabledClassName $class ) {
    $self->install_class_table( $class );
    $self->install_linking_tables( $class );
    return 1;
}


method install_class_table ( StormEnabledClassName $class ) {
    my $sql = $self->table_definition( $class );
    
    $self->source->dbh->do( $sql );
    if ( $self->source->dbh->err ) {
        confess $self->source->dbh->errstr;
    }
    
    return 1;
}

method install_linking_tables ( StormEnabledClassName $class ) {
    my $meta = $class->meta;
    my @relationships = map { $meta->get_relationship( $_ ) } $meta->get_relationship_list;
    
    
    
    for my $r ( @relationships ) {
        next if $r->isa( 'Storm::Meta::Relationship::OneToMany' );
        
        my $table = $r->linking_table;
        my $col1  = $r->primary_key;
        my $col2  = $r->foreign_key;
        
        # skip if the table already exists in the database
        my $infosth = $self->source->dbh->table_info( undef, undef, $table, undef);
        my @tableinfo = $infosth->fetchrow_array;
        next if @tableinfo;
        
        my $sql = 'CREATE TABLE ' . $table . ' (' . "\n";
        $sql .= "\t" . $col1 . ' ' . $self->column_definition( $meta->primary_key ) . ",\n";
        $sql .= "\t" . $col2 . ' ' . $self->column_definition( $r->foreign_class->meta->primary_key ) . "\n";
        $sql .= ');';
        
        $self->source->dbh->do( $sql );
        if ( $self->source->dbh->err ) {
            confess $self->source->dbh->errstr;
        }
    }
}

method column_definition ( MooseAttribute $attr ) {
    my $type_constraint = $attr->type_constraint;
    my $definition = $type_constraint ? undef : 'VARCHAR(64)';
    
    while ( ! $definition ) {
        # check to see if there is a definition for the type constraint
        if ( $self->source->policy->has_definition( $type_constraint->name ) ) {
            $definition = $self->source->policy->get_definition( $type_constraint->name );
        }
        # if not, check the parent type constraint for definitions
        else {
            $type_constraint = $type_constraint->parent;
            $definition = 'VARCHAR(64)' if ! $type_constraint;
        }
    }
    
    return $definition;
}

method table_definition ( StormEnabledClassName $class ) {
    my $meta = $class->meta;
    my $table = $meta->table;
    
    
    my %defmap; # definition map
    
    # get the definition for each attribute
    for my $attr ( map { $meta->get_attribute($_) } $meta->get_attribute_list ) {
        next if ! $attr->column;
        $defmap{ $attr->name } = {
            column => $attr->column,
            definition => $self->column_definition( $attr ),
        };
    }
    
    my $sql = 'CREATE TABLE ' . $table->name . ' (' . "\n";
    
    my @definitions;
    
    # primary key definition
    if ( $meta->primary_key ) {
        my $def = delete $defmap{ $meta->primary_key->name };
        my $string = "\t" . $def->{column}->name . " ";
        $string .= $def->{definition};
        $string .= ' PRIMARY KEY';
        $string .= ' ' . $self->source->auto_increment_token if $meta->primary_key->does('AutoIncrement');
        push @definitions, $string;
    }
    for my $attname ( sort keys %defmap ) {
        my $string = "\t" . $defmap{ $attname }->{column}->name . " ";
        $string .= $defmap{ $attname }->{definition};
        push @definitions, $string;
    }
   
    $sql .= join ",\n", @definitions;
    #$sql .= ",\n\tPRIMARY KEY (" . $meta->primary_key->column->name . ')' if $meta->primary_key;
    $sql .= "\n);";
    
    return $sql;
}



method install ( $sql_source ) {
    
    my $sql = Storm::Source::Manager::SQL->new_from_source( $sql_source );
    my $dbh = $self->source->dbh;
    
    { # new block for the redo statement
        if ( $self->_n_tables_in_database ) {
            
            my $result = $self->_present_error(
                qq[Tables exist in the database - continue anyways?]
            );
            
            next if ! $result;                                       # ignore
            redo if defined $result && $result == 1;                 # retry
            return undef if defined $result && $result == -1;        # abort
            confess q[bad result $result - must be undef, 0, 1, -1]; # bad response
        }
    }
    
    # execute schema statements
    my $num_statements = scalar $sql->statements;
    
    my $x = 1;
    for ( $sql->statements ) {
        
        # execute the statement
        if ( $dbh->do($_) ) {
            
            # send a notice if one is set
            if ($self->_install_notice) {
                &{$self->_install_notice}($self, $x, $num_statements);
            }
        }
        # throw an error if execution fails
        else {
            my $result = $self->_present_error($dbh->errstr);
            $x++ and next if ! $result;                              # ignore
            redo if defined $result && $result == 1;                 # retry
            return undef if defined $result && $result == -1;        # abort
            confess q[bad result $result - must be undef, 0, 1, -1]; # bad response
        }
        
        $x++;
    }
    
    return 1;
}

method uninstall ( ) {
    my $dbh  = $self->source->dbh;
    my @tables = $self->source->tables;

    
    # if working with mysql we need to disable foreign key checks before we
    # delete tables otherwise the database will give us an error
    if ($dbh->{Driver} eq 'mysql') { # new block for the redo statement
        if (! $dbh->do("set foreign_key_checks=0") ) {
            my $result = $self->_present_error($dbh->errstr);
            redo if defined $result && $result == 1;                 # retry
            return undef if defined $result && $result == -1;        # abort
            #confess q[bad result $result - must be undef, 0, 1, -1]; # bad response
        }
    }

    # drop all of the tables that exist in the database
    my $x = 1;
    my $num_tables = scalar @tables;
    for my $table (@tables) {
        # execute the statement
        if ($dbh->do("DROP TABLE $table")) {
            if ($self->_uninstall_notice) {
                &{$self->_uninstall_notice}($self, $x, $num_tables);
            }
        }
        # throw an error if execution fails
        else {
            my $result = $self->_present_error($dbh->errstr);
            $x++ and next if ! $result;                              # ignore
            redo if defined $result && $result == 1;                 # retry
            last if defined $result && $result == -1;        # abort
            confess q[bad result $result - must be undef, 0, 1, -1]; # bad response
        }
        $x++;
    }
    
    # enable foreign key checks again
    if ($dbh->{Driver} eq 'mysql') { # new block for the redo statement
        if (! $dbh->do("set foreign_key_checks=1" ) ) {
            my $result = $self->_present_error($dbh->errstr);
            redo if defined $result && $result == 1;                 # retry
            return undef if defined $result && $result == -1;        # abort
        }
    }
    
    # if we made it all the way here, the then the uninstall was successful
    return 1;
}

method clean_install ( @args ) {
    $self->uninstall;
    $self->install( @args );
}

method _n_tables_in_database ( ) {
    my @tables = $self->source->tables;
    return scalar @tables;
}

sub _present_error {
    my $self = shift;
   
    # ignore the error
    # if the user has not provided an error function
    return undef if ! $self->_error_prompt;
    
    my $result = &{$self->_error_prompt}($self, @_);
    return $result;
}

no Moose;
no Moose::Util::TypeConstraints;
__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Gi::Installer::Database - Easily implement and remove a databae schema

=head1 SYNOPSIS

    use DBI;
    use Gi::Installer::Database;
    
    $dbi = DBI->connect(@connection_args);
    
    $schema =
        Gi::Installer::Database::Schema->new_from_file('/path/to/file.ext');
    
    $installer = Gi::Installer::Database->new($dbh, $schema);  
    
    $installer = Gi::Installer::Database->new(dbh => $dbh, schema => $schema);
    
    $installer = Gi::Installer::Database->new(
        dbh    => [@connection_args]
        schema => '/path/to/file.ext/
    );
    
    $installer->set_install_notice(
        ($installer, $step, $total) = @_;
        print "$step of $total statements executed\n";
    );
    
    $installer->set_uninstall_notice(
        ($installer, $step, $total) = @_;
        print "$step of $total tables removed\n";
    );
    
    $installer->set_error_prompt(
        ($installer, $message) = @_;
        print "ERROR: $message [A]bort, [R]etry, [Ignore]: ";
        my $response = <STDIN>
        return -1 if $response =~ /^a/i;
        return 0 if $response =~ /^i/i;
        return 1 if $response =~ /^r/i;
        return -1;
    );
    
    $installer->install;
    
    $installer->uninstall;

=head1 DESCRIPTION

Implement a database structure by executing a series of sql statements that can
be read from a variable, file path, or file handle.

=head1 METHODS

=over 4

=item $class->new($dbh, $schema)

=item $class->new(dbh => $dbh, schema => $schema);

=item $class->new(\@connect_args, $file_handle_or_path)

Creates a new installer object that will operate on the given database
connection. DBI objects will be coerced from array refernces and schema objects
will be coerced from file paths and file handles.

=item $installer->dbh

Returns the the database handler, which is a C<DBI::db> object.

=item $installer->schema

Returns the schema, which is a C<Gi::Installer::Database::Schema> object.

=item $installer->set_error_prompt(\&error_prompt)

Sets the callback that will be executed when the installer encounters an error.
The callback function will be call with the two parameters: $installer,
$error_message. If the callback function returns -1 the installation will be
aborted, 0 or undef and the the error will be ignored and installation will
continue, and 1 to retry executing the offending action.

=item $installer->set_install_notice(\&notice_function)

Sets callback that will be executed after each successful (or igornored)
statement execution. The callback function will be called with three parameters:
$installer, $step, $total_steps.

=item $installer->set_uninstall_notice(\&notice_function)

Sets callback function that will be executed after each successful (or ignored)
table deletion. The callback function will be called with three parameters:
$installer, $step, $total_steps.


=back

=head1 BUGS

Please send bug reports to the email listed below.

=head1 AUTHOR

Jeffrey Ray Hallock, E<lt>jeffrey.ray at ragingpony dot comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Jeffrey Ray Hallock

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
