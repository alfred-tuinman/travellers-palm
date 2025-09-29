use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Dancer2;                     # starts the app
use Dancer2::Plugin::Database;   # load the Database plugin

use TravellersPalm::Web;       # load hooks & template setup
use TravellersPalm::Router;    # route table

# initialize hooks and Dancer2 app
# my $web_app = TravellersPalm::Web->to_app;

# router returns a PSGI app
my $router_app = TravellersPalm::Router->to_app;
$router_app;
