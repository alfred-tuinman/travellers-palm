package TravellersPalm::Database::Cities;

use strict;
use warnings;

use Exporter 'import';
use TravellersPalm::Database::Connector qw(fetch_all fetch_row);

our @EXPORT_OK = qw(
    airports
    get_airports_by_country
    city
    cityhotels
    cityid
    citythemes
    cityidea
    nearcities
    randomcities
    totalcities
);

# -----------------------------
# Airports
# -----------------------------
sub airports {
    my $country = shift // 0;
    my $sql = q{
        SELECT city, RTRIM(citycode) AS citycode
        FROM cities c
        JOIN countries co ON co.countries_id = c.countries_id
        WHERE airport = 1 AND nighthalt = 1 AND citycode IS NOT NULL AND co.url = ?
        ORDER BY c.city
    };
    return fetch_row($sql, [$country]);
}

sub get_airports_by_country {
    my $country = shift // 0;
    my $sql = q{
        SELECT city, RTRIM(citycode) AS citycode
        FROM cities c
        JOIN countries co ON co.countries_id = c.countries_id
        WHERE airport = 1 AND nighthalt = 1 AND citycode IS NOT NULL AND co.url = ?
        ORDER BY c.city
    };
    return fetch_all($sql, [$country]);
}

# -----------------------------
# City Details
# -----------------------------
sub city {
    my $cities_id = shift // 0;
    my $sql = q{
        SELECT 
            cities_id,
            RTRIM(citycode) AS citycode,
            city,
            countries_id,
            oneliner,
            generalinfo,
            gettingthere,
            whattosee,
            excursions,
            courier,
            writeup,
            nighthalt,
            pic1,
            pic2,
            states_id,
            bestairporta_cities_id,
            bestairportb_cities_id,
            bestairportc_cities_id,
            beststationa_cities_id,
            beststationb_cities_id,
            beststationc_cities_id,
            bestcarhirea_cities_id,
            bestcarhireb_cities_id,
            bestcarhirec_cities_id,
            airport,
            railway,
            budgethotels_id,
            luxuryhotels_id,
            defaultdays,
            webwriteup,
            latitude,
            longitude,
            filterfield,
            meta_title,
            meta_descr,
            meta_keywords,
            url
        FROM cities
        WHERE cities_id = ?
    };
    return fetch_row($sql, [$cities_id], 'NAME_lc');
}

# -----------------------------
# Hotels in a city
# -----------------------------
sub cityhotels {
    my $cityid = shift;
    my $sql = q{
        SELECT wh.hotel_id, wh.hotel, wh.description, wh.category, wh.categoryname, dh.addressbook_id AS isdefault
        FROM (
            SELECT  
                h.addressbook_id AS hotel_id,
                h.organisation AS hotel,
                h.description,
                h.city,
                h.cities_id,
                CASE a2.categories_id
                    WHEN 23 THEN 10
                    WHEN 22 THEN 20
                    WHEN 8  THEN 30
                    WHEN 35 THEN 40
                END AS category,
                CASE a2.categories_id
                    WHEN 23 THEN 'Standard'
                    WHEN 22 THEN 'Superior'
                    WHEN 8  THEN 'Luxury'
                    WHEN 35 THEN 'Top of Line'
                END AS categoryname
            FROM vw_hoteldetails h
            JOIN addresscategories a1 ON a1.addressbook_id = h.addressbook_id AND a1.categories_id = 27
            JOIN addresscategories a2 ON a2.addressbook_id = h.addressbook_id AND a2.categories_id IN (23,22,8,35)
            WHERE h.cities_id = ?
        ) wh
        LEFT JOIN vw_defaulthotels dh ON wh.hotel_id = dh.addressbook_id
        ORDER BY category
    };
    return fetch_all($sql, [$cityid]);
}

# -----------------------------
# City ID lookup
# -----------------------------
sub cityid {
    my $city = shift;
    my $sql = q{SELECT cities_id FROM cities WHERE city = ?};
    return fetch_row($sql, [$city]);
}

# -----------------------------
# Themes in a city
# -----------------------------
sub citythemes {
    my $subthemes_id = shift;
    my $sql = q{
        SELECT s.cities_id AS id,
               c.city AS name,
               c.latitude AS lat,
               c.longitude AS lng,
               c.writeup AS descr
        FROM citythemes s
        JOIN cities c ON c.cities_id = s.cities_id
        WHERE s.subthemes_id = ?
    };
    return fetch_all($sql, [$subthemes_id]);
}

# -----------------------------
# Ideas in a city
# -----------------------------
sub cityidea {
    my $cities_id = shift;
    my $sql = q{
        SELECT idea_id, title, description, pic1, pic2
        FROM cityideas
        WHERE cities_id = ?
        ORDER BY title
    };
    return fetch_all($sql, [$cities_id]);
}

# -----------------------------
# Nearby cities
# -----------------------------
sub nearcities {
    my $cityid = shift;
    my $sql = q{
        SELECT c.cities_id, c.city, c.oneliner, c.writeup, c.latitude, c.longitude
        FROM cities c
        JOIN nearcities n ON c.cities_id = n.cities_id
        WHERE c.display = 1 AND n.maincities_id = ?
    };
    return fetch_all($sql, [$cityid]);
}

# -----------------------------
# Random cities (excluding main and nearby)
# -----------------------------
sub randomcities {
    my $cityid = shift;
    my $all_sql = q{
        SELECT DISTINCT c.cities_id, c.city
        FROM cities c
        JOIN defaulthotels dh ON dh.cities_id = c.cities_id
        WHERE c.nighthalt = 1 AND c.display = 1 AND c.countries_id = 200
        ORDER BY c.city
    };
    my $all_cities = fetch_all($all_sql);

    my %seen = map { $_ => 1 } ($cityid, map { $_->{cities_id} } @{ nearcities($cityid) });
    my @rndcities = grep { !$seen{ $_->{cities_id} } } @$all_cities;

    return \@rndcities;
}

# -----------------------------
# Total cities count
# -----------------------------
sub totalcities {
    my $sql = q{
        SELECT DISTINCT c.cities_id
        FROM cities c
        JOIN defaulthotels dh ON dh.cities_id = c.cities_id
        WHERE c.nighthalt = 1 AND c.display = 1 AND c.countries_id = 200
    };
    my $rows = fetch_all($sql);
    return scalar @$rows;
}

1;
