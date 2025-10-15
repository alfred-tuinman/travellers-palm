package TravellersPalm::Database::Itineraries;

use strict;
use warnings;
use Exporter 'import';
use TravellersPalm::Database::Connector qw(fetch_all fetch_row execute);
use Data::Dumper;

our @EXPORT_OK = qw(
    route_listing
    itinerary_details
    itinerary_days
    itinerary_modules
    itinerary_regions
    itinerary_themes
    itinerary_search
);

# -----------------------------
# Internal wrappers for logging
# -----------------------------
sub _fetch_row {
    my ($sql, $bind_ref, $key_style, $dbkey) = @_;
    $bind_ref  //= [];
    $key_style //= 'NAME_lc';

    warn "[Itineraries] fetch_row called with SQL: $sql, Bind: " . Dumper($bind_ref);
    return fetch_row($sql, $bind_ref, $key_style, $dbkey);
}

sub _fetch_all {
    my ($sql, $bind_ref, $dbkey) = @_;
    $bind_ref //= [];

    warn "[Itineraries] fetch_all called with SQL: $sql, Bind: " . Dumper($bind_ref);
    return fetch_all($sql, $bind_ref, $dbkey);
}

# -----------------------------
# Route listing for a destination
# -----------------------------
sub route_listing {
    my ($destination, $option, $view, $order) = @_;
    my $sql = q{
        SELECT i.itinerary_id, i.title, i.description, i.duration, i.difficulty
        FROM itineraries i
        JOIN destinations d ON d.destination_id = i.destination_id
        WHERE d.name = ?
        AND i.option_type = ?
        ORDER BY ?
    };
    return _fetch_all($sql, [$destination, $option, $order], 'jadoo');
}

# -----------------------------
# Itinerary details (single row)
# -----------------------------
sub itinerary_details {
    my ($itinerary_id) = @_;
    my $sql = q{
        SELECT i.itinerary_id, i.title, i.description, i.duration, i.difficulty, i.price
        FROM itineraries i
        WHERE i.itinerary_id = ?
    };
    return _fetch_row($sql, [$itinerary_id], 'NAME_lc', 'jadoo');
}

# -----------------------------
# Day-by-day breakdown for an itinerary
# -----------------------------
sub itinerary_days {
    my ($itinerary_id) = @_;
    my $sql = q{
        SELECT day_no, title, description
        FROM daybyday
        WHERE itinerary_id = ?
        ORDER BY day_no
    };
    return _fetch_all($sql, [$itinerary_id], 'jadoo');
}

# -----------------------------
# Modules associated with an itinerary
# -----------------------------
sub itinerary_modules {
    my ($itinerary_id) = @_;
    my $sql = q{
        SELECT m.module_name, m.module_code
        FROM modules m
        JOIN itinerary_modules im ON im.module_id = m.module_id
        WHERE im.itinerary_id = ?
        ORDER BY m.module_name
    };
    return _fetch_all($sql, [$itinerary_id], 'jadoo');
}

# -----------------------------
# Regions covered in an itinerary
# -----------------------------
sub itinerary_regions {
    my ($itinerary_id) = @_;
    my $sql = q{
        SELECT DISTINCT r.region_name
        FROM regions r
        JOIN itinerary_regions ir ON ir.region_id = r.region_id
        WHERE ir.itinerary_id = ?
        ORDER BY r.region_name
    };
    return _fetch_all($sql, [$itinerary_id], 'jadoo');
}

# -----------------------------
# Themes associated with an itinerary
# -----------------------------
sub itinerary_themes {
    my ($itinerary_id) = @_;
    my $sql = q{
        SELECT t.theme_name
        FROM themes t
        JOIN itinerary_themes it ON it.theme_id = t.theme_id
        WHERE it.itinerary_id = ?
        ORDER BY t.theme_name
    };
    return _fetch_all($sql, [$itinerary_id], 'jadoo');
}

# -----------------------------
# Search itineraries by keyword
# -----------------------------
sub itinerary_search {
    my ($keyword) = @_;
    my $sql = q{
        SELECT i.itinerary_id, i.title, i.description, i.duration, i.difficulty
        FROM itineraries i
        WHERE i.title LIKE ?
           OR i.description LIKE ?
        ORDER BY i.title
    };
    my $like = "%$keyword%";
    return _fetch_all($sql, [$like, $like], 'jadoo');
}

1;
