package TravellersPalm::Database::States;

use strict;
use warnings;

use Exporter 'import';
use TravellersPalm::Database::Core::Connector qw(fetch_all fetch_row);
use TravellersPalm::Database::Core::Validation qw(
    validate_string 
    validate_integer
    validate_order
);

# -----------------------------
# Get a single state by ID
# -----------------------------
sub state {
    my ($states_id, $c) = @_;
    
    # Validate state ID
    eval {
        $states_id = validate_integer($states_id, 1, 1, 1000); # Required, range 1-1000
    };
    if ($@) {
        warn "Input validation failed in state(): $@";
        return undef;
    }

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
    
    # Validate inputs
    eval {
        $country = validate_string($country, 0, 2, 'IN');    # Optional (defaults to IN), 2 chars
        $order = validate_string($order, 0, 50, 'state');    # Optional (defaults to 'state')
    };
    if ($@) {
        warn "Input validation failed in states(): $@";
        return undef;
    }

    # Safe mapping of sort keys to full column names to avoid SQL injection
    my %order_map = (
        'statecode'  => 's.statecode',
        'state'      => 's.state',
        'printstate' => 's.printstate',
        'oneliner'   => 's.oneliner',
        'url'        => 's.url'
    );

    # Default to statecode if order key not found in mapping
    my $order_col = $order_map{$order // ''} || $order_map{'statecode'};
    
    my $category_hotel = 27;

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
        ORDER BY $order_col
    };

    return fetch_all($sql, [$category_hotel, "$country%"], 'NAME', 'jadoo', $c);
}

# -----------------------------
# Get state details by URL
# -----------------------------
sub statesurl {
    my ($url, $c) = @_;
    
    # Validate URL
    eval {
        $url = validate_string($url, 1, 255); # Required, max 255 chars
    };
    if ($@) {
        warn "Input validation failed in statesurl(): $@";
        return undef;
    }

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
