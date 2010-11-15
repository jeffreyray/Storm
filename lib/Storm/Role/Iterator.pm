package Storm::Role::Iterator;

use Moose::Role;
requires qw( _get_next_result reset);

has index => (
    is       => 'ro',
    isa      => 'Int',
    default  => 0,
    traits   => [qw/Counter/],
    init_arg => undef,
    handles => {
        '_increase_index' => 'inc'   ,
        '_reset_index'    => 'reset' ,
    },
);


sub next {
    my $self   = shift;
    my $result = $self->_get_next_result();
    
    return unless $result;

    # increase the index by one
    $self->_increase_index;

    return $result;
}

sub all {
    my $self = shift;
    $self->reset if $self->index;
    return $self->remaining;
}


sub remaining {
    my $self = shift;
    
    my @result;
    while ( my $object = $self->next ) {
        push @result, $object;
    }

    return @result;
}



no Moose::Role;
1;
