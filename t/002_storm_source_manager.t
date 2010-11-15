use Test::More 'no_plan';


use Storm::Source;

my $source = Storm::Source->new;
ok $source, 'source instantiated';

$source->set_parameters( 'DBI:SQLite:dbname=:memory:' );
ok $source->dbh, 'created database handle';

ok $source->manager, 'retrieved source manager';


# install tables from string
$source->manager->install(q[
    CREATE TABLE Foo (
        FooID    VARCHAR(10) NOT NULL,
        FooLabel VARCHAR(30)
    );
    CREATE TABLE Bar (
        BarID    VARCHAR(10) NOT NULL,
        BarLabel VARCHAR(30)
    );
]);

is_deeply [sort $source->tables], [qw/Bar Foo/], 'tables installed from string';
$source->manager->uninstall;
is_deeply [$source->tables], [], 'tables removed';

# install tables from file
$source->manager->install( 't/test_source_manager.sql' );
is_deeply [sort $source->tables], [qw/Bar Foo/], 'tables installed from file';
$source->manager->uninstall;

# install tables from file handle
$source->manager->install( 't/test_source_manager.sql' );
is_deeply [sort $source->tables], [qw/Bar Foo/], 'tables installed from handle';
$source->manager->uninstall;


__DATA__

CREATE TABLE Foo (
    FooID    VARCHAR(10) NOT NULL,
    FooLabel VARCHAR(30)
);
CREATE TABLE Bar (
    BarID    VARCHAR(10) NOT NULL,
    BarLabel VARCHAR(30)
);