package Storm::Meta::Attribute::Trait::PrimaryKey;
use Moose::Role;



package Moose::Meta::Attribute::Custom::Trait::PrimaryKey;
sub register_implementation { 'Storm::Meta::Attribute::Trait::PrimaryKey' };
1;
