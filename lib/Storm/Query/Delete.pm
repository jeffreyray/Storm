package Storm::Query::Delete;

use Moose;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;
use MooseX::Method::Signatures;

with 'Storm::Role::Query';
with 'Storm::Role::Query::IsExecutable';

method _sql ( ) {
    my $table = $self->class->meta->storm_table->sql;
    my $column = $self->class->meta->primary_key->column->sql;
    return  qq[DELETE FROM $table WHERE $column = ?];
}


method delete ( @objects ) {
    my $sth     = $self->_sth;
    
    for my $o (@objects) {
        $sth->execute(  $o->meta->primary_key->get_value( $o ) );
        
        # throw exception if insert failed
        if ($sth->err) {
            confess qq[could not delete $o from database: ] .  $sth->errstr;
        }
    }
    
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;


1;

