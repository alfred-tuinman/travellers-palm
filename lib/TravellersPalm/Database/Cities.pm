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
  cityidea 
  citythemes 
  nearcities 
  randomcities 
  totalcities);

sub airports {
    my $country = shift // 0;
    my $sql = q/
      SELECT city, RTRIM(citycode
      FROM cities c INNER JOIN countries co ON co.countries_id=c.countries_id
      WHERE airport = 1 AND  nighthalt = 1 AND  citycode IS NOT NULL AND co.url = ? 
      ORDER BY c.city /;
   return TravellersPalm::Database::Connector::fetch_row( $sql, [ $country ]);
}

sub get_airports_by_country {
    my $country = shift // 0;
    my $sql = q/
        SELECT city,
               RTRIM(citycode) AS citycode
        FROM   cities c
               INNER JOIN countries co ON co.countries_id = c.countries_id
        WHERE  airport = 1
               AND nighthalt = 1
               AND citycode IS NOT NULL
               AND co.url = ?
        ORDER BY c.city/;
    return TravellersPalm::Database::Connector::fetch_all( $sql, [ $country ]);
}

sub city {
    my $cities_id = shift // 0;

    my $sql = q/
            SELECT 
            cities_id,
            rtrim(citycode) as citycode,
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
            budgethotels_id as budgethotels_id,
            luxuryhotels_id as luxuryhotels_id,
            defaultdays as defaultdays,
            webwriteup as webwriteup,
            latitude as latitude,
            longitude as longitute,
            filterfield as filterfield,
            meta_title as meta_title, 
            meta_descr as meta_descr, 
            meta_keywords as meta_keywords, 
            url
            FROM cities 
            WHERE cities_id = ? /;
    return TravellersPalm::Database::Connector::fetch_row( $sql, [ $cities_id ],,'NAME_lc');
}

sub cityhotels {

    # given hotel preference, returns default
    # hotel *and* all hotels in a city

    my $cityid = shift;
    my $sql    = q/
            SELECT wh.hotel_id, wh.hotel, wh.description, wh.category, wh.categoryname, dh.addressbook_id isdefault
            FROM 
                (
                SELECT  h.addressbook_id hotel_id,
                        h.organisation hotel,
                        h.description description,
                        h.city city,
                        h.cities_id,
                        CASE a2.categories_id 
                        WHEN 23 THEN 10 
                        WHEN 22 THEN 20 
                        WHEN  8 THEN 30 
                        WHEN 35 THEN 40 
                        END as category,
                        case a2.categories_id 
                        when 23 then 'Standard' 
                        when 22 then 'Superior' 
                        when 8 then 'Luxury' 
                        when 35 then 'Top of Line' 
                        end as categoryname
                FROM    vw_hoteldetails h,
                        addresscategories a1,
                        addresscategories a2
                WHERE   a1.categories_id = 27 AND
                        a2.categories_id IN (23, 22, 8, 35) AND
                        a1.addressbook_id = h.addressbook_id AND
                        a2.addressbook_id = h.addressbook_id AND
                        h.cities_id = ?
                ) wh
            LEFT JOIN vw_defaulthotels dh ON wh.hotel_id = dh.addressbook_id 
            ORDER BY category/;
    return TravellersPalm::Database::Connector::fetch_all( $sql, [ $cityid ]);
}

sub cityid {

  my $city = shift;
    my $sql = q/SELECT cities_id FROM cities WHERE city = ?/;
    return TravellersPalm::Database::Connector::fetch_row( $sql, [ $city ]);
}

sub citythemes {

    my $subthemes_id = shift;

    # subtheme: themes_id, title, oneliner, introduction, subtheme, url
    # for google map on theme page
    my $sql = q/
        SELECT  s.cities_id     as id, 
                c.city          as name, 
                c.latitude      as lat, 
                c.longitude     as lng, 
                c.writeup       as descr
        FROM    citythemes s JOIN cities c ON c.cities_id=s.cities_id
        WHERE   s.subthemes_id = $subthemes_id /;
    return TravellersPalm::Database::Connector::fetch_all( $sql);
}

sub nearcities {

    my $cityid  = shift;
    my $sql     = q/
            SELECT  cities.cities_id,
                    cities.city,
                    cities.oneliner,
                    cities.writeup,
                    cities.latitude     as latitude,
                    cities.longitude    as longitude
            FROM    cities,
                    nearcities
            WHERE   cities.cities_id = nearcities.cities_id and 
                    cities.display = 1 and
                    nearcities.maincities_id = ? /;

    return TravellersPalm::Database::Connector::fetch_all( $sql, [$cityid]);
}


sub randomcities {

    my $sql = q/
        SELECT  DISTINCT cities.cities_id   as cities_id, 
                cities.city                 as city
        FROM    cities, defaulthotels
        WHERE   cities.nighthalt = 1 and
                cities.display = 1 and
                cities.countries_id = 200 and
                defaulthotels.cities_id = cities.cities_id
        ORDER   BY 2 /;

      return TravellersPalm::Database::Connector::fetch_all( $sql, [ ]);    
    my $key = "randomcities" . ':' . join( ':', @_ );

    my $cityid = $_[0];
    my %seen = map { $_ => 1 } @_;
    foreach ( @{ nearcities($cityid) } ) {
        $seen{ $_->{cities_id} } = 1;
    }

    my @rndcities = grep { !exists $seen{ $_->{cities_id} } } @$rndcities;

    return \@rndcities;
    
}


sub totalcities {

    my $sql = q/
            SELECT  DISTINCT cities.cities_id  as cities
            FROM    cities, 
                    defaulthotels
            WHERE   cities.nighthalt = 1 and
                    cities.display = 1 and
                    cities.countries_id = 200 and
                    defaulthotels.cities_id = cities.cities_id /;

    my $rows = TravellersPalm::Database::Connector::fetch_all( $sql, []);
    return ( 0 + @{$rows} );
}

1;
