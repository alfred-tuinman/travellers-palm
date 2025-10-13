package TravellersPalm::Database::General;

use strict;
use warnings;
use Exporter 'import';
use TravellersPalm::Database::Connector qw(fetch_all fetch_row execute);
use Data::Dumper;

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
# Internal wrappers for logging
# -----------------------------
sub _fetch_row {
    my ($sql, $bind_ref, $key_style, $dbkey) = @_;
    $bind_ref  //= [];
    $key_style //= 'NAME_lc';

    warn "[General] fetch_row called with SQL: $sql, Bind: " . Dumper($bind_ref);
    return fetch_row($sql, $bind_ref, $key_style, $dbkey);
}

sub _fetch_all {
    my ($sql, $bind_ref, $dbkey) = @_;
    $bind_ref //= [];

    warn "[General] fetch_all called with SQL: $sql, Bind: " . Dumper($bind_ref);
    return fetch_all($sql, $bind_ref, $dbkey);
}

# -----------------------------
# Meta tags (single row)
# -----------------------------
sub metatags {
    my ($url) = @_;
    return {} unless defined $url;

    my $sql = q{
        SELECT meta_title, meta_descr, meta_keywords
        FROM webpages
        WHERE url = ?
    };
    return _fetch_row($sql, [$url], 'NAME_lc', 'jadoo');
}

# -----------------------------
# Webpages (single row)
# -----------------------------
sub webpages {
    my ($id) = @_;
    return {} unless defined $id;

    my $sql = q{
        SELECT pagename, url, meta_title, meta_descr, meta_keywords
        FROM webpages
        WHERE webpages_id = ?
    };
    return _fetch_row($sql, [$id], 'NAME_lc', 'jadoo');
}

# -----------------------------
# Web entry (single row)
# -----------------------------
sub web {
    my ($id) = @_;
    return {} unless defined $id;

    my $sql = q{
        SELECT srno, title, pagename, writeup, webpages_id
        FROM Web
        WHERE Web_id = ?
    };
    return _fetch_row($sql, [$id], 'NAME_lc', 'jadoo');
}

# -----------------------------
# Example multi-row with logging
# -----------------------------
sub categories {
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
    return _fetch_all($sql, [], 'jadoo');
}

1;
