package TravellersPalm::Database::Initializer;
use strict;
use warnings;

# Backwards-compatible shim to Core::Initializer
use TravellersPalm::Database::Core::Initializer ();

sub setup {
    my ($class, @rest) = @_;
    return TravellersPalm::Database::Core::Initializer::setup(@rest);
}

1;
