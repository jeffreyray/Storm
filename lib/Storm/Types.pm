package Storm::Types;
use MooseX::Types -declare => [qw(
    DBIStatementHandle
    MooseAttribute
    SchemaColumn
    SchemaTable
    Storm
    StormDeleteQuery
    StormEnabledClassName
    StormInsertQuery
    StormLiveObjects
    StormLiveObjectScope
    StormLookupQuery
    StormMetaRelationship
    StormPolicyObject
    StormSelectQuery
    StormSource
    StormSourceManager
    StormUpdateQuery
)];

use MooseX::Types::Moose qw( ArrayRef ClassName HashRef Str );

class_type DBIStatementHandle,
    { class => 'DBI::st' };
    
class_type MooseAttribute,
    { class => 'Moose::Meta::Attribute' };

class_type SchemaColumn,
    { class => 'Storm::Schema::Column' };
    
coerce SchemaColumn,
    from Str,
    via { Storm::Schema::Column->new(name => $_) };

coerce SchemaColumn,
    from HashRef,
    via { Storm::Schema::Column->new( %$_ ) };

    
class_type SchemaTable,
    { class => 'Storm::Schema::Table' };
    
coerce SchemaTable,
    from Str,
    via { Storm::Schema::Table->new( name => $_ ) };
    
    
class_type Storm,
    { class => 'Storm' };
    
class_type StormDeleteQuery,
    { class => 'Storm::Query::Delete' };

subtype StormEnabledClassName,
    as ClassName,
    where { $_->can('meta') && $_->meta->does_role('Storm::Role::Object::Base') };
    
class_type StormInsertQuery,
    { class => 'Storm::Query::Insert' };
    
class_type StormLiveObjects,
    { class => 'Storm::LiveObjects' };
    
class_type StormLiveObjectScope,
    { class => 'Storm::LiveObjects::Scope' };

class_type StormMetaRelationship,
    { class => 'Storm::Meta::Relationship' };

class_type StormLookupQuery,
    { class => 'Storm::Query::Lookup' };
    
class_type StormPolicyObject,
    { class => 'Storm::Policy::Object' };
    
coerce StormPolicyObject,
    from ClassName,
    via { $_->Policy };

class_type StormSelectQuery,
    { class => 'Storm::Query::Select' };

class_type StormSource,
    { class => 'Storm::Source' };

coerce StormSource,
    from Str,
    via { Storm::Source->new( $_) };

coerce StormSource,
    from ArrayRef,
    via { Storm::Source->new( @$_) };

class_type StormSourceManager,
    { class => 'Storm::Source::Manager' };

class_type StormUpdateQuery,
    { class => 'Storm::Query::Update' };



1;
