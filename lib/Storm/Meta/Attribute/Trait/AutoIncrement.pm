package Storm::Meta::Attribute::Trait::AutoIncrement;
use Moose::Role;

use MooseX::Types::Moose qw( Int );

before '_process_options' => sub {
    my $class   = shift;
    my $name    = shift;
    my $options = shift;
  
    $options->{isa} ||= Int;
    $options->{column} ||= { };
    $options->{column}{auto_increment} = 1;
};


package Moose::Meta::Attribute::Custom::Trait::AutoIncrement;
sub register_implementation { 'Storm::Meta::Attribute::Trait::AutoIncrement' };
1;
