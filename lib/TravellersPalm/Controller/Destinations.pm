package TravellersPalm::Controller::Destinations;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use TravellersPalm::Constants qw(:all);
use TravellersPalm::Functions qw(boldify email_request ourtime url2text);

# Ensure General module is loaded
BEGIN { require TravellersPalm::Database::General; }

# -----------------------------
# Utility to get last path segment
# -----------------------------
sub _last_path_segment ($self) {
    my $path = $self->req->url->path->to_string;
    my ($last) = reverse grep { length } split('/', $path);
    return $last;
}

# -----------------------------
# Show state list or single destination
# -----------------------------
sub show_state_list ($self) {
    my $state_name = $self->stash('destination') || '';
    my $tags       = TravellersPalm::Database::General::metatags($self->_last_path_segment);

    # Batch fetch webtexts for this page
    my @ids = (201,202,203,204); # example IDs for destination page; adjust as needed
    my $webtexts = TravellersPalm::Database::General::webtext_multi(\@ids);

    # Fetch themes and destinations for this state
    my $themes = TravellersPalm::Database::Themes::themes('STATE');
    my $cities = TravellersPalm::Database::Cities::cities_in_state($state_name);

    $self->render(
        template => 'destinations/state_list',
        metatags => $tags,
        state    => $state_name,
        themes   => $themes,
        cities   => $cities,
        intro    => $webtexts->{201},
        tips     => $webtexts->{202},
        gallery  => $webtexts->{203},
        faq      => $webtexts->{204},
    );
}

# -----------------------------
# Single destination page
# -----------------------------
sub show_destination ($self) {
    my $destination = $self->stash('destination') || '';
    my $tags        = TravellersPalm::Database::General::metatags($self->_last_path_segment);

    # Batch fetch webtexts for this destination
    my @ids = (301,302,303,304,305,306); # example IDs for destination content
    my $webtexts = TravellersPalm::Database::General::webtext_multi(\@ids);

    my $itineraries = TravellersPalm::Database::Itineraries::by_destination($destination);
    my $related     = TravellersPalm::Database::Cities::related_destinations($destination);

    $self->render(
        template      => 'destinations/single',
        metatags      => $tags,
        destination   => $destination,
        intro         => $webtexts->{301},
        history       => $webtexts->{302},
        culture       => $webtexts->{303},
        activities    => $webtexts->{304},
        accommodation => $webtexts->{305},
        travel_tips   => $webtexts->{306},
        itineraries   => $itineraries,
        related       => $related,
    );
}

1;
