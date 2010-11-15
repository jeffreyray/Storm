package Storm::Transaction;
use Moose;
use MooseX::StrictConstructor;

use Storm::Types qw( Storm );

has 'orm' => (
    is => 'rw',
    isa => Storm,
    required => 1,
);

has 'code' => (
    is => 'rw'      ,
    isa => 'CodeRef',
    required => 1   ,
);


sub BUILDARGS {
    my $class = shift;
    
    if (@_ == 2) {
        { orm => $_[0], code => $_[1] }
    }
    else {
        __PACKAGE__->SUPER::BUILDARGS(@_);
    }
}

sub commit {
    my $self = shift;
    my $dbh  = $self->orm->source->dbh;
    my $comvar = $dbh->{AutoCommit};
    
    $dbh->{AutoCommit} = 0;
    eval { &{ $self->code }( $self ) };
    $@ ? $dbh->rollback : $dbh->commit;
    $dbh->{AutoCommit} = $comvar;
    
    confess $@ if $@;
    return 1;
}



no Moose;
__PACKAGE__->meta->make_immutable;
1;
