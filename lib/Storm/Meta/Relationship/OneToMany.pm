package Storm::Meta::Relationship::OneToMany;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Method::Signatures;

extends 'Storm::Meta::Relationship';

has 'foreign_key' => (
    is       => 'rw' ,
    isa      => 'Maybe[Str]',
    writer   => '_set_foreign_key'  ,
);


method _iter_method ( $instance ) {
    my $orm = $instance->orm;
    confess "$instance must exist in the database" if ! $orm;
    
    my $foreign_key = $self->foreign_key ? $self->foreign_key : $self->associated_class->meta->primary_key->column->name;
   
    my $query = $orm->select_query($self->foreign_class);
    $query->where("`$foreign_key`", '=', $self->associated_class->meta->primary_key->get_value($instance));
    $query->results;
}


method _build_handle_methods ( ) {
    
    my %methods;
    
    for my $method_name ($self->_handles) {
        my $action = $self->get_handle($method_name);
        my $code_ref;
        if ($action eq 'iter'  ) { $code_ref = sub { $self->_iter_method(@_) } }
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
