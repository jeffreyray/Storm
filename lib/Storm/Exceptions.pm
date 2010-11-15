package Storm::Exceptions;
use MooseX::Declare;

class StormException {
    with 'Throwable';
    has 'error' => (
        is => 'rw',
        isa => 'Str',
        default => '',
    );
    has 'details' => (
        is => 'rw',
        isa => 'Str',
    );
}


1;
