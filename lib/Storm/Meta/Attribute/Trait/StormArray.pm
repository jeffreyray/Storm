package Storm::Meta::Attribute::Trait::StormArray;
use Moose::Role;



package Moose::Meta::Attribute::Custom::Trait::StormArray;
sub register_implementation { 'Storm::Meta::Attribute::Trait::StormArray' };
1;
