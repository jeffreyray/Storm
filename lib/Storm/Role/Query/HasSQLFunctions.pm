package Storm::Role::Query::HasSQLFunctions;
use Moose::Role;
use MooseX::Method::Signatures;

use Storm::SQL::Literal;
use Storm::SQL::Placeholder;
use Storm::SQL::Function;

method function ( Str $function, @args ) {   
    # perform substitution on arguments
    @args = $self->args_to_sql_objects( @args );
    
    my $element = Storm::SQL::Function->new( $function, @args );
    return $element;
}

no Moose::Role;
1;
