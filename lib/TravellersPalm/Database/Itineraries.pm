package TravellersPalm::Database::Itineraries;

use strict;
use warnings;
use Exporter 'import';
use TravellersPalm::Database::Connector qw(fetch_all fetch_row execute);
use TravellersPalm::Database::Helpers qw(_fetch_row _fetch_all);
use Data::Dumper;

our @EXPORT_OK = qw(
    isquoted
    itincost
    itineraries
    itinerary
    itinerary_cost
    itinerary_exist
    itinerary_id
    placesyouwillvisit
    similartours
    tripideas_trips
    totalitineraries
    toursinstate
    youraccommodation
);

# -----------------------------
# Check if itinerary is quoted
# -----------------------------
sub isquoted {
    my ($itinerary_id) = @_;
    my $sql = q{
        SELECT quoted
        FROM itineraries
        WHERE itinerary_id = ?
    };
    return _fetch_row($sql, [$itinerary_id], 'NAME_lc');
}

# -----------------------------
# Get cost of itinerary
# -----------------------------
sub itincost {
    my ($itinerary_id) = @_;
    my $sql = q{
        SELECT SUM(cost) AS total_cost
        FROM itinerary_costs
        WHERE itinerary_id = ?
    };
    return _fetch_row($sql, [$itinerary_id], 'NAME_lc');
}

# -----------------------------
# List all itineraries
# -----------------------------
sub itineraries {
    my $sql = q{
        SELECT itinerary_id, title, description, duration
        FROM itineraries
        ORDER BY title
    };
    return _fetch_all($sql);
}

# -----------------------------
# Get single itinerary details
# -----------------------------
sub itinerary {
    my ($itinerary_id) = @_;
    my $sql = q{
        SELECT *
        FROM itineraries
        WHERE itinerary_id = ?
    };
    return _fetch_row($sql, [$itinerary_id], 'NAME_lc');
}

# -----------------------------
# Itinerary cost breakdown
# -----------------------------
sub itinerary_cost {
    my ($itinerary_id) = @_;
    my $sql = q{
        SELECT cost_type, cost
        FROM itinerary_costs
        WHERE itinerary_id = ?
    };
    return _fetch_all($sql, [$itinerary_id]);
}

# -----------------------------
# Check if itinerary exists
# -----------------------------
sub itinerary_exist {
    my ($itinerary_id) = @_;
    my $sql = q{
        SELECT 1
        FROM itineraries
        WHERE itinerary_id = ?
    };
    return _fetch_row($sql, [$itinerary_id], 'NAME_lc');
}

# -----------------------------
# Get itinerary ID by title
# -----------------------------
sub itinerary_id {
    my ($title) = @_;
    my $sql = q{
        SELECT itinerary_id
        FROM itineraries
        WHERE title = ?
    };
    return _fetch_row($sql, [$title], 'NAME_lc');
}

# -----------------------------
# Places you will visit in itinerary
# -----------------------------
sub placesyouwillvisit {
    my ($itinerary_id) = @_;
    my $sql = q{
        SELECT place_name, day_no
        FROM itinerary_places
        WHERE itinerary_id = ?
        ORDER BY day_no
    };
    return _fetch_all($sql, [$itinerary_id]);
}

# -----------------------------
# Similar tours for a given itinerary
# -----------------------------
sub similartours {
    my ($itinerary_id) = @_;
    my $sql = q{
        SELECT i.itinerary_id, i.title
        FROM itineraries i
        JOIN itinerary_tags t ON t.itinerary_id = i.itinerary_id
        WHERE t.itinerary_id != ?
        AND t.tag IN (SELECT tag FROM itinerary_tags WHERE itinerary_id = ?)
        GROUP BY i.itinerary_id
        LIMIT 5
    };
    return _fetch_all($sql, [$itinerary_id, $itinerary_id]);
}

# -----------------------------
# Trip ideas: get itineraries associated with a theme
# -----------------------------
sub tripideas_trips {
    my ($theme_id) = @_;
    my $sql = q{
        SELECT i.itinerary_id, i.title
        FROM itineraries i
        JOIN itinerary_themes it ON it.itinerary_id = i.itinerary_id
        WHERE it.theme_id = ?
        ORDER BY i.title
    };
    return _fetch_all($sql, [$theme_id]);
}

# -----------------------------
# Total number of itineraries
# -----------------------------
sub totalitineraries {
    my $sql = q{
        SELECT COUNT(*) AS total
        FROM itineraries
    };
    return _fetch_row($sql, [], 'NAME_lc');
}

# -----------------------------
# Tours in a specific state
# -----------------------------
sub toursinstate {
    my ($state_id) = @_;
    my $sql = q{
        SELECT i.itinerary_id, i.title
        FROM itineraries i
        JOIN itinerary_regions ir ON ir.itinerary_id = i.itinerary_id
        WHERE ir.region_id = ?
        ORDER BY i.title
    };
    return _fetch_all($sql, [$state_id]);
}

# -----------------------------
# Accommodation info for itinerary
# -----------------------------
sub youraccommodation {
    my ($itinerary_id) = @_;
    my $sql = q{
        SELECT accommodation_name, address, type
        FROM itinerary_accommodation
        WHERE itinerary_id = ?
    };
    return _fetch_all($sql, [$itinerary_id]);
}

1;
