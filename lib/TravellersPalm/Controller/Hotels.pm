package TravellersPalm::Controller::Hotels;

use strict;
use warnings;

use Data::FormValidator;
use Date::Manip::Date;
use Data::Dumper;

use Exporter 'import';
use Template;
use TravellersPalm::Database::Connector qw(dbh);
use TravellersPalm::Functions qw(webtext);
use TravellersPalm::Constants qw(:all);

# -----------------------------
# Controller Actions
# -----------------------------

sub show_hotel_categories {
    template('hotel_categories') => {
        hotel_categories => webtext(18),
    };
}

sub show_hand_picked_hotels {
    template('hand_picked_hotels') => {
        metatags         => TravellersPalm::Database::General::metatags( ( split '/', request->path )[-1] ),
        hotel_categories => webtext(18),
        heritage_hotels  => webtext(19),
        home_stays       => webtext(20),
        about            => webtext(208),
        crumb            => '<li class="active">Hand-picked Hotels</li>',
        page_title       => 'Hand Picked Hotels',
    };
}

1;  
