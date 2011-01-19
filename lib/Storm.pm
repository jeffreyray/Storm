package Storm;

our $VERSION = '0.04';
our $AUTHORITY = 'cpan:JHALLOCK';

use Moose;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;
use MooseX::Method::Signatures;

use Storm::Aeolus;
use Storm::LiveObjects;
use Storm::Query::Delete;
use Storm::Query::Insert;
use Storm::Query::Lookup;
use Storm::Query::Refresh;
use Storm::Query::Select;
use Storm::Query::Update;
use Storm::Source;
use Storm::Transaction;

use Storm::Types qw( StormAeolus StormLiveObjects StormPolicyObject StormSource );
use MooseX::Types::Moose qw( CodeRef ClassName );


has 'aeolus' => (
    is => 'rw',
    isa => StormAeolus,
    lazy => 1,
    default => sub { Storm::Aeolus->new( storm => $_[0] ) },
);

has 'live_objects' => (
    is  => 'ro',
    isa => StormLiveObjects,
    default => sub { Storm::LiveObjects->new },
);

has 'policy' => (
    is  => 'rw',
    isa => StormPolicyObject,
    default => sub { Storm::Policy::Object->new },
    coerce => 1,
);

has 'source' => (
    is  => 'rw',
    isa => StormSource,
    coerce => 1,
);

method delete ( @objects ) {
    my %queries;
    
    for my $o ( @objects ) {
        my $class = ref $o;
        $queries{$class} ||= $self->delete_query( $class );
        $queries{$class}->delete( $o );
    }
    
    return 1;
}



method delete_query ( ClassName $class ) {
    Storm::Query::Delete->new( $self, $class );
}



method do_transaction ( CodeRef $code ) {
    $self->new_transaction($code)->commit;
}



method insert ( @objects ) {
    my %queries;
    
    for my $o ( @objects ) {
        my $class = ref $o;
        $queries{$class} ||= $self->insert_query( $class );
        $queries{$class}->insert( $o );
    }
    
    return 1;
}



method insert_query ( ClassName $class ) {
    Storm::Query::Insert->new( $self, $class );
}



method lookup ( ClassName $class, @ids ) {
    my $q = $self->lookup_query( $class );
    my @objects = map { $q->lookup( $_ ) } @ids;
    
    if ( @objects > 1 ) {
        return @objects;
    }
    else {
        return wantarray ? @objects : $objects[0];
    }
}


method lookup_query ( ClassName $class ) {
    Storm::Query::Lookup->new( $self, $class );
}


method new_scope ( ) {
    $self->live_objects->new_scope;
}


method new_transaction ( CodeRef $code ) {
    Storm::Transaction->new( $self, $code );
}


method refresh ( @objects ) {
    my %queries;
    
    for my $o ( @objects ) {
        my $class = ref $o;
        $queries{$class} ||= $self->refresh_query( $class );
        $queries{$class}->refresh( $o );
    }
    
    return 1;
}



method refresh_query ( ClassName $class ) {
    Storm::Query::Refresh->new( $self, $class );
}



method select ( ClassName $class, @options ) {
    $self->select_query( $class );
}



method select_query ( ClassName $class ) {
    Storm::Query::Select->new( $self, $class );
}



method update ( @objects ) {
    my %queries;
    
    for my $o ( @objects ) {
        my $class = ref $o;
        $queries{$class} ||= $self->update_query( $class );
        $queries{$class}->update( $o );
    }
    
    return 1;
}

method update_query ( ClassName $class ) {
    Storm::Query::Update->new( $self, $class );
}

no Moose;
1;




__END__

=pod

=head1 NAME

Storm - Object-relational mapping

=head1 TUTORIAL

If you're new to L<Storm> check out L<Storm::Tutorial>.

=head1 SYNOPSIS

    package Foo;

    use Storm::Builder;

    __PACKAGE__->meta->table('Foo');

    has 'id' => ( is => 'rw', traits => [qw( PrimaryKey AutoIncrement )] );

    has 'label' => ( is => 'rw' );



    # and then ....

    package main;

    use Storm;

    # connect to a database
    $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );

    $o = Foo->new( label => 'Storm Enabled Object' );

    # store object
    $storm->insert( $o );

    # update object
    $o->label( 'Updated Object' );
    $storm->update( $o );

    # sync object with database
    $storm->refresh( $o );

    # lookup object in database
    $o = $storm->lookup( 'Foo', 1 );

    # search for objects in database
    $query = $storm->select( 'Foo' );
    $query->where( '.label', '=', 'Updated Object' )
    $iter  = $query->results;
    @results = $iter->all;

    # delete objects
    $storm->delete( $o );

    
=head1 DESCRIPTION

L<Storm> is a Moose based library for storing and retrieving objects from a
L<DBI> connection.

=head1 ALPHA VERSION

*THIS IS NEW SOFTWARE. IT IS STILL IN DEVELOPMENT. THE API MAY CHANGE IN FUTURE
VERSIONS WITH NO NOTICE.*


=head1 ATTRIBUTES

=over 4

=item aeolus

Read-only.

A L<Storm::Aeolus> object for installing/uninstalling database tables.

=item live_objects

Read-only.

A L<Storm::LiveObjects> object for tracking the set of live objects. Creates
scope objects to help ensure that objects are not garbage collected. This is
used internally and you typically shouldn't need to access it yourself. It
is documented here for completeness.

=item policy

The policy determines how types are defined in the database and can be used
to customize how types are inflated/deflated. See L<Storm::Policy> for more
details.

=item source

Required.

The L<Storm::Source> object responsible for spawning active database handles. A
Storm::Source object will be coerced from a ArrayRef or Hashref.

=back

=head1 METHODS

=over 4

=item delete @objects

Deletes the objects from the database.

=item delete_query $class

Returns a L<Storm::Query::Delete> instance for deleting objects of type $class
from the database.

=item do_transaction \&func

Creates and commits a L<Storm::Transaction>. The \&func will be called within
the transaction.

=item insert @objects
  
Insert objects into the database.

=item insert_query $class
  
Returns a L<Storm::Query::Insert> instance for inserting objects of type $class
into the database.

=item lookup $class, @ids
  
Retrieve objects from the database.

=item lookup_query $class
  
Returns a L<Storm::Query::Lookup> instance for retrieving objects of type $class
from the database.

=item new_transaction \&func
  
Returns a new transaction. \&func is the code to be called within the
transaction.

=item refresh @objects
  
Update the @objects with data from the database. 

=item refresh_query $class
  
Returns a L<Storm::Query::Refresh> instance for refresh objects of type $class.

=item select $class, @objects
  
Synonamous with C<select_query>. Provided for consistency.

=item select_query $class
  
Returns a L<Storm::Query::Select> instance for selecting objects from the
database.

=item update @objects

Update the @objects in the database.

=item update_query

Returns a L<Storm::Query::Select> instance for updating objects in the
database.

=back

=head1 SEE ALSO

=head2 Similar modules

=over 4

=item L<KiokuDB>

=item L<Fey::ORM>

=item L<Pixie>

=item L<DBM::Deep>

=item L<OOPS>

=item L<Tangram>

=item L<DBIx::Class>

=item L<MooseX::Storage>

=back

=head1 CAVEATS/LIMITATIONS

=head2 Databases

L<Storm> has only been tested using MySQL and SQLite.

=head1 BUGS

Please report bugs by going to http://blue-aeolus.com/storm/

=head1 AUTHOR

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

Special thanks to Yuval Kogman and Dave Rolsky, for who without their talented
work and inspiration this library would not be possible.

The code for managing the live object set and the scope relies on modified
code written by Yuval Kogman for L<KiokuDB>. Documentation for this feature was
also taken from L<KiokuDB>.

The code for managing the policy and generating sql statements relies on
modified code written by Dave Rolsky for L<Fey> and L<Fey::ORM>.

=head1 COPYRIGHT

    Copyright (c) 2010 Jeffrey Ray Hallock. All rights reserved.
    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut








