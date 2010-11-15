use Test::More 'no_plan';


use Storm;
my $storm = Storm->new( source => ['DBI:SQLite:dbname=:memory:'] );
ok $storm, 'storm instantiated';
ok $storm->source, 'source object created';
ok $storm->source->dbh, 'database handle created';
ok $storm->source->manager->install( *main::DATA ), 'installed schema';


__DATA__

CREATE TABLE TestObject (
    TestObjectPrimaryKey  VARCHAR(10),
    TestObjectProperty    VARCHAR(30)
);