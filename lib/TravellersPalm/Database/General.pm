package TravellersPalm::Database::General;

use strict;
use warnings;

use TravellersPalm::Database::Connector qw(fetch_all fetch_row);
use TravellersPalm::Functions qw(boldify addptags);

# -----------------------------
# Categories
# -----------------------------
sub categories {
    my ($c) = @_;
    my $sql = q{
        SELECT DISTINCT c.description,
               a2.categories_id,
               CASE a2.categories_id 
                   WHEN 23 THEN '$'
                   WHEN 36 THEN '$$'
                   WHEN 8  THEN '$$$'
               END AS hotelcategory
        FROM vw_hoteldetails
        JOIN addresscategories a1 ON a1.addressbook_id = vw_hoteldetails.addressbook_id
        JOIN addresscategories a2 ON a2.addressbook_id = vw_hoteldetails.addressbook_id
        JOIN categories c ON a2.categories_id = c.categories_id
        WHERE a1.categories_id = 27
          AND a2.categories_id IN (23,36,8)
        ORDER BY 3
    };
    return fetch_all($sql, [], 'NAME', 'jadoo', $c);
}

# -----------------------------
# Countries URL mapping
# -----------------------------
sub countries_url {
    my ($c) = @_;
    my $sql = q{ SELECT country_name, url FROM countries };
    return fetch_all($sql, [], 'NAME', 'jadoo', $c);
}

# -----------------------------
# Day-by-day itinerary
# -----------------------------
sub daybyday {
    my ($itinerary_id, $c) = @_;
    return [] unless defined $itinerary_id;
    my $sql = q{
        SELECT day_no, description
        FROM itinerary_days
        WHERE itinerary_id = ?
        ORDER BY day_no
    };
    return fetch_all($sql, [$itinerary_id], 'NAME', 'jadoo', $c);
}

# -----------------------------
# Hotel info
# -----------------------------
sub hotel {
    my ($hotel_id, $c) = @_;
    return {} unless defined $hotel_id;
    my $sql = q{ SELECT * FROM hotels WHERE hotel_id = ? };
    return fetch_row($sql, [$hotel_id], 'NAME_lc', 'jadoo', $c);
}

# -----------------------------
# Meta tags
# -----------------------------
sub metatags {
    my ($url, $c) = @_;
    return {} unless defined $url;
    my $sql = q{
        SELECT meta_title, meta_descr, meta_keywords
        FROM webpages
        WHERE url = ?
    };
    return fetch_row($sql, [$url], 'NAME_lc', 'jadoo', $c);
}

# -----------------------------
# Modules info
# -----------------------------
sub modules {
    my ($c) = @_;
    my $sql = q{ SELECT * FROM modules ORDER BY module_name };
    return fetch_all($sql, [], 'NAME', 'jadoo', $c);
}

# -----------------------------
# Regions
# -----------------------------
sub regionnames {
    my ($c) = @_;
    my $sql = q{ SELECT region_id, region FROM regions };
    return fetch_all($sql, [], 'NAME', 'jadoo', $c);
}

sub regions {
    my ($c) = @_;
    my $sql = q{ SELECT DISTINCT region FROM regions ORDER BY region };
    return fetch_all($sql, [], 'NAME', 'jadoo', $c);
}

sub regionsurl {
    my ($c) = @_;
    my $sql = q{ SELECT region, url FROM regions };
    return fetch_all($sql, [], 'NAME', 'jadoo', $c);
}

# -----------------------------
# Total trains
# -----------------------------
sub totaltrains {
    my ($c) = @_;
    my $sql = q{ SELECT COUNT(*) AS total FROM trains };
    return fetch_row($sql, [], 'NAME_lc', 'jadoo', $c);
}

# -----------------------------
# Webpages
# -----------------------------
sub webpages {
    my ($id, $c) = @_;
    return {} unless defined $id;
    my $sql = q{
        SELECT pagename, url, meta_title, meta_descr, meta_keywords
        FROM webpages
        WHERE webpages_id = ?
    };
    return fetch_row($sql, [$id], 'NAME_lc', 'jadoo', $c);
}

# -----------------------------
# Single Web entry
# -----------------------------
sub web {
    my ($id, $c) = @_;
    return {} unless defined $id;
    my $sql = q{
        SELECT srno, title, pagename, writeup, webpages_id
        FROM Web
        WHERE Web_id = ?
    };
    return fetch_row($sql, [$id], 'NAME_lc', 'jadoo', $c);
}

# -----------------------------
# Single Web entry with formatted writeup
# -----------------------------
sub webtext {
    my ($id, $c) = @_;
    return {} unless defined $id;

    my $sql = q{
        SELECT srno, title, pagename, writeup, webpages_id
        FROM Web
        WHERE Web_id = ?
    };

    my $data = fetch_row($sql, [$id], 'NAME_lc', 'jadoo', $c);

    # Ensure hashref
    $data = {} unless ref $data eq 'HASH';
    $data->{writeup} = '' unless defined $data->{writeup};

    # Format writeup safely
    $data->{writeup} = boldify(addptags($data->{writeup})) if $data->{writeup};

    return $data;
}

# -----------------------------
# Fetch multiple webtext entries at once
# Returns a hashref keyed by Web_id
# -----------------------------
sub webtext_multi {
    my ($ids, $c) = @_;
    return {} unless $ids && ref $ids eq 'ARRAY' && @$ids;

    my $placeholders = join ',', ('?') x @$ids;

    my $sql = qq{
        SELECT Web_id, srno, title, pagename, writeup, webpages_id
        FROM Web
        WHERE Web_id IN ($placeholders)
    };

    my $rows = fetch_all($sql, $ids, 'NAME_lc', 'jadoo', $c);

    my %result;
    for my $row (@$rows) {
        # Ensure writeup is processed like webtext
        my $writeup = defined $row->{writeup} ? boldify(addptags($row->{writeup})) : '';
        $result{$row->{Web_id}} = {
            %$row,
            writeup => $writeup,
        };
    }

    return \%result;
}

1;
