package TravellersPalm::Database::Validation;

use strict;
use warnings;

# Backwards-compatible shim to Core::Validation
use TravellersPalm::Database::Core::Validation qw(
    validate_string
    validate_integer
    validate_filter
    validate_order
    validate_array
);

our @EXPORT_OK = qw(
    validate_string
    validate_integer
    validate_filter
    validate_order
    validate_array
);

1;