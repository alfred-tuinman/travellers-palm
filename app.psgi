use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use Dancer2;                     # start the app
use Dancer2::Plugin::Database;   # plugin must be loaded

use TravellersPalm::Web;         # hooks & template setup
use TravellersPalm::Router;      # route table

use Plack::Builder;

my $app = builder {
    # Mount your Web app
    mount '/' => TravellersPalm::Web->to_app;

    # Mount your Router app
    mount '/' => TravellersPalm::Router->to_app;
};

$app;
