package Storm::Policy;
use strict;
use warnings;

our $VERSION = '0.01';

use Storm::Policy::Object;

use Sub::Exporter -setup => {
    exports => [qw/Policy define deflate inflate transform /],
    groups  => { default => [qw/Policy define deflate inflate transform /] },
};

{
    my %Policies;

    sub Policy {
        my $caller = shift;
        return $Policies{$caller} ||= Storm::Policy::Object->new;
    }
}


sub define {
    my $class = caller();
    my ( $type, $definition ) = @_;
    $class->Policy()->add_definition( $type => $definition );
}

sub deflate (&) {
    return ( deflate => $_[0] );
}

sub inflate (&) {
    return ( inflate => $_[0] );
}

sub transform {
    my $class = caller();
    my $type  = shift;
    $class->Policy()->add_transformation( $type => {@_} );
}



1;
