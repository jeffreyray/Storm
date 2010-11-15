package Storm::Builder;

use Moose;
use Moose::Exporter;
use Moose::Util::MetaRole;

use Storm::Meta::Attribute::Trait::AutoIncrement;
use Storm::Meta::Attribute::Trait::NoStorm;
use Storm::Meta::Attribute::Trait::PrimaryKey;

use Storm::Schema::Column;
use Storm::Schema::Table;


Moose::Exporter->setup_import_methods(
    also => 'Moose',
    with_caller => [qw( has_many )],
);

sub init_meta {
    my ( $class, %options ) = @_;
    Moose->init_meta( %options );
    
    Moose::Util::MetaRole::apply_metaroles(
        for       => $options{for_class},
        class_metaroles => {
            class => [ 'Storm::Role::Object::Meta::Class' ],
            attribute => [ 'Storm::Role::Object::Meta::Attribute' ],
        },
    );
    
    Moose::Util::MetaRole::apply_base_class_roles(
        for       => $options{for_class},
        roles           => [ 'Storm::Role::Object::Base'  ],
    );
}

sub has_many {
    my $caller = shift;
    my $name   = shift;
    my $meta   = $caller->meta;
    my %params = @_;
    
    $params{name} = $name;
    $meta->add_has_many(%params);
}

1;
