package Storm::Meta::Class::Trait::AutoTable;
use Moose::Role;

around '_build_storm_table' => sub {
    my $orig = shift;
    my $self = shift;
    return (split /::/, $self->name)[-1];
};

package Moose::Meta::Class::Custom::Trait::AutoTable;
sub register_implementation { 'Storm::Meta::Class::Trait::AutoTable' };
1;
