package iPlant::FoundationalAPI::Object::File;


=head1 NAME

iPlant::FoundationalAPI::Object::File - The great new iPlant::FoundationalAPI::Object::File!

=head1 VERSION

Version 0.01

=cut

use overload '""' => sub { $_[0]->path; };

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use iPlant::FoundationalAPI::IO;

    my $apif = iPlant::FoundationalAPI->new;
    my $io = $apif->io;
    my @files = $io->list($path);
    print $files[0]->owner;
    ...

=head1 METHODS

=head2 new

=cut


sub new {
	my ($proto, $args) = @_;
	my $class = ref($proto) || $proto;
	
	my $self  = { map {$_ => $args->{$_}} keys %$args};
	
	
	bless($self, $class);
	
	
	return $self;
}

sub name {
	my ($self) = @_;
	return $self->{name};
}


sub path {
	my ($self) = @_;
	return $self->{path};
}


sub size {
	my ($self) = @_;
	return $self->{length};
}


sub type {
	my ($self) = @_;
	return $self->{type};
}

sub format {
	my ($self) = @_;
	return $self->{format};	
}


sub is_file {
	my ($self) = @_;
	return $self->type eq 'file';
}


sub is_folder {
	my ($self) = @_;
	return $self->type eq 'dir';
}


1; # End of iPlant::FoundationalAPI::Object::File
