package TravellersPalm::Controller::Hotels;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use TravellersPalm::Constants qw(:all);

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
# GET /hotel-categories
# -----------------------------
sub show_hotel_categories ($self) {
    my $webtext = TravellersPalm::Database::General::webtext(18, $self);

    $self->render(
        template         => 'hotel_categories',
        hotel_categories => $webtext,
    );
}

# -----------------------------
# GET /hand-picked-hotels
# -----------------------------
sub show_hand_picked_hotels ($self) {
    my $path_segment = $self->_last_path_segment;

    # Batch fetch all webtexts needed for this page
    my @ids = (18, 19, 20, 208);
    my $webtexts = TravellersPalm::Database::General::webtext_multi(\@ids);

    $self->render(
        template         => 'hand_picked_hotels',
        metatags         => TravellersPalm::Database::General::metatags($path_segment, $self),
        hotel_categories => $webtexts->{18},
        heritage_hotels  => $webtexts->{19},
        home_stays       => $webtexts->{20},
        about            => $webtexts->{208},
        crumb            => '<li class="active">Hand-picked Hotels</li>',
        page_title       => 'Hand Picked Hotels',
    );
}

1;
