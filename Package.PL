use Module::Package;

my $pack = Module::Package->new(
    name => 'Storm',
    version_from => 'lib/Storm.pm',
    prereq_pm => {
        'DateTime',
        'DateTime::Format::SQLite',
        'DateTime::Format::MySQL',
        'DBI' => 0,
	'DBD::SQLite' => 0,
	'Moose' => 0,
	'MooseX::SemiAffordanceAccessor' => 0,
        'MooseX::StrictConstructor' => 0,
	'MooseX::Types' => 0,
    },
    abstract_from => 'lib/Storm.pm',
    author => 'Jeffrey Ray Hallock <jeffrey dot hallock at gmail dot com>',
    exclude => [ '*.komodoproject', '.komodotools', '.git' ],
);
$pack->package;


