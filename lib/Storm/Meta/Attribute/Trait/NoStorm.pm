package Storm::Meta::Attribute::Trait::NoStorm;
use Moose::Role;

before '_process_options' => sub {
    my $class   = shift;
    my $name    = shift;
    my $options = shift;
  
    $options->{column} = undef;  
};

package Moose::Meta::Attribute::Custom::Trait::NoStorm;
sub register_implementation { 'Storm::Meta::Attribute::Trait::NoStorm' };
1;
