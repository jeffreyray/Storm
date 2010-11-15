package Storm::Query::Select::Iterator;

use Devel::GlobalDestruction;
use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

use Storm::Types qw( DBIStatementHandle Storm StormSelectQuery );
use MooseX::Types::Moose qw( ArrayRef Str );

with 'Storm::Role::Iterator';
with 'Storm::Role::CanInflate';

has 'orm' => (
    is  => 'ro',
    isa => Storm,
    required => 1,
);

has select => (
    is => 'ro',
    isa => StormSelectQuery,
    required => 1,
);

has _sql => (
    is         => 'rw' ,
    isa        => 'Str',
);

has _sth => (
    is => 'rw',
    isa => DBIStatementHandle,
    lazy_build => 1,
    init_arg   => undef,
);

has '_attributes' => (
    isa => ArrayRef,
    traits => [qw( Array )],
    writer => '_set_attributes',
    handles   => {
        add_attributes => 'push',
        _attributes => 'elements',
    }
);

has 'bind_params' =>(
    isa       => ArrayRef,
    writer    => '_set_bind_params',
    traits    => [qw( Array )],
    default => sub { [] },
    handles  => {
        'bind_params' => 'elements',
    },
);


sub BUILDARGS {
    my $class = shift;
    my $query = shift;
    my @user_args = @_;
    return { select => $query, orm => $query->orm, bind_params => \@user_args };
}

sub BUILD {
    my $self = shift;
    $self->_set_sql( $self->select->_sql );
    $self->_set_attributes( [$self->select->attribute_order] );
}



sub _build__sth {
    my  $self   = shift;

    my $dbh = $self->select->dbh;
    my $sth = $dbh->prepare( $self->_sql );
    $sth->execute( $self->bind_params );
    
    return $sth;
}


sub _get_next_result {
    my  $self = shift;
    my  $select = $self->select;
    my  $class  = $select->class;
    
    # TODO: WRITE BENCHMARCKS FOR DIFFERENT SCENARIOS
    # I think it might be better here to fetch only the ids of the
    # matching records, and then use a lookup query to retrieve the record
    # if the object is cached locally, there is no need to fetch the data
    # from the database ( here we retrieving the data for all records that
    # match the query, then ignoring it for records the are cached )
    # the downside to this is that the result is issuing multiple lookup
    # commands will result in sending more reqests to the database, which could
    # potentially be slower
   
    my  $sth  = $self->_sth;
    my  @data = $sth->fetchrow_array;
    return undef if ! @data;
    

    # see if the object exists in the live object cache
    my $live = $self->orm->live_objects;
    my $cached  = $live->get_object($class, $data[0]);
    return $cached if $cached;
    
    # if not, the inflate the object
    my %struct;
    my @attributes = $self->_attributes;
    @data = $self->_inflate_values(\@attributes, \@data);
    @struct{map {$_->name } $self->_attributes} = @data;
    my $object = "$class"->new(%struct);
    $object->_set_orm( $self->orm );
    
    # store the object in the live object cache
    $live->insert($object) if $live->current_scope;
    
    return $object;
}

sub reset {
    my $self = shift;
    $self->_reset_index(0);
    $self->_finish_handle;
    $self->_clear_sth;
    return;
}

sub DEMOLISH
{
    my $self = shift;

    $self->_finish_handle();
}

sub _finish_handle {
    my $self = shift;

    return if in_global_destruction();
    return if ! $self->_has_sth();

    $self->_sth()->finish() if $self->_sth()->{Active};
}



no Moose;
__PACKAGE__->meta()->make_immutable();

1;
