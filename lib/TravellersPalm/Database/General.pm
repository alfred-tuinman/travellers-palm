package TravellersPalm::Database::General;

use strict;
use warnings;

use Exporter 'import';
use TravellersPalm::Database::Connector qw(fetch_all fetch_row execute); 
use Mojo::Log;
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
# Categories
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
    return fetch_all($sql, []);
}

# -----------------------------
# Get country by column (like URL, id)
# -----------------------------
sub countries_url {
    my ($column, $country) = @_;
    return unless $column && $country;

    my $sql = qq{
        SELECT countries_id, country, isd, gmt, countrycode, writeup, currencies_id
        FROM countries
        WHERE $column = ?
    };
    return fetch_row($sql, [$country], 'NAME_lc');
}

# -----------------------------
# Day-by-day itinerary for tour
# -----------------------------
sub daybyday {
    my ($tour) = @_;
    return [] unless defined $tour;
    
    my $sql = q{
        SELECT c.dayno,
               c.dayitinerary,
               c.cities_id,
               c.endoftour,
               (SELECT city FROM cities s WHERE s.cities_id = c.cities_id) AS city
        FROM fixeditin f
        JOIN CityDayFixedItin c ON f.FixedItin_id = c.FixedItin_id
        WHERE f.url LIKE ?
        ORDER BY c.dayno
    };
    return fetch_all($sql, [$tour]);
}

# -----------------------------
# Hotel info
# -----------------------------
sub hotel {
    my ($hotel_id) = @_;
    return [] unless defined $hotel_id;
    
    my $sql = q{
        SELECT h.addressbook_id AS hotel_id,
               h.organisation AS hotel,
               SUBSTR(h.description,1,80) AS truncdesc,
               h.description AS description,
               h.city,
               h.cities_id,
               CASE a.categories_id 
                   WHEN 23 THEN 10
                   WHEN 36 THEN 20
                   WHEN 8  THEN 30
               END AS category,
               CASE a.categories_id 
                   WHEN 23 THEN '$'
                   WHEN 36 THEN '$$'
                   WHEN 8  THEN '$$$'
               END AS categoryname
        FROM vw_hoteldetails h
        JOIN addresscategories a ON a.addressbook_id = h.addressbook_id
        WHERE a.addressbook_id = ?
          AND a.categories_id IN (23,36,8)
    };
    
    return fetch_row($sql, [$hotel_id], 'NAME_lc');
}

# -----------------------------
# Meta tags
# -----------------------------
sub metatags {
    my ($url) = @_;
    return [] unless defined $url;

    my $sql = q{
        SELECT meta_title, meta_descr, meta_keywords
        FROM webpages
        WHERE url = ?
    };
    
    return fetch_row($sql, [$url], 'NAME_lc');
}

# -----------------------------
# Modules / tours list
# -----------------------------
sub modules {
    my %args = (
        currency => 'USD',
        order    => 'popularity',
        @_,
    );

    my $order_by = $args{order} =~ /popularity/i ? 'f.orderno'
                  : $args{order} =~ /price/i      ? 'cost'
                  : $args{order} =~ /days/i       ? 'numdays'
                  : $args{order} =~ /name/i       ? 'f.title'
                  : $args{order} =~ /url/i        ? 'f.url'
                  : 'f.orderno';

    $order_by .= ' DESC' if $args{order} =~ /desc/i;

    my $sql = qq{
        SELECT f.fixeditin_id AS tourname,
               f.title,
               f.oneliner,
               f.introduction,
               f.itinerary,
               f.triphighlights,
               f.quotes,
               f.adv,
               f.regions_id,
               f.readytours,
               f.url,
               f.itindates,
               f.inclusions,
               f.prices,
               f.orderno,
               f.days,
               f.duration,
               (SELECT CAST(MIN(fc.cost) AS INT)
                FROM fixeditincosts fc
                JOIN currencies c ON fc.currencies_id = c.currencies_id
                WHERE fc.fixeditin_id=f.fixeditin_id
                  AND principalagents_id=68
                  AND frompax=2 AND topax=2
                  AND wet IS NULL
                  AND c.currencycode LIKE ?) AS cost,
               (SELECT COUNT(fi.dayno)
                FROM CityDayFixedItin fi
                WHERE fi.FixedItin_id = f.FixedItin_id) AS numdays
        FROM fixeditin f
        JOIN regions r ON r.regions_id = f.regions_id
        WHERE r.url = ?
          AND inactivewef IS NULL
        ORDER BY $order_by
    };
    return fetch_all($sql, [$args{currency}, $args{region}]);
}

# -----------------------------
# Region names
# -----------------------------
sub regionnames {

    my $sql = q{
        SELECT title
        FROM regions
        ORDER BY orderno
    };
    
    return fetch_all($sql,[]);
}

# -----------------------------
# Regions
# -----------------------------
sub regions {
    my ($order) = @_;
    return 'orderno' unless defined $order;

    $order = 'title' if $order =~ /name/i;
    $order = 'url'   if $order =~ /url/i;

    my $sql = qq{
        SELECT regions_id, title, oneliner, introduction, region, url
        FROM regions
        ORDER BY $order
    };
    return fetch_all($sql, []);
}

# -----------------------------
# Region by URL
# -----------------------------
sub regionsurl {
    my ($url) = @_;
    return [] unless defined $url;

    my $sql = q{
        SELECT regions_id, title, oneliner, introduction, region, url
        FROM regions
        WHERE url = ?
    };

    return fetch_row($sql, [$url], 'NAME_lc');
}

# -----------------------------
# Total trains
# -----------------------------
sub totaltrains {
    my $sql = q{ SELECT startname FROM zz_trains };
    my $rows = fetch_all($sql, []);
    
    return scalar @$rows;
}

# -----------------------------
# Webpages
# -----------------------------
sub webpages {
    my ($id) = @_;
    return [] unless defined $id;

    my $sql = q{
        SELECT pagename, url, meta_title, meta_descr, meta_keywords
        FROM webpages
        WHERE webpages_id = ?
    };
    return fetch_row($sql, [$id], 'NAME_lc');
}

# -----------------------------
# Web entry
# -----------------------------
sub web {
    my ($id) = @_;
    return { rows => 0, data => {} } unless defined $id;

    my $sql = q{
        SELECT srno, title, pagename, writeup, webpages_id
        FROM Web
        WHERE Web_id = ?
    };

    my $text = TravellersPalm::Database::Connector->fetch_row($sql, [$id], 'NAME_lc');

    my $data = {
        rows => $text ? 1 : 0,
        data => $text // {},
    };

    return $data;
}



1;
