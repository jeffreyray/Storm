package Storm::SQL::Function;

use Moose;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;
use MooseX::Method::Signatures;

use MooseX::Types::Moose qw( ArrayRef Str );

use Storm::SQL::Parameter;
use Storm::SQL::Placeholder;

has 'function' => (
    is => 'rw',
    isa => Str,
    required => 1,
);

has '_args' => (
    is      => 'ro'      ,
    isa     => ArrayRef,
    default => sub { [] },
);

sub BUILDARGS
{
    my $class = shift;
    my $name = shift;
    my @args = @_;
    
    return {
        function => $name,
        _args   => \@args,
    };
    
}

method sql {
    my $sql = '';
    $sql .= uc $self->function;
    $sql .= '(';
    $sql .= join  ", ", map { $_->sql } @{$self->_args};
    $sql .= ')';
    return $sql;
}

method bind_params ( ) {
    return
        ( map { $_->bind_params() }
          grep { $_->can('bind_params') }
          @{$self->_args}
        );
}



no Moose;
__PACKAGE__->meta()->make_immutable();
1;
