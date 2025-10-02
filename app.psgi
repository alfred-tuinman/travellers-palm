use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Dancer2;                     # starts the app
use Dancer2::Plugin::Database;   # load the Database plugin

use TravellersPalm;
TravellersPalm->to_app;
