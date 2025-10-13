package TravellersPalm::Database::Itineraries;

use strict;
use warnings;
use Exporter 'import';
use TravellersPalm::Database::Connector qw(fetch_all fetch_row execute);
use Data::Dumper;
use constant DBKEY => 'sqlserver';  # or change to 'jadoo' if needed

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
# Internal logging wrappers
# -----------------------------
sub _fetch_row {
    my ($sql, $bind_ref, $key_style, $dbkey) = @_;
    $bind_ref //= [];
    $key_style //= 'NAME_lc';
    $dbkey     //= DBKEY;
    warn "[Itineraries] fetch_row SQL: $sql, Bind: " . Dumper($bind_ref);
    return fetch_row($sql, $bind_ref, $key_style, $dbkey);
}

sub _fetch_all {
    my ($sql, $bind_ref, $dbkey) = @_;
    $bind_ref //= [];
    $dbkey    //= DBKEY;
    warn "[Itineraries] fetch_all SQL: $sql, Bind: " . Dumper($bind_ref);
    return fetch_all($sql, $bind_ref, $dbkey);
}

# -----------------------------
# Quoted itineraries (boolean)
# -----------------------------
sub isquoted {
    my ($itinid) = @_;
    return 0 unless defined $itinid;

    my $sql = q{
        SELECT COUNT(*) AS cnt
        FROM quotations
        WHERE itinerary_id = ?
    };
    my $row = _fetch_row($sql, [$itinid]);
    return $row->{cnt} ? 1 : 0;
}

# -----------------------------
# Itinerary cost (numeric)
# -----------------------------
sub itincost {
    my ($itinid, $currency) = @_;
    return 0 unless defined $itinid;

    my $sql = q{
        SELECT SUM(total_cost) AS cost
        FROM itinerary_cost
        WHERE itinerary_id = ?
          AND currency = ?
    };
    my $row = _fetch_row($sql, [$itinid, $currency]);
    return $row->{cost} ? int($row->{cost}) : 0;
}

# -----------------------------
# All itineraries
# -----------------------------
sub itineraries {
    my ($currency, $city) = @_;
    my $sql = q{
        SELECT itinerary_id, itinerary, duration, price, city
        FROM itineraries
        WHERE currency = ?
          AND city = ?
        ORDER BY itinerary
    };
    return _fetch_all($sql, [$currency, $city]);
}

# -----------------------------
# Single itinerary
# -----------------------------
sub itinerary {
    my ($itinid) = @_;
    return {} unless defined $itinid;

    my $sql = q{
        SELECT itinerary_id, itinerary, duration, description
        FROM itineraries
        WHERE itinerary_id = ?
    };
    return _fetch_row($sql, [$itinid]);
}

# -----------------------------
# Itinerary by name
# -----------------------------
sub itinerary_id {
    my ($itinname) = @_;
    return unless defined $itinname;

    my $sql = q{
        SELECT itinerary_id
        FROM itineraries
        WHERE itinerary = ?
    };
    my $row = _fetch_row($sql, [$itinname]);
    return $row->{itinerary_id};
}

# -----------------------------
# Check existence
# -----------------------------
sub itinerary_exist {
    my ($itinname) = @_;
    return 0 unless defined $itinname;

    my $sql = q{
        SELECT COUNT(*) AS cnt
        FROM itineraries
        WHERE itinerary = ?
    };
    my $row = _fetch_row($sql, [$itinname]);
    return $row->{cnt} ? 1 : 0;
}

# -----------------------------
# Itinerary cost breakdown
# -----------------------------
sub itinerary_cost {
    my ($itinid, $currency) = @_;
    return [] unless defined $itinid;

    my $sql = q{
        SELECT component, total_cost, currency
        FROM itinerary_cost
        WHERE itinerary_id = ?
          AND currency = ?
    };
    return _fetch_all($sql, [$itinid, $currency]);
}

# -----------------------------
# Similar tours
# -----------------------------
sub similartours {
    my ($itinid) = @_;
    return [] unless defined $itinid;

    my $sql = q{
        SELECT s.similar_id, i.itinerary, i.city
        FROM similartours s
        JOIN itineraries i ON s.similar_id = i.itinerary_id
        WHERE s.itinerary_id = ?
    };
    return _fetch_all($sql, [$itinid]);
}

# -----------------------------
# Places you will visit
# -----------------------------
sub placesyouwillvisit {
    my ($itinid) = @_;
    return [] unless defined $itinid;

    my $sql = q{
        SELECT p.place, p.country
        FROM itinerary_places ip
        JOIN places p ON ip.place_id = p.place_id
        WHERE ip.itinerary_id = ?
        ORDER BY p.place
    };
    return _fetch_all($sql, [$itinid]);
}

# -----------------------------
# Your accommodation
# -----------------------------
sub youraccommodation {
    my ($itinid) = @_;
    return [] unless defined $itinid;

    my $sql = q{
        SELECT h.hotelname, h.city, h.category
        FROM itinerary_hotels ih
        JOIN hotels h ON ih.hotel_id = h.hotel_id
        WHERE ih.itinerary_id = ?
        ORDER BY h.city
    };
    return _fetch_all($sql, [$itinid]);
}

# -----------------------------
# Tours in state
# -----------------------------
sub toursinstate {
    my ($state) = @_;
    return [] unless defined $state;

    my $sql = q{
        SELECT itinerary_id, itinerary, duration, price
        FROM itineraries
        WHERE state = ?
        ORDER BY itinerary
    };
    return _fetch_all($sql, [$state]);
}

# -----------------------------
# Trip ideas trips
# -----------------------------
sub tripideas_trips {
    my ($idea) = @_;
    return [] unless defined $idea;

    my $sql = q{
        SELECT itinerary_id, itinerary, duration, theme
        FROM itineraries
        WHERE theme LIKE ?
        ORDER BY itinerary
    };
    return _fetch_all($sql, ["%$idea%"]);
}

# -----------------------------
# Total itineraries count
# -----------------------------
sub totalitineraries {
    my $sql = q{
        SELECT COUNT(*) AS total
        FROM itineraries
    };
    my $row = _fetch_row($sql);
    return $row->{total} || 0;
}

1;
