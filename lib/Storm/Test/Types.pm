package Storm::Test::Types;

use MooseX::Types -declare => [qw(
    DateTime
)];

class_type DateTime,
    { class => 'DateTime' };

1;
