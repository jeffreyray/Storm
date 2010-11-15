package Storm::SQL::Fragment::Where::Boolean;

use Moose;
use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints;

subtype 'TIMs::SQL::Types::WhereBoolean'
    => as 'Str',
    => where { return $_ =~ /^(?:and|not|or|xor)$/ };

has 'operator' => (
    is       => 'ro',
    isa      => 'TIMs::SQL::Types::WhereBoolean',
    required => 1,
);

sub BUILDARGS {
    my $class = shift;

    # one argument form
    if (@_ == 1) {
        return { operator => $_[0] };
    }
    else {
        return $class->SUPER::BUILDARGS(@_);
    }
}


sub sql {
    return uc $_[0]->operator();
}

no Moose;
__PACKAGE__->meta()->make_immutable();

1;

