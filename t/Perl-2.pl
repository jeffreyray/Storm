  package MyApp::Meta::Class::Trait::HasTable;
  use Moose::Role;

  has table => (
      is  => 'rw',
      isa => 'Str',
  );

  package Moose::Meta::Class::Custom::Trait::HasTable;
  sub register_implementation { 'MyApp::Meta::Class::Trait::HasTable' }

  package MyApp::User;
  use Moose -traits => 'HasTable';

  __PACKAGE__->meta->table('User');