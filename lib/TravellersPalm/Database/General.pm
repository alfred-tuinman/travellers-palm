package TravellersPalm::Database::General;

use strict;
use warnings;

use Data::Dumper;
use Exporter 'import';
use TravellersPalm::Database::Connector qw(fetch_all fetch_row);

our @EXPORT_OK = qw(
    categories
    countries_url
    daybyday
    hotel
    metatags
    modules
    regionnames
    regions
    regionsurl
    totaltrains
    webpages
    web
);

# -----------------------------
# Categories (example multi-row)
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
    return fetch_all($sql, [],'NAME', 'jadoo', $c);
}

# -----------------------------
# Countries URL mapping
# -----------------------------
sub countries_url {
    my ($c) = @_;
    my $sql = q{
        SELECT country_name, url
        FROM countries
    };
    return fetch_all($sql,[], 'NAME', 'jadoo', $c);
}

# -----------------------------
# Day-by-day itinerary info
# -----------------------------
sub daybyday {
    my ($itinerary_id, $c) = @_;
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
    my $sql = q{
        SELECT *
        FROM hotels
        WHERE hotel_id = ?
    };
    return fetch_row($sql, [$hotel_id], 'NAME_lc', 'jadoo', $c);
}

# -----------------------------
# Meta tags (single row)
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
    my $sql = q{
        SELECT *
        FROM modules
        ORDER BY module_name
    };
    return fetch_all($sql,[], 'NAME', 'jadoo', $c);
}

# -----------------------------
# Region names
# -----------------------------
sub regionnames {
    my ($c) = @_;
    my $sql = q{
        SELECT region_id, region
        FROM regions
    };
    return fetch_all($sql,[], 'NAME', 'jadoo', $c);
}

# -----------------------------
# Regions (example for listing)
# -----------------------------
sub regions {
    my ($c) = @_;
    my $sql = q{
        SELECT DISTINCT region
        FROM regions
        ORDER BY region
    };
    return fetch_all($sql,[], 'NAME', 'jadoo', $c);
}

# -----------------------------
# Regions URL mapping
# -----------------------------
sub regionsurl {
    my ($c) = @_;
    my $sql = q{
        SELECT region, url
        FROM regions
    };
    return fetch_all($sql,[], 'NAME', 'jadoo', $c);
}

# -----------------------------
# Total trains (example)
# -----------------------------
sub totaltrains {
    my ($c) = @_;
    my $sql = q{
        SELECT COUNT(*) AS total
        FROM trains
    };
    return fetch_row($sql, [], 'NAME_lc', 'jadoo', $c);
}

# -----------------------------
# Webpages (single row)
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
# Web entry (single row)
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

1;
