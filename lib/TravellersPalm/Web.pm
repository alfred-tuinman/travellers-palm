package TravellersPalm::Web;
use strict;
use warnings;
use Dancer2;

sub to_app {
    # Example: could setup before/after hooks
    # For now, just a placeholder PSGI app
    return sub { [404, ['Content-Type' => 'text/plain'], ['Not Found (Web)']] };
}

1;
