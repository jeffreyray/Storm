package Storm::SQL::Placeholder;
use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

has 'value' => (
    is => 'rw',
    predicate => 'has_value',
    clearer => 'clear_value',
);

sub sql {
    return '?';
}

sub bind_params  {
    my ( $self ) = @_;
    return $self->has_value ? $self->value : ( );
}




no Moose;
__PACKAGE__->meta->make_immutable;

1;
