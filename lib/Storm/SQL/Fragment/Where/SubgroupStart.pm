package Storm::SQL::Fragment::Where::SubgroupStart;
use Moose;



sub sql { return '(' };



no Moose;
__PACKAGE__->meta()->make_immutable();