package Storm::Meta::Relationship::ManyToMany;
use Moose;
use MooseX::StrictConstructor;
use MooseX::Method::Signatures;

use MooseX::Types::Moose qw( Str Undef);

extends 'Storm::Meta::Relationship';

has 'linking_table' => (
    is => 'rw',
    isa => Str,
    writer => '_set_linking_table',
    required => 1
);

has 'primary_key' => (
    is => 'rw' ,
    isa => Str|Undef,
    writer => '_set_primary_key',
);

has 'foreign_key' => (
    is => 'rw' ,
    isa => Str|Undef,
    writer => '_set_foreign_key',
);

method _add_method ( $instance, @objects ) {
    my $orm = $instance->orm;
    confess "$instance must exist in the database" if ! $orm;
    
    my $table = $self->linking_table;
    my $primary_key = $self->primary_key ? $self->primary_key : $self->associated_class->meta->primary_key->column->name;
    my $foreign_key = $self->foreign_key ? $self->foreign_key : $self->foreign_class->meta->primary_key->column->name;
    
    my $sth = $orm->source->dbh->prepare("INSERT INTO $table ($primary_key, $foreign_key) VALUES (?, ?)");
    eval {
        for (@objects) {
            $sth->execute($instance->identifier, $_->identifier);
        }
    };
    confess $@ if $@;

    return 1;
}

method _remove_method ( $instance, @objects ) {
    my $orm = $instance->orm;
    confess "$instance must exist in the database" if ! $orm;
    
    my $table = $self->linking_table;
    my $primary_key = $self->primary_key ? $self->primary_key : $self->associated_class->meta->primary_key->column->name;
    my $foreign_key = $self->foreign_key ? $self->foreign_key : $self->foreign_class->meta->primary_key->column->name;
    
    my $sth = $orm->source->dbh->prepare("DELETE FROM $table WHERE $primary_key = ? AND $foreign_key = ?");
    
    for (@objects) {
        $sth->execute($instance->identifier, $_->identifier);
    }
    
    return 1;
}

method _iter_method ( $instance ) {
    my $orm = $instance->orm;
    confess "$instance must exist in the database" if ! $orm;
    
    my $link_table     = $self->linking_table;
    my $foreign_table  = $self->foreign_class->meta->table->name;

    my $primary_key = $self->primary_key ? $self->primary_key : $self->associated_class->meta->primary_key->column->name;
    my $foreign_key = $self->foreign_key ? $self->foreign_key : $self->foreign_class->meta->primary_key->column->name;
    my $foreign_primary_key = $self->foreign_class->meta->primary_key->column->name;
    
    my $query = $orm->select($self->foreign_class);
    $query->join($link_table);
    $query->where("`$link_table.$foreign_key`", '=', "`$foreign_table.$foreign_primary_key`");
    $query->where("`$link_table.$primary_key`", '=', $self->associated_class->meta->primary_key->get_value($instance));
    return $query->results;
}


method _build_handle_methods ( ) {
    my %methods;
    
    for my $method_name ($self->_handles) {
        my $action = $self->get_handle($method_name);
        my $code_ref;
        if    ($action eq 'add')    { $code_ref = sub { &_add_method($self, @_)    } }
        elsif ($action eq 'remove') { $code_ref = sub { &_remove_method($self, @_) } }
        elsif ($action eq 'iter'  ) { $code_ref = sub { &_iter_method($self, @_)   } }
        else {
            confess "could not create handle $method_name because $action is not a valid action"
        }
        
        # wrap the method
        my $wrapped_method = $self->associated_class->meta->method_metaclass->wrap(
            name         => $method_name,
            package_name => $self->associated_class,
            body         => $code_ref,
        );
        
        $methods{$method_name} = $wrapped_method;
    }
    
    
    return \%methods;
}


no Moose;
__PACKAGE__->meta()->make_immutable();
1;
