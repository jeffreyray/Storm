use Test::More tests => 19;


use Storm::Source::Manager::SQL;
my $sql = Storm::Source::Manager::SQL->new;
ok $sql, 'object instantiated';

# parse string
ok $sql->parse_string(q[
    CREATE TABLE Foo (
        FooID    VARCHAR(10) NOT NULL,
        FooLabel VARCHAR(30)
    );
    CREATE TABLE Bar (
        BarID    VARCHAR(10) NOT NULL,
        BarLabel VARCHAR(30)
    );
]), 'parsed string';

is scalar ( $sql->statements ), 2, 'statements created from string';


# parse file
$sql = Storm::Source::Manager::SQL->new;
ok $sql->parse_file( 't/test_source_manager.sql' ), 'parsed file';
is scalar ( $sql->statements ), 2, 'statements created from file';


# parse file handle
$sql = Storm::Source::Manager::SQL->new;
no warnings;
ok $sql->parse_handle( *main::DATA, 1 ), 'parsed handle';
use warnings;
is scalar ( $sql->statements ), 2, 'statements created from handle';


# new from string
$sql = undef;
$sql = Storm::Source::Manager::SQL->new_from_string(q[
    CREATE TABLE Foo (
        FooID    VARCHAR(10) NOT NULL,
        FooLabel VARCHAR(30)
    );
    CREATE TABLE Bar (
        BarID    VARCHAR(10) NOT NULL,
        BarLabel VARCHAR(30)
    );
]);
ok $sql, 'object created using new_from_string';
is scalar ( $sql->statements ), 2, 'statements created using new_from_string';

# new from file
$sql = undef;
$sql = Storm::Source::Manager::SQL->new_from_file( 't/test_source_manager.sql' );
ok $sql, 'object created using new_from_file';
is scalar ( $sql->statements ), 2, 'statements created using new_from_file';

# new from handle
$sql = undef;
$sql = Storm::Source::Manager::SQL->new_from_handle( *main::DATA, 1  );
ok $sql, 'object created using new_from_handle';
is scalar ( $sql->statements ), 2, 'statements created using new_from_handle';

# new from source
$sql = undef;
$sql = Storm::Source::Manager::SQL->new_from_source(q[
    CREATE TABLE Foo (
        FooID    VARCHAR(10) NOT NULL,
        FooLabel VARCHAR(30)
    );
    CREATE TABLE Bar (
        BarID    VARCHAR(10) NOT NULL,
        BarLabel VARCHAR(30)
    );
]);
ok $sql, 'object created using string to new_from_source';
is scalar ( $sql->statements ), 2, 'statements created using new_from_source';

# new from file
$sql = undef;
$sql = Storm::Source::Manager::SQL->new_from_source( 't/test_source_manager.sql' );
ok $sql, 'object created using filename to new_from_source';
is scalar ( $sql->statements ), 2, 'statements created using new_from_source';

# new from handle
$sql = undef;
$sql = Storm::Source::Manager::SQL->new_from_handle( *main::DATA, 1  );
ok $sql, 'object created using handle to new_from_source';
is scalar ( $sql->statements ), 2, 'statements created using new_from_source';




__DATA__

CREATE TABLE Foo (
    FooID    VARCHAR(10) NOT NULL,
    FooLabel VARCHAR(30)
);

CREATE TABLE Bar (
    BarID    VARCHAR(10) NOT NULL,
    BarLabel VARCHAR(30)
);
