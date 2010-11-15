package Storm::SQL::Fragment::Where::SubgroupEnd;
use Moose;



sub sql { return ')' };



no Moose;
__PACKAGE__->meta()->make_immutable();

1;

