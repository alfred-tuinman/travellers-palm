package TravellersPalm::Database::General;

use strict;
use warnings;

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

my $SERVER = 'sqlserver';

# ------------- SUBROUTINES/METHODS ------------------

sub categories {

    my $sql = q/
            SELECT 
            DISTINCT c.description,
            a2.categories_id,
            CASE a2.categories_id 
            when 23 then '\$' 
            when 36 then '\$\$'
            when 8 then '\$\$\$' 
            END as hotelcategory
            FROM    vw_hoteldetails, addresscategories a1, addresscategories a2, categories c
            WHERE   a1.categories_id = 27 AND
            a2.categories_id in (23, 36, 8) AND
            a1.addressbook_id = vw_hoteldetails.addressbook_id AND
            a2.addressbook_id = vw_hoteldetails.addressbook_id AND
            a2.categories_id = c.categories_id
            ORDER BY 3 /;

          return TravellersPalm::Database::Connector::fetch_row( $sql, [ ]);
}


sub countries_url {

    my ( $column, $country ) = @_;
  
    my $sql = qq/
        SELECT  countries_id, 
                country, 
                isd, 
                gmt, 
                countrycode, 
                writeup, 
                currencies_id 
        FROM    countries 
        WHERE   $column = ? /;

    return TravellersPalm::Database::Connector::fetch_row( $sql, [ $country ],$SERVER,'NAME_lc');
}

sub daybyday {

    my $tour = shift;
    my $sql  = q/
        SELECT  
        c.dayno         as dayno, 
        c.dayitinerary  as dayitinerary, 
        c.cities_id     as cities_id, 
        c.endoftour     as endoftour,
        (select city from cities s where s.cities_id=c.cities_id) as city
        FROM    fixeditin f INNER JOIN CityDayFixedItin c on f.FixedItin_id = c.FixedItin_id
        WHERE   f.url like ? ORDER BY c.dayno /;

    return TravellersPalm::Database::Connector::fetch_all( $sql, [$tour]);
}


sub hotel {

    my $hotel_id = shift // 0;
    my $sql      = q/
            SELECT 
            h.addressbook_id    as hotel_id, 
            h.organisation      as hotel, 
            h.organisation, 
            SUBSTR(h.description,1,80) as truncdesc,
            h.description       as description,
            h.city city, 
            h.cities_id,
            CASE a.categories_id 
            WHEN 23 THEN 10 
            WHEN 36 THEN 20 
            WHEN 8  THEN 30 
            END                 as category,
            CASE a.categories_id 
            WHEN 23 THEN '\$' 
            WHEN 36 THEN '\$\$' 
            WHEN 8  THEN '\$\$\$'
            END                 as categoryname
            FROM 
            vw_hoteldetails h,  
            addresscategories a
            WHERE 
            a.addressbook_id = h.addressbook_id AND
            a.addressbook_id = ? 
            and a.categories_id in (23,36,8)/;

    return TravellersPalm::Database::Connector::fetch_row( $sql, [ $hotel_id],$SERVER,'NAME_lc');
}


sub metatags {

    my $url = shift // 'index';

    my $data;
    $data->{meta_descr} = '';
    $data->{meta_title}       = '';
    $data->{meta_keywords}    = '';

    my $sql = q/ 
        SELECT  meta_title      as meta_title, 
                meta_descr      as meta_descr, 
                meta_keywords   as meta_keywords
        FROM    webpages 
        WHERE   url = ? /;

    return TravellersPalm::Database::Connector::fetch_row( $sql, [ $url],$SERVER,'NAME_lc');
}

sub modules {

    my %args = (
        currency => 'USD',
        order    => 'popularity',
        @_ ,
        );

    my $order_by;
    $order_by = 'f.orderno' if ( $args{order} =~ m/popularity/i );
    $order_by = 'cost'      if ( $args{order} =~ m/price/i );
    $order_by = 'numdays'   if ( $args{order} =~ m/days/i );
    $order_by = 'f.title'   if ( $args{order} =~ m/name/i );
    $order_by = 'f.url'     if ( $args{order} =~ m/url/i );

    if ( $args{order} =~ m/desc/i ) {
        $order_by .= ' DESC';
    }

    my $sql = "
        SELECT   f.fixeditin_id as tourname,
                 f.title           as title,
                 f.oneliner        as oneliner,
                 f.introduction    as introduction,
                 f.itinerary       as itinerary,
                 f.triphighlights  as triphighlights,
                 f.quotes          as quotes,
                 f.adv             as adv,
                 f.regions_id      as regions_id,
                 f.readytours      as readytours,
                 f.url             as url,
                 f.itindates       as itindates,
                 f.inclusions      as inclusions,
                 f.prices          as prices,
                 f.orderno         as orderno,
                 f.days            as days,
                 f.duration        as duration,
                 (SELECT  CAST(MIN(fc.cost) AS INT) 
        FROM     fixeditincosts fc 
                 JOIN currencies c ON fc.currencies_id = c.currencies_id
        WHERE    fc.fixeditin_id=f.fixeditin_id and
                principalagents_id = 68 and
                frompax = 2 and
                topax = 2 and
                wet IS NULL and 
                c.currencycode  like '". $args{currency} . "') as cost,
                (SELECT COUNT(fi.dayno) FROM CityDayFixedItin fi WHERE fi.FixedItin_id = f.FixedItin_id) AS numdays
                FROM    fixeditin f JOIN regions r ON r.regions_id=f.regions_id
                WHERE   r.url = '". $args{region}. "' AND 
                        inactivewef IS NULL
        ORDER BY 
        $order_by";

    return TravellersPalm::Database::Connector::fetch_all( $sql, [  ]);
}

sub regionnames {

    my $sql = q/
        SELECT  title as title
        FROM    regions 
        ORDER   BY orderno /;

    return TravellersPalm::Database::Connector::fetch_all( $sql, [ ]);
}

sub regions {

    my $order = shift // 'orderno';

    $order = 'title' if ( $order =~ m/name/i );
    $order = 'url'   if ( $order =~ m/url/i );

    my $sql = q/
        SELECT  regions_id      as regions_id,
                title           as title,
                oneliner        as oneliner,
                introduction    as introduction,
                region          as region,
                url             as url
        FROM    regions 
        ORDER   BY ? /;
    return TravellersPalm::Database::Connector::fetch_all( $sql, [$order ]);
}

sub regionsurl {

    my $url = shift;
    my $sql = q/
        SELECT  regions_id      as regions_id,
                title           as title,
                oneliner        as oneliner,
                introduction    as introduction,
                region          as region,
                url             as url
        FROM    regions 
        WHERE   url = ? /;
    return TravellersPalm::Database::Connector::fetch_row( $sql, [ $url],$SERVER,'NAME_lc');
}

sub totaltrains {

    my $sql = q/SELECT startname as startname from zz_trains /;
    my $rows = TravellersPalm::Database::Connector::fetch_row( $sql, [ ]);
    return ( 0 + @{$rows} );
}

sub webpages {

    my $id = shift;
    my $sql = q/
        SELECT  pagename        as pagename, 
                url, 
                meta_title      as meta_title, 
                meta_descr      as meta_descr, 
                meta_keywords   as meta_keywords
        FROM    webpages 
        WHERE   webpages_id = ? /;

    return TravellersPalm::Database::Connector::fetch_row( $sql, [ $id],$SERVER,'NAME_lc');
}

sub web {

    my $id  = shift // 0;
    my $sql = q/ 
            SELECT  srno        as srno, 
                    title       as title, 
                    pagename    as pagename, 
                    writeup     as writeup, 
                    webpages_id as webpages_id 
            FROM    Web 
            WHERE   Web_id = ? /;

    my $text = TravellersPalm::Database::Connector::fetch_row($sql,[$id],$SERVER,'NAME_lc');
    my $data;
    $data->{rows} = defined (scalar $text) ? (scalar $text) : 0 ;
    $data->{data} = $text;
    return $data;
}


1;