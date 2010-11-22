package Storm::Role::CanInflate;

use Moose::Role;
use MooseX::Method::Signatures;

method _inflate_values ( $atts_ref, $values_ref ) {
    my @inflated_values;    
    for my $i( 0..$#{$atts_ref} ) {
        push @inflated_values, $self->orm->policy->inflate_value($self->orm, $atts_ref->[$i], $values_ref->[$i]);
    }
    
    return @inflated_values;
}

no Moose::Role;
1;
