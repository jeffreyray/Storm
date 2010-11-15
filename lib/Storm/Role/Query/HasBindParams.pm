package Storm::Role::Query::HasBindParams;
use Moose::Role;

use MooseX::Types::Moose qw( ArrayRef );

has '_bind_params' =>(
    is => 'ro',
    isa => ArrayRef,
    default => sub { [] },
    init_arg => undef,
    traits => [qw( Array )],
    handles  => {
        '_add_bind_param' => 'push', 
    },
);

no Moose::Role;
1;
