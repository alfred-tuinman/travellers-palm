package TravellersPalm::Controller::Hotels;

use strict;
use warnings;

use Dancer2 appname => 'TravellersPalm';      # link to your main app

use Template;
use Data::FormValidator;
use Date::Manip::Date;
use Data::Dumper;
use Exporter 'import';

use TravellersPalm::Functions;
use TravellersPalm::Database;

our @EXPORT_OK = qw(register_routes);

# -----------------------------
# Register all routes
# -----------------------------
sub register_routes {

    get '/hotel-categories'    => \&show_hotel_categories;
    get '/hand-picked-hotels'  => \&show_hand_picked_hotels;

}

# -----------------------------
# Controller Actions
# -----------------------------

sub show_hotel_categories {
    template hotel_categories => {
        hotel_categories => webtext(18),
    };
}

sub show_hand_picked_hotels {
    template hand_picked_hotels => {
        metatags         => metatags( ( split '/', request->path )[-1] ),
        hotel_categories => webtext(18),
        heritage_hotels  => webtext(19),
        home_stays       => webtext(20),
        about            => webtext(208),
        crumb            => '<li class="active">Hand-picked Hotels</li>',
        page_title       => 'Hand Picked Hotels',
    };
}

1;  
