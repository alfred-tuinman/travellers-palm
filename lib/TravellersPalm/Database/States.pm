package TravellersPalm::Database::States;

use strict;
use warnings;

use Exporter 'import';
use TravellersPalm::Database::Connector qw(fetch_all fetch_row);

our @EXPORT_OK = qw(
    state
    states
    statesurl
);

# -----------------------------
# Get a single state by ID
# -----------------------------
sub state {
    my ($states_id, $c) = @_;
    return undef unless defined $states_id;

    my $sql = q{
        SELECT states_id, statecode, state, countries_id, printstate,
               oneliner, writeup, webwriteup, latitude, longitude,
               meta_title, meta_descr, meta_keywords, url
        FROM states
        WHERE states_id = ?
    };

    return fetch_row($sql, [$states_id], 'NAME_lc', 'jadoo', $c);
}

# -----------------------------
# List of states for a country
# -----------------------------
sub states {
    my ($country, $order, $c) = @_;
    $order //= 'state';

    # sanitize order column to prevent SQL injection
    $order = 'states.url' if $order =~ /url/i;
    $order = 'state'      if $order =~ /name/i;

    my $category_hotel = 27;

    my $sql = qq{
        SELECT s.states_id, s.statecode, s.state, s.countries_id, s.printstate,
               s.oneliner, s.writeup, s.webwriteup, s.latitude, s.longitude,
               s.meta_title, s.meta_descr, s.meta_keywords, s.url
        FROM states s
        INNER JOIN countries c ON c.countries_id = s.countries_id
        WHERE s.states_id IN (
            SELECT DISTINCT st.states_id
            FROM vw_hoteldetails h
            JOIN addresscategories a ON a.addressbook_id = h.addressbook_id
            JOIN states st ON h.states_id = st.states_id
            WHERE a.categories_id = ?
        )
        AND c.url LIKE ?
        ORDER BY $order
    };

    return fetch_all($sql, [$category_hotel, "$country%"], 'NAME', 'jadoo', $c);
}

# -----------------------------
# Get state details by URL
# -----------------------------
sub statesurl {
    my ($url, $c) = @_;
    return undef unless defined $url;

    my $sql = q{
        SELECT states_id, statecode, state, countries_id, oneliner, writeup,
               webwriteup, latitude, longitude, meta_title, meta_descr,
               meta_keywords, url
        FROM states
        WHERE url LIKE ?
    };

    return fetch_row($sql, [$url], 'NAME_lc', 'jadoo', $c);
}

1;
