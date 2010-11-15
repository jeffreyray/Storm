package Storm::Source::Manager::SQL;

use Moose;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;
use MooseX::Method::Signatures;

use MooseX::Types::Moose qw( ArrayRef Str );

has 'statements' => (
    isa         => ArrayRef,
    default     => sub { [ ] },
    traits      => [qw( Array )],
    reader      => '_statements',
    handles     => {
        _add_statement => 'push',
        statements    => 'elements',
    }
);


# we declare this method instead of using an accessor so we can ignore
# empty statements and remove leading/trailing whitespace

method add_statement ( Str $statement ) {
    # throw exeptions
    confess q[__PACKAGE__->add_statement( $statement )] if ! defined $statement;
    
    $statement =~ s/^\s+//;
    $statement =~ s/\s+$//;
    
    return if $statement eq '';
    $self->_add_statement( $_ );
}


# alternative constructors
sub new_from_file {
    my ( $class, $file ) = @_;
    my $self  = $class->new;
    $self->parse_file( $file );
    return $self;
}

sub new_from_string {
    my ( $class, $string ) = @_;
    my $self   = $class->new;
    $self->parse_string( $string );
    return $self;
}

sub new_from_handle {
    my $class = shift;
    my $self = $class->new;
    $self->parse_handle( @_ );
    return $self;
}

sub new_from_source {
    my ( $class, $source, $reset ) = @_;
   
    confess 'you did not supply a source' if ! defined $source;
  
    # if the source is a filehandle
    if ($source =~ /^\*/) {
        return $class->new_from_handle( $source, $reset );
    }
    elsif (! ref $source && $source =~ /\n/g ) {
        return $class->new_from_string( $source );
    }
    # otherwise assum it is a filename
    elsif (! ref $source ) {
        return $class->new_from_file($source);
    }
    else {
        # shouldn't get here
        confess 'bad source type';
    }
}


method parse_file ( Str $file ) {
    # throw exceptions
    confess q[Usage is $schema->parse_file($file_path)] if ! defined $file || $file eq '';
    confess qq[File "$file" does not exist] if ! -e $file;
    
    # parse the file
    open my $SCHEMA, $file || die qq[Could not open file "$file" for reading];
    flock $SCHEMA, 2;
    my $schema_data = do { local( $/ ); <$SCHEMA> };
    $self->parse_string( $schema_data );
    close $SCHEMA;
    
    return 1;
}

method parse_handle ( $handle, $reset? ) {
    
    # throw exception if no handle
    confess q[usage $schema->parse_file_handle(<$HANDLE>)] if ! defined $handle;
    
    # if $reset is true, we will remember the current position
    # in the file handle, then reset back to it - this is so the user
    # can easily reparse the same file over and over again without
    # needing to reset the file themselves
    
    my $position = tell $handle if $reset;
    my $schema_data = do { local $/; <$handle> };
    seek $handle, $position, 0 if $reset;
    
    # give a warning if no contant was retrieveds
    if ( ! $schema_data ) {
        use Carp;
        carp
            q[could not read any data from file handle - the file is empty ] .
            q[or you are at the end of the file ]
            and return 0;
    }
    
    $self->parse_string( $schema_data );
    
    return 1;
}

method parse_string ( Str $string ) {

    # no string supplied
    if (! defined $string) {
        carp q[usage: $schema->parse_string( $string )]
        and return;
    }
    
    $self->add_statement( $_ ) for split(/;/, $string);
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Storm::Source::Manager::SQL - A class for storing sql statements which are used
to setup a data source

=head1 SYNOPSIS


  use Storm::Source::Manager::SQL;
  
  $sql = Storm::Source::Manager::SQL->new;
  
  $sql = Storm::Source::Manager::SQL->new_from_string( $string );
  
  $sql = Storm::Source::Manager::SQL->new_from_file( '/path/to/file.sql' );
  
  $sql = Storm::Source::Manager::SQL->new_from_handle( *main::DATA );
 
  $sql->parse_string($string);
  
  $sql->parse_file('/path/to/file');
  
  $sql->parse_handle( *main::DATA );
  
  for my $statement ( $sql->statements ) {
    $dbh->execute( $statement );
  }

=head1 DESCRIPTION

Manages a list of SQL statements to be used by the ::Source::Manager to setup
a data source.

=head1 METHODS

=over 4

=item __PACKAGE__->new

=item __PACKAGE__->new_from_file($file_path)

Constructs a schema object then calls C<parse_file>.

=item __PACKAGE__->new_from_handle($file_handle, ?$reset)

Constructs a schema object then calls C<parse_handle>.

=item __PACKAGE__->new_from_string($string)

Constructs a schema object then calls C<parse_string>.

=item __PACKAGE__->new_from_source($source, ?$reset)

Constructs a schema object then calls C<parse_file> or C<parse_handle>
depending on the value of C<$source>.

=item $self->parse_file($file_path)

=item $self->parse_handle($file_handle, ?$reset)

If C<$reset> is true, the file handle will be set back to the same
position it was at before parsing began. The default behavior is 'NOT'
to reset the filehandle.

=item $self->parse_string($string)

=item $self->add_statement($statement, ?@statements)

=item $self->statements

=back


=head1 AUTHOR

Jeffrey Ray Hallock, < jeffrey dot hallock at gmail dot com >

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Jeffrey Ray Hallock

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut


1;