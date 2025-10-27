package TravellersPalm::Controller::Utils;

use strict;
use warnings;

=head1 NAME

TravellersPalm::Controller::Utils - Utility methods for controllers

=head1 DESCRIPTION

Provides shared utility functions for TravellersPalm controllers.

=cut

# Utility to get last path segment from request URL
sub last_path_segment {
    my ($c) = @_;
    my $req = $c->req;
    my $path = $req->url->path->to_string;
    my ($last) = reverse grep { length } split('/', $path);
    return $last;
}

1;

__END__

=head1 AUTHOR

Travellers Palm Team

=head1 LICENSE

See the main project LICENSE file.

=cut
