package Storm::Role::CanDeflate;

use Moose::Role;
use MooseX::Method::Signatures;

method _deflate_values ( $atts_ref, $values_ref ) {

    my @deflated_values;    
    for my $i( 0..$#{$atts_ref} ) {
        push @deflated_values, $self->orm->policy->deflate_value($atts_ref->[$i], $values_ref->[$i]);
    }
    
    return @deflated_values;
}

no Moose::Role;
1;
