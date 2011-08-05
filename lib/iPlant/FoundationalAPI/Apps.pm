package iPlant::FoundationalAPI::Apps;

use warnings;
use strict;

use iPlant::FoundationalAPI::Constants ':all';
use base qw/iPlant::FoundationalAPI::Base/;

use iPlant::FoundationalAPI::Object::Application ();

=head1 NAME

iPlant::FoundationalAPI::Apps - The great new iPlant::FoundationalAPI::Apps!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use iPlant::FoundationalAPI::Apps;

    my $foo = iPlant::FoundationalAPI::Apps->new();
    ...

=head1 METHODS

=head2 list

=cut

# retrieve a list of the available applications
sub list {
	my ($self) = @_;

	my $list = $self->do_get('/list');


# 	if ($use_formating) {
# 		my @l = map { $_->{id} } @$list;
# 		return \@l;
# 	}

	my @applications =  $list != -1 && @$list ? ( map { new iPlant::FoundationalAPI::Object::Application($_) } @$list) : ();
	#use Data::Dumper;
	#print STDERR Dumper( \@applications), $/;
	wantarray ? @applications : \@applications;
}

=head2 load

=cut

sub find_by_name {
	my ($self, $name) = @_;
	my @applications = ();

	if ($name) {
		my $list = $self->do_get('/name/' . $name);
		@applications =  @$list ? ( map { new iPlant::FoundationalAPI::Object::Application($_) } @$list) : ();
	}
	wantarray ? @applications : \@applications;
}

=head1 AUTHOR

Cornel Ghiban, C<< <ghiban at cshl.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-iplant-foundationalapi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=iPlant-FoundationalAPI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc iPlant::FoundationalAPI::Apps


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=iPlant-FoundationalAPI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/iPlant-FoundationalAPI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/iPlant-FoundationalAPI>

=item * Search CPAN

L<http://search.cpan.org/dist/iPlant-FoundationalAPI/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2011 Cornel Ghiban.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of iPlant::FoundationalAPI::Apps
