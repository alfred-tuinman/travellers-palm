package TravellersPalm::Database::States;

use strict;
use warnings;

use Exporter 'import';
use TravellersPalm::Database::Connector qw(fetch_all fetch_row);

=pod
our @EXPORT_OK = qw(
    state
    states
    statesurl
=cut

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
    $country //= 'IN';
    $order //= 'state';

    # sanitize order column to prevent SQL injection
    $order = 'states.url' if $order =~ /url/i;
    $order = 'state'      if $order =~ /name/i;

    my $category_hotel = 27;

    # whitelist allowed columns for ordering
    my %allowed_columns = map { $_ => 1 } qw(statecode state printstate oneliner);
    $order = 'statecode' unless $allowed_columns{$order};

    my $sql = qq{
        SELECT DISTINCT s.states_id, s.statecode, s.state, s.countries_id, s.printstate,
              s.oneliner, s.writeup, s.webwriteup, s.latitude, s.longitude,
              s.meta_title, s.meta_descr, s.meta_keywords, s.url
        FROM states s
        INNER JOIN countries c ON c.countries_id = s.countries_id
        INNER JOIN vw_hoteldetails h ON h.states_id = s.states_id
        INNER JOIN addresscategories a ON a.addressbook_id = h.addressbook_id
        WHERE a.categories_id = ?
          AND c.url LIKE ?
        ORDER BY s."$order"
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
