package iPlant::FoundationalAPI::Job;

use warnings;
use strict;

use iPlant::FoundationalAPI::Constants ':all';
use base qw/iPlant::FoundationalAPI::Base/;

use iPlant::FoundationalAPI::Object::Job ();

use Data::Dumper;

=head1 NAME

iPlant::FoundationalAPI::Job - The great new iPlant::FoundationalAPI::Job!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use iPlant::FoundationalAPI::Job;

    my $foo = iPlant::FoundationalAPI::Job->new();
    ...

=head1 METHODS

=head2 submit_job

    Submits a request to run a jobs.
	Returns a Job object.

	$apps = $api_instance->apps;
	$job = $api_instance->job;
	($ap) = $apps->find_by_name("name"); #iPlant::FoundationalAPI::Object::Application
	$job->submit_job($ap, %arguments)

=cut

sub submit_job {
	my ($self, $application, %params) = @_;

	#print STDERR  '$application: ', $application, $/;
	#print STDERR  'ref $application: ', ref $application, $/;
	unless ($application && ref($application) =~ /::Application/) {
		print STDERR  "::submit_job: Invalid argument. Expecting Application object", $/;
		return kExitError;
	}


	my %required_options = ();
	my %available_options = ();

	my %post_content = (
		#application => $application->id,
			softwareName => $application->id,
			jobName => delete $params{jobName} || 'Job for ' . $application->id,
			requestedTime => delete $params{requestedTime} || '0:10:00',
			processors => delete $params{processors} || 1,
			archive => 'true',
			#archivePath => '/' . $self->user . '/analyses/',
		);


	for my $opt_group (qw/inputs outputs parameters/) {
		for my $opt ($application->$opt_group) {
			#print STDERR Dumper( $opt ), $/;
			print STDERR  "** ", $opt->{id}, ' = ', defined $opt->{required} ? $opt->{required} : '', $/;
			$available_options{$opt->{id}} = $opt;
			if (defined $params{$opt->{id}}) {
				$post_content{ $opt->{id} } = $params{$opt->{id}};
			}
			elsif (defined $opt->{required} && $opt->{required}) {
				$required_options{$opt->{id}} = $opt_group;
			}
		}
	}

	if (%required_options) {
		print STDERR  "Missing required argument(s):", $/;
		for (keys %required_options) {
			print STDERR "\t", $_, ' in ', $required_options{$_}, "\n";
		}
		return kExitError;
	}

	my $resp = $self->do_post('/', %post_content);
	if ($resp != kExitError) {
		return $resp;
	}
	return kExitError;
}

=head2 job_details

=cut

sub job_details {
	my ($self, $job_id) = @_;

	$self->do_get('/' . $job_id);
}

=head2 jobs

=cut

sub jobs {
	my ($self) = @_;

	$self->do_get('s/list');
}


=head2 delete_job

    Kills a running job identified by <id> and removes it from history

=cut

sub delete_job {
	my ($self, $job_id) = @_;

	my $st = $self->do_delete('/' . $job_id);

	return 1 if ($st != 1);
	return;
}

=head2 input

=cut

sub input {
	my ($self, $job_id) = @_;

	$self->do_get('/' . $job_id . '/input');
}



=head1 AUTHOR

Cornel Ghiban, C<< <ghiban at cshl.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-iplant-foundationalapi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=iPlant-FoundationalAPI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc iPlant::FoundationalAPI

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2011 Cornel Ghiban.

=cut

1; # End of iPlant::FoundationalAPI::Job
