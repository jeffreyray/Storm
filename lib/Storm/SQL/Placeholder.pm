package Storm::SQL::Placeholder;
use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;
use MooseX::Method::Signatures;

has 'value' => (
    is => 'rw',
    predicate => 'has_value',
    clearer => 'clear_value',
);

method sql ( ) {
    return '?';
}

method bind_params ( ) {
    return $self->has_value ? $self->value : ( );
}




no Moose;
__PACKAGE__->meta->make_immutable;

1;
