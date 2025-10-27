package TravellersPalm::Database::Connector;

use strict;
use warnings;

# Backwards-compatible shim to Core::Connector
use TravellersPalm::Database::Core::Connector ();

our @EXPORT_OK = @TravellersPalm::Database::Core::Connector::EXPORT_OK;

sub setup {
    my ($class, @rest) = @_;
    return TravellersPalm::Database::Core::Connector->setup(@rest);
}

sub fetch_row  { TravellersPalm::Database::Core::Connector::fetch_row(@_) }
sub fetch_all  { TravellersPalm::Database::Core::Connector::fetch_all(@_) }
sub insert_row { TravellersPalm::Database::Core::Connector::insert_row(@_) }
sub update_row { TravellersPalm::Database::Core::Connector::update_row(@_) }
sub delete_row { TravellersPalm::Database::Core::Connector::delete_row(@_) }

1;
