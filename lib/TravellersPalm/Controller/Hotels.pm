package TravellersPalm::Controller::Hotels;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Data::FormValidator;
use Date::Manip::Date;
use Data::Dumper;

use TravellersPalm::Database::Connector qw(dbh);
use TravellersPalm::Database::General;
use TravellersPalm::Functions qw(webtext);
use TravellersPalm::Constants qw(:all);

# -----------------------------
# Controller Actions
# -----------------------------

# GET /hotel-categories
sub show_hotel_categories ($self) {
  $self->render(
    template => 'hotel_categories',
    hotel_categories => webtext(18),
  );
}

# GET /hand-picked-hotels
sub show_hand_picked_hotels ($self) {
  # Extract last path segment, e.g., "hand-picked-hotels"
  my $path_segment = (split '/', $self->req->url->path->to_string)[-1];

  $self->render(
    template => 'hand_picked_hotels',
    metatags         => TravellersPalm::Database::General::metatags($path_segment),
    hotel_categories => webtext(18),
    heritage_hotels  => webtext(19),
    home_stays       => webtext(20),
    about            => webtext(208),
    crumb            => '<li class="active">Hand-picked Hotels</li>',
    page_title       => 'Hand Picked Hotels',
  );
}

1;
