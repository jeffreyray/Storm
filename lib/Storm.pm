package Storm;

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:JHALLOCK';

use Moose;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;
use MooseX::Method::Signatures;

use Storm::LiveObjects;
use Storm::Query::Delete;
use Storm::Query::Insert;
use Storm::Query::Lookup;
use Storm::Query::Refresh;
use Storm::Query::Select;
use Storm::Query::Update;
use Storm::Source;
use Storm::Transaction;

use Storm::Types qw( StormLiveObjects StormPolicyObject StormSource );
use MooseX::Types::Moose qw( CodeRef ClassName );


has 'source' => (
    is  => 'rw',
    isa => StormSource,
    coerce => 1,
);

has 'live_objects' => (
    is  => 'ro',
    isa => StormLiveObjects,
    default => sub { Storm::LiveObjects->new },
);

method delete_query ( ClassName $class ) {
    Storm::Query::Delete->new( $self, $class );
}

method insert_query ( ClassName $class ) {
    Storm::Query::Insert->new( $self, $class );
}

method lookup_query ( ClassName $class ) {
    Storm::Query::Lookup->new( $self, $class );
}

method refresh_query ( ClassName $class ) {
    Storm::Query::Refresh->new( $self, $class );
}

method select_query ( ClassName $class ) {
    Storm::Query::Select->new( $self, $class );
}

method update_query ( ClassName $class ) {
    Storm::Query::Update->new( $self, $class );
}


method delete ( @objects ) {
    my %queries;
    
    for my $o ( @objects ) {
        my $class = ref $o;
        $queries{$class} ||= $self->delete_query( $class );
        $queries{$class}->delete( $o );
    }
    
    return 1;
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

method refresh ( @objects ) {
    my %queries;
    
    for my $o ( @objects ) {
        my $class = ref $o;
        $queries{$class} ||= $self->refresh_query( $class );
        $queries{$class}->refresh( $o );
    }
    
    return 1;
}

method select ( ClassName $class, @options ) {
    $self->select_query( $class );
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

method do_transaction ( CodeRef $code ) {
    $self->new_transaction($code)->commit;
}

method new_scope ( ) {
    $self->live_objects->new_scope;
}

method new_transaction ( CodeRef $code ) {
    Storm::Transaction->new( $self, $code );
}


no Moose;
1;




__END__

=pod

=head1 NAME

Storm - Object-relational mapping

=head1 TUTORIAL

If you're new to L<Storm> check out L<Storm::Manual::Intro>.

=head1 SYNOPSIS

    package Foo;

    use Storm::Builder;

    __PACKAGE__->meta->set_table('Foo');

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
    
    $o->label( 'Updated Object' );
    
    # update object
    $storm->update( $o );
    
    # sync object with database
    $storm->refresh( $o );
    
    # lookup object in database
    $o = $storm->lookup( 'Foo', 1 );
    
    # search for objects in database
    $query = $storm->select( 'Foo' )->where( '.label', '=', 'Updated Object' )
    
    $iter  = $query->results;
    
    @results = $iter->all;
    
    
    # delete objects
    $storm->delete( $o );
    
    
=head1 DESCRIPTION

L<Storm> is a Moose based library for storing and retrieving objects from a
L<DBI> connection.


=head1 ATTRIBUTES

=over 4

=item source

This attribute is required and must be L<Storm::Source> object. A
Storm::Source object will be coerced from a ArrayRef or Hashref.

=item live_objects

Read-only.

A L<Storm::LiveObjects> object for tracking the set of live objects.


=item typemap

This is an instance L<KiokuDB::TypeMap>.

The typemap contains entries which control how L<KiokuDB::Collapser> and
L<KiokuDB::Linker> handle different types of objects.

=item allow_classes

An array references of extra classes to allow.

Objects blessed into these classes will be collapsed using
L<KiokuDB::TypeMap::Entry::Naive>.

=item allow_bases

An array references of extra base classes to allow.

Objects derived from these classes will be collapsed using
L<KiokuDB::TypeMap::Entry::Naive>.

=item allow_class_builders

If true adds L<KiokuDB::TypeMap::ClassBuilders> to the merged typemap.

It's possible to provide a hash reference of options to give to
L<KiokuDB::TypeMap::ClassBuilders/new>.

=item check_class_versions

Controls whether or not the class versions of objects are checked on load.

Defaults to true.

=item class_version_table

A table of classes and versions that is passed to the default typemap entry for
Moose/Class::MOP objects.

When a class version has changed between the time that an object was stored and
the time it's being retrieved, the data must be converted.

See L<KiokuDB::TypeMap::Entry::MOP> for more details.

=back

=head1 METHODS

=over 4

=item connect $dsn, %args

DWIM wrapper for C<new>.

C<$dsn> represents some sort of backend (much like L<DBI> dsns map to DBDs).

An example DSN is:

    my $dir = KiokuDB->connect("bdb:dir=path/to/data/");

The backend moniker name is extracted by splitting on the colon. The rest of
the string is passed to C<new_from_dsn>, which is documented in more detail in
L<KiokuDB::Backend>.

Typically DSN arguments are separated by C<;>, with C<=> separating keys and
values. Arguments with no value are assumed to denote boolean truth (e.g.
C<jspon:dir=foo;pretty> means C<< dir => "foo", pretty => 1 >>). However, a
backend may override the default parsing, so this is not guaranteed.

Extra arguments are passed both to the backend constructor, and the C<KiokuDB>
constructor.

Note that if you need a typemap you still need to pass it in:

    KiokuDB->connect( $dsn, typemap => $typemap );

The DSN can also be a valid L<JSON> string taking one of the following forms:

    dsn => '["dbi:SQLite:foo",{"schema":"MyApp::DB"}]'

    dsn => '{"dsn":"dbi:SQLite:foo","schema":"MyApp::DB"}'

This allows more complicated arguments to be specified accurately, or arbitrary
options to be specified when the backend has nonstandard DSN parsing (for
instance L<KiokuDB::Backend::DBI> simply passes the string to L<DBI>, so this
is necessary in order to specify options on the command line).

=item configure $config_file, %args

TODO

=item new %args

Creates a new directory object.

See L</ATTRIBUTES>

=item new_scope

Creates a new object scope. Handled by C<live_objects>.

The object scope artificially bumps up the reference count of objects to ensure
that they live at least as long as the scope does.

This ensures that weak references aren't deleted prematurely, and the object
graph doesn't get corrupted without needing to create circular structures and
cleaning up leaks manually.

=item lookup @ids

Fetches the objects for the specified IDs from the live object set or from
storage.

=item store @objects

=item store %objects

=item store_nonroot @objects

=item store_nonroot %objects

Recursively collapses C<@objects> and inserts or updates the entries.

This performs a full update of every reachable object from C<@objects>,
snapshotting everything.

Strings found in the object list are assumed to be IDs for the following objects.

The C<nonroot> variant will not mark the objects as members of the root set
(therefore they will be subject to garbage collection).

=item update @objects

Performs a shallow update of @objects (referants are not updated).

It is an error to update an object not in the database.

=item deep_update @objects

Update @objects and all of the objects they reference. All references
objects must already be in the database.

=item insert @objects

=item insert %objects

=item insert_nonroot @objects

=item insert_nonroot %objects

Inserts objects to the database.

It is an error to insert objects that are already in the database, all elements
of C<@objects> must be new, but their referants don't have to be.

C<@objects> will be collapsed recursively, but the collapsing stops at known
objects, which will not be updated.

The C<nonroot> variant will not mark the objects as members of the root set
(therefore they will be subject to garbage collection).


=item delete @objects_or_ids

Deletes the specified objects from the store.

Note that this can cause lookup errors if the object you are deleting is
referred to by another object, because that link will be broken.

=item set_root @objects

=item unset_root @objects

Modify the C<root> flag on the associated entries.

C<update> must be called for the change to take effect.

=item txn_do $code, %args

=item txn_do %args

=item scoped_txn $code

Executes $code within the scope of a transaction.

This requires that the backend supports transactions
(L<KiokuDB::Backend::Role::TXN>).

If the backend does not support transactions, the code block will simply be
invoked.

Transactions may be nested.

If the C<scope> argument is true an implicit call to C<new_scope> will be made,
keeping the scope for the duration of the transaction.

The return value is propagated from the code block, with handling of
list/scalar/void context.

C<scoped_txn> is like C<txn_do> but sets C<scope> to true.

=item txn_begin

=item txn_commit

=item txn_rollback

These methods simply call the corresponding methods on the backend.

Like C<txn_do> these methods are no-ops if the backend does not support
transactions.

=item search \%proto

=item search @args

Searching requires a backend that supports querying.

The C<\%proto> form is currently unspecified but in the future should provide a
simple but consistent way of looking up objects by attributes.

The second form is backend specific querying, for instance
L<Search::GIN::Query> objects passed to L<KiokuDB::Backend::BDB::GIN> or
the generic GIN backend wrapper L<KiokuDB::GIN>.

Returns a L<Data::Stream::Bulk> of the results.

=item root_set

Returns a L<Data::Stream::Bulk> of all the root objects in the database.

=item all_objects

Returns a L<Data::Stream::Bulk> of all the objects in the database.

=item grep $filter

Returns a L<Data::Stream::Bulk> of the objects in C<root_set> filtered by
C<$filter>.

=item scan $callback

Iterates the root set calling C<$callback> for each object.

=item object_to_id

=item objects_to_ids

=item id_to_object

=item ids_to_objects

Delegates to L<KiokuDB::LiveObjects>

=item directory

Returns C<$self>.

This is used when setting up L<KiokuDB::Role::API> delegation chains. Calling
C<directory> on any level of delegator will always return the real L<KiokuDB>
instance no matter how deep.

=back

=head1 GLOBALS

=over 4

=item C<$SERIAL_IDS>

If set at compile time, the default UUID generation role will use serial IDs,
instead of UUIDs.

This is useful for testing, since the same IDs will be issued each run, but is
utterly broken in the face of concurrency.

=back

=head1 INTERNAL ATTRIBUTES

These attributes are documented for completeness and should typically not be
needed.

=over 4

=item collapser

L<KiokuDB::Collapser>

The collapser prepares objects for storage, by creating L<KiokuDB::Entry>
objects to pass to the backend.

=item linker

L<KiokuDB::Linker>

The linker links entries into functioning instances, loading necessary
dependencies from the backend.

=item live_objects

L<KiokuDB::LiveObjects>

The live object set keeps track of objects and entries for the linker and the
resolver.

It also creates scope objects that help ensure objects don't garbage collect
too early (L<KiokuDB::LiveObjects/new_scope>, L<KiokuDB::LiveObjects::Scope>),
and transaction scope objects used by C<txn_do>
(L<KiokuDB::LiveObjects::TXNScope>).

=item typemap_resolver

An instance of L<KiokuDB::TypeMap::Resolver>. Handles actual lookup and
compilation of typemap entries, using the user typemap.

=back

=head1 SEE ALSO

=head2 Prior Art on the CPAN

=over 4

=item L<Pixie>

=item L<DBM::Deep>

=item L<OOPS>

=item L<Tangram>

=item L<DBIx::Class>

Polymorphic retrieval is possible with L<DBIx::Class::DynamicSubclass>

=item L<Fey::ORM>

=item L<MooseX::Storage>

=back

=head1 VERSION CONTROL

KiokuDB is maintained using Git. Information about the repository is available
on L<http://www.iinteractive.com/kiokudb/>

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

    Copyright (c) 2008, 2009 Yuval Kogman, Infinity Interactive. All
    rights reserved This program is free software; you can redistribute
    it and/or modify it under the same terms as Perl itself.

=cut








