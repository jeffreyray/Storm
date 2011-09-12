package Storm::Role::Query;
use Moose::Role;

use Storm::Types qw( Storm );
use MooseX::Types::Moose qw( ClassName );

has 'orm' => (
    is  => 'ro',
    isa => Storm,
    required => 1,
);

has 'class' => (
    is  => 'ro',
    isa => ClassName,
    required => 1,
);

sub BUILDARGS {
    my $class = shift;
    
    # parse arguments
    if (@_ == 2 ) {
        return { orm => $_[0], class => $_[1] }
    }
    # otherwise pass upwords to deal with
    else {
        return __PACKAGE__->SUPER::BUILDARGS(@_);
    }
}

sub dbh  {
    $_[0]->orm->source->dbh;
}

no Moose::Role;
1;
