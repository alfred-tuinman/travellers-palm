use strict;
use warnings;

# --- Force config file and views path before anything else ---
BEGIN {
    $ENV{DANCER_ENVIRONMENT} = 'development';
    $ENV{DANCER_CONFIG}      = '/usr/src/app/config.yml';
    $ENV{DANCER_VIEWS}       = '/usr/src/app/views';  # force views path
}
# Add lib/ to @INC so TravellersPalm.pm can be found
use lib '/usr/src/app/lib';

use Dancer2;                     # starts the app
use Dancer2::Plugin::Database;   # load the Database plugin
use TravellersPalm;

# Force views path explicitly for this app instance
TravellersPalm->set(views => '/usr/src/app/views');

TravellersPalm->to_app;
