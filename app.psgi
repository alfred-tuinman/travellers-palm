use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use TravellersPalm::Router;

# Return PSGI app
my $app = TravellersPalm::Router->to_app;
$app;
