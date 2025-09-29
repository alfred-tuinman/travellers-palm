package TravellersPalm::Controller::Cities;
use strict;
use warnings;
use Template;

use Dancer2;

use Data::FormValidator;
use Date::Manip::Date;
use Data::Dumper;

use TravellersPalm::Functions;
use TravellersPalm::Database;

use TravellersPalm::Database::Cities qw(get_airports_by_country);

sub airports {
    my ($class, $c) = @_;
    my $country = $c->param('country');
    my $airports = TravellersPalm::Database::Cities::get_airports_by_country($country);
    $c->stash( airports => $airports );
    $c->render('airports.tt');
}


