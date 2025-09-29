package TravellersPalm::Database::Itineraries;

use strict;
use warnings;
use Dancer2 appname => 'TravellersPalm';
use TravellersPalm::Database::Connector qw();
use Exporter 'import';

our @EXPORT_OK = qw( 
    isquoted
    itincost 
    itineraries 
    itinerary 
    itinerary_cost 
    itinerary_exist 
    itinerary_id 
    placesyouwillvisit
    similartours 
    tripideas_trips 
    totalitineraries 
    toursinstate 
    youraccommodation
    );


sub isquoted {

    my ( $user, $id ) = @_;

    my $qry = "
        select count(*) from quotes where username = ? and id = ?";

            my $sth = database->prepare($qry);
            $sth->execute($user);
            my ($isquoted) = $sth->fetchrow_array;
            $sth->finish;

            return $isquoted;
}

sub itincost {

    my ( $itinid, $currency ) = shift;

    my $qry = "
    SELECT   cost as cost
    FROM     fixeditincosts, currencies 
    WHERE    fixeditin_id = ? AND 
             principalagents_id = 68 AND
             frompax = 2 AND
             topax = 2 AND
             fixeditincosts.currencies_id = currencies.currencies_id AND
             currencies.currencycode = ?
    ORDER BY wef DESC ";

    my $sth = database->prepare($qry);
    $sth->execute( $itinid, $currency );
    my ($cost) = $sth->fetchrow_array;

    return int($cost);
}

sub itineraries {

    # pass itin, all, or '' for respectively tours, modules, or all

    my %args = (
        currency => 'USD',
        order    => 'popularity',
        @_ ,
        );

    return 0 unless ( lc $args{option} eq 'itin' || lc $args{option} eq 'all' || $args{option} eq '' );

    my $order_by;
    $order_by = 'f.orderno' if ( $args{order} =~ m/popularity/i );
    $order_by = 'cost'      if ( $args{order} =~ m/price/i );
    $order_by = 'numdays'   if ( $args{order} =~ m/days/i );
    $order_by = 'f.title'   if ( $args{order} =~ m/name/i );
    $order_by = 'f.url'     if ( $args{order} =~ m/url/i );

    if ( $args{order} =~ m/desc/i ) {
        $order_by .= ' DESC';
    }

    my $condition = "WHERE (f.readytours=1 or r.url is not null) ";

    if ( $args{option} ne 'all' ) {
        if ( $args{option} eq 'itin' ) {
            $condition = " WHERE f.readytours=1 ";
        }
        else {
            $condition = " WHERE r.url like '$args{option}' ";
        }
    }

    my $qry = "
        SELECT  fixeditin_id            as tourname,
                f.title                 as title, 
                f.oneliner              as oneliner,
                f.introduction          as introduction,
                itinerary               as itinerary,
                triphighlights          as triphighlights,
                quotes                  as quotes,
                adv                     as adv,
                f.regions_id            as regions_id,
                readytours              as readytours,
                itindates               as itindates,
                inclusions              as inclusions,
                prices                  as prices,
                f.orderno               as orderno,
                f.meta_title            as meta_title, 
                f.meta_descr            as meta_descr, 
                f.meta_keywords         as meta_keywords, 
                f.url                   as url,
                (
                    SELECT  CAST(MIN(fc.cost) as INT) 
                    FROM    fixeditincosts fc 
                    JOIN    currencies c ON fc.currencies_id = c.currencies_id
                    WHERE   fc.fixeditin_id=f.fixeditin_id and
                            principalagents_id = 68 and
                            frompax = 2 and
                            topax = 2 and
                            wet IS NULL and 
                            c.currencycode  like '". $args{currency}."'
                ) as cost,
                (
                    SELECT count(fi.dayno) FROM CityDayFixedItin fi WHERE fi.FixedItin_id = f.FixedItin_id
                ) as numdays,
                (
                    SELECT t.url FROM fixeditinthemes fit JOIN themes t ON t.themes_id = fit.themes_id
                                 WHERE fit.fixeditin_id = f.fixeditin_id
                ) as themes
        FROM    fixeditin f 
                LEFT JOIN regions r ON r.regions_id=f.regions_id ". $condition . " AND 
                inactivewef IS NULL
        ORDER   BY " . $order_by;

    return 0 unless database('sqlserver')->selectall_arrayref( $qry, { Slice => {} } );
}


sub itinerary {

    my $tour = shift;

    die('No tour name passed') unless $tour;

    my $qry = q/
            SELECT  f.fixeditin_id  as tourname,
                    f.fixeditin_id  as fixeditin_id,
                    f.title         as title, 
                    f.oneliner      as oneliner, 
                    f.introduction  as introduction, 
                    itinerary       as itinerary, 
                    triphighlights  as triphighlights,
                    quotes          as quotes, 
                    adv             as adv, 
                    f.regions_id    as regions_id, 
                    readytours      as readytours, 
                    itindates       as itindates,  
                    inclusions      as inclusions,
                    prices          as prices, 
                    f.orderno       as orderno, 
                    days            as days, 
                    duration        as duration, 
                    inactivewef     as inactivewef,
                    f.meta_title    as meta_title, 
                    f.meta_descr    as meta_descr, 
                    f.meta_keywords as meta_keywords, 
                    f.url           as url,
                    (
                    SELECT  ec.cities_id as cities_id
                    FROM    cities ec JOIN citydayfixeditin cde ON cde.cities_id=ec.cities_id
                    WHERE   cde.fixeditin_id = f.fixeditin_id
                    ORDER   BY dayno DESC
                    LIMIT   1
                    )               as endcity,
                    (
                    SELECT  sc.cities_id 
                    FROM    cities sc JOIN citydayfixeditin cds ON cds.cities_id=sc.cities_id 
                    WHERE   cds.fixeditin_id = f.fixeditin_id and 
                            dayno=1
                    )               as startcity
            FROM    fixeditin f 
            WHERE   f.url = ? /;
            
            my $sth = database('sqlserver')->prepare($qry);
            $sth->execute($tour);
            my $row = $sth->fetchrow_hashref('NAME_lc');
            $sth->finish;
            return $row;
}


sub itinerary_cost {

    my $fixeditin_id  = shift // 0;
    my $currencycode  = shift // 'USD';

    my $qry = qq/
            SELECT  CAST(MIN(fc.cost) AS INT) as cost, 
                    c.currencycode, 
                    c.symbol
            FROM    fixeditincosts fc 
            JOIN    currencies c ON fc.currencies_id = c.currencies_id
            WHERE   principalagents_id = 68 and
                    frompax = 2 and
                    topax = 2 and
                    wet IS NULL and 
                    fixeditin_id = ? and
                    c.currencycode  like ?
            GROUP BY c.currencycode, symbol/;

            my $sth = database('sqlserver')->prepare( $qry );
            $sth->execute( $fixeditin_id, $currencycode );
            my $row = $sth->fetchrow_hashref('NAME_lc');
            $sth->finish;

            return $row;
}


sub itinerary_exist {

    my $tour = shift ;

            my $qry = "SELECT f.fixeditin_id FROM  fixeditin f WHERE f.url = ? ";

            my $sth = database('sqlserver')->prepare($qry);
            $sth->execute($tour);
            my $row = $sth->fetchrow_hashref('NAME_lc');
            $sth->finish;

            my $exist->{exist} = (ref $row eq ref {} ) ? $row->{fixeditin_id} : 0 ;

            return $exist;
}


sub itinerary_id {

    my $id = shift // 0;

    my $qry = "
            SELECT  title           as title,
                    oneliner        as oneliner,
                    introduction    as introduction,
                    itinerary       as itinerary,
                    triphighlights  as triphighlights,
                    quotes          as quotes,
                    adv             as adv,
                    regions_id      as regions_id,
                    readytours      as readytours,
                    url             as url,
                    itindates       as itindates,
                    inclusions      as inclusions,
                    prices          as prices,
                    orderno         as orderno,
                    days            as days,
                    duration        as duration,
                    (SELECT cast(min(c.cost) as INT) from fixeditincosts c where c.fixeditin_id=f.fixeditin_id) as cost
            FROM    fixeditin f 
            WHERE   fixeditin_id = ? ";

            my $sth = database('sqlserver')->prepare($qry);
            $sth->execute($id);
            my $row = $sth->fetchrow_hashref('NAME_lc');
            $sth->finish;

            return $row;
}


sub placesyouwillvisit {

    my $tour = shift;
    my $qry  = "
        SELECT  city        as city,
                cities_id   as cities_id,
                oneliner    as oneliner,
                writeup     as writeup,
                url         as url,
                dayno       as dayno,
                imagename   as imagename ,
                latitude    as latitude,
                longitude   as longitude
        FROM    (  
                SELECT  c.city, 
                        c.cities_id, 
                        c.oneliner, 
                        writeup, 
                        c.url, 
                        cdf.dayno,
                        c.latitude,
                        c.longitude
                FROM    fixeditin f 
                        INNER JOIN CityDayFixedItin cdf on f.FixedItin_id = cdf.FixedItin_id
                        INNER JOIN cities c on cdf.cities_id = c.cities_id
                WHERE   f.url like '$tour' 
                ORDER   BY c.city 
                ) a  
                JOIN images on cities_id = images.ImageObjectId
        WHERE   ImageCategories_id=1 and 
                ImageTypes_id = 4 and 
                srno < 6 
        ORDER   BY dayno";
                          
        return database('sqlserver')->selectall_arrayref( $qry, { Slice => {} } );
}

sub similartours {

    my $city     = shift // 0;
    my $currency = shift;
    my $qry      = "
            SELECT  fixeditin_id        as tourname,
                    f.title             as title,
                    f.oneliner          as oneliner,
                    f.introduction      as introduction,
                    itinerary           as itinerary,
                    f.regions_id        as regions_id,
                    readytours          as readytours, 
                    f.startcities_id    as scity, 
                    prices              as prices,
                    f.orderno           as orderno,
                    days                as numdays,
                    f.url               as url,
                    (
                        SELECT  CAST(MIN(fc.cost) as INT) 
                        FROM    fixeditincosts fc,
                                currencies c
                        WHERE   fc.fixeditin_id=f.fixeditin_id and 
                                principalagents_id = 68 and
                                frompax = 2 and 
                                topax = 2 and
                                fc.currencies_id = c.currencies_id and
                                c.currencycode like '$currency'
                    ) as cost                       
            FROM    fixeditin f LEFT JOIN regions r ON r.regions_id=f.regions_id 
            WHERE   (f.readytours=1 or r.url is not null) and 
                    inactivewef is NULL and 
                    f.startcities_id = $city  
            ORDER   BY RANDOM() 
            LIMIT   3 ";
                    
            return database('sqlserver')->selectall_arrayref( $qry, { Slice => {} } );
}


sub tripideas_trips {

    my $tour     = shift;
    my $currency = shift // 'USD';
    my $exchrate = shift;
    my $order    = shift // 'popularity';

    $tour = lc($tour);

    my $order_by;
    $order_by = 'f.orderno' if ( $order eq 'popularity' );
    $order_by = 'cost'      if ( $order eq 'price' );
    $order_by = 'numdays'   if ( $order eq 'days' );

    if ( $order =~ m/desc/i ) {
        $order_by .= ' DESC';
    }

    my $qry = "
            SELECT f.fixeditin_id   as tourname,
                f.title             as title,
                f.oneliner          as oneliner,
                f.introduction      as introduction,
                DATALENGTH(f.introduction) as lengthintro,
                itinerary           as itinerary,
                triphighlights      as triphighlights,
                quotes              as quotes,
                adv                 as adv,
                f.regions_id        as regions_id,
                readytours          as readytours,
                itindates           as itindates,
                inclusions          as inclusions,
                prices              as prices,
                f.orderno,days      as numdays,
                duration            as duration,
                inactivewef         as inactivewef,
                f.meta_title        as meta_title, 
                f.meta_descr        as meta_descr, 
                f.meta_keywords     as meta_keywords, 
                f.url,f.startcities_id as scity,
                (
                SELECT  cast(min(fc.cost/$exchrate) as INT) 
                FROM    fixeditincosts fc,
                        currencies c
                WHERE   fc.fixeditin_id=f.fixeditin_id and 
                        fc.principalagents_id = 68 and
                        frompax = 2 and
                        topax = 2 and
                        fc.currencies_id = c.currencies_id and
                        c.currencycode = 'INR' 
                ) as cost,
                (SELECT city FROM cities s WHERE s.cities_id=f.startcities_id) as startcity,
                (SELECT city FROM cities e WHERE e.cities_id=f.endcities_id) as endcity                                  
            FROM    fixeditin f 
            WHERE   f.fixeditin_id IN 
                    (
                    SELECT  DISTINCT f.fixeditin_id                                      
                    FROM    fixeditin f 
                    INNER   JOIN FixedItinThemes fit ON fit.fixeditin_id = f.fixeditin_id
                    INNER   JOIN themes th ON fit.themes_id = th.themes_id  
                    INNER   JOIN fixeditincosts fc ON fc.fixeditin_id=f.fixeditin_id
                    WHERE   inactivewef is NULL AND 
                    fc.principalagents_id = 68 AND 
                    th.url LIKE $tour
                    ) 
            ORDER   BY $order_by ";

    return database('sqlserver')->selectall_arrayref( $qry, { Slice => {} } );
}


sub totalitineraries {

    my $qry = "
            SELECT  fixeditin_id                              
            FROM    fixeditin f 
                    LEFT JOIN regions r ON r.regions_id=f.regions_id 
            WHERE   (f.readytours=1 or r.url is not null) and 
                    inactivewef is NULL
            ORDER   BY days ";

            my $sth = database('sqlserver')->prepare($qry);
            $sth->execute();
            my $rows = $sth->fetchall_arrayref( {} );
            $sth->finish;

            return ( 0 + @{$rows} );
}



sub toursinstate {

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

    # in the addressbook Odyssey is 68 which is linked as principalagents_id in fixeditincosts

    my $qry = "
        SELECT  f.fixeditin_id  as tourname,
                f.title         as title,
                f.oneliner      as oneliner,
                SUBSTR(f.introduction,0,400) as introduction,
                itinerary       as itinerary,
                triphighlights  as triphighlights,
                quotes          as quotes,
                adv             as adv,
                f.regions_id    as regions_id,
                readytours      as readytours,
                itindates       as itindates,
                inclusions      as inclusions,
                prices          as prices,
                f.orderno       as orderno,
                days            as numdays,
                duration        as duration,
                f.inactivewef   as inactivewef,
                f.meta_title    as meta_title, 
                f.meta_descr    as meta_descr, 
                f.meta_keywords as meta_keywords, 
                f.url,
                f.startcities_id as scity,
                (
                SELECT  CAST(MIN(fc.cost) AS INT) 
                FROM    fixeditincosts fc 
                JOIN    currencies c ON fc.currencies_id = c.currencies_id
                WHERE   fc.fixeditin_id=f.fixeditin_id and
                        principalagents_id = 68 and
                        frompax = 2 and
                        topax = 2 and
                        wet IS NULL and 
                        c.currencycode  like '" . $args{currency} . "'
                )               as cost,
                s.city          as startcity,
                (
                SELECT  city 
                from    cities e 
                where e.cities_id=f.endcities_id
                )               as endcity,
                s.latitude      as latitude,
                s.longitude     as longitude                         
        FROM    fixeditin f INNER JOIN cities s ON s.cities_id=f.startcities_id
        WHERE   f.fixeditin_id IN 
                (
                SELECT      DISTINCT f.fixeditin_id 
                FROM        fixeditin f INNER JOIN CityDayFixedItin cd ON cd.fixeditin_id=f.fixeditin_id 
                INNER JOIN  cities c on cd.cities_id = c.cities_id 
                INNER JOIN  states s ON s.states_id = c.states_id 
                INNER JOIN  fixeditincosts fc ON fc.fixeditin_id=f.fixeditin_id
                WHERE       fc.principalagents_id = 68 AND
                            f.inactivewef is NULL AND
                            s.url LIKE '" . $args{state} . "'
                ) 
        ORDER BY $order_by";

        return database('sqlserver')->selectall_arrayref( $qry, { Slice => {} } );
}


sub youraccommodation {

    my $tour = shift;

    my $qry = "
                   SELECT DISTINCT 
                            c.city              as city,
                            h.addressbook_id    as hotel_id,
                            h.organisation      as hotel,
                            SUBSTR(h.description,1,80) as truncated_description,
                            (
                            case a.categories_id 
                                    when 23 then 10 
                                    when 36 then 20 
                                    when 8 then 30  
                                    end
                            ) as category,
                            (
                            case a.categories_id 
                                    when 23 then '\$' 
                                    when 36 then '\$\$' 
                                    when 8 then '\$\$\$' 
                                    end
                            ) as categoryname,
                            c.oneliner  as oneliner, 
                            c.writeup   as writeup
                    FROM    fixeditin f 
                            INNER JOIN CityDayFixedItin cdf ON f.FixedItin_id = cdf.FixedItin_id
                            INNER JOIN vw_hoteldetails h ON h.cities_id=cdf.cities_id
                            INNER JOIN cities c on c.cities_id = h.cities_id
                            LEFT JOIN addresscategories a ON a.addressbook_id = h.addressbook_id
                    WHERE   cdf.EndOfTour <> 1 AND
                            a.categories_id in (23, 36, 8) AND
                            a.ranking = 1 AND
                            f.url like '$tour' 
                            order by cdf.dayno, category ASC
                    ";


            my $original = "select  * 
            from    (
                    SELECT  h.city,
                            ROW_NUMBER() OVER(PARTITION BY h.addressbook_id ORDER BY h.city DESC) rn,
                            h.addressbook_id    as hotel_id,
                            h.organisation      as hotel,
                            SUBSTR(h.description,1,80) as truncated_description,
                            (
                            case a.categories_id 
                                    when 23 then 10 
                                    when 36 then 20 
                                    when 8 then 30  
                                    end
                            ) as category,
                            (
                            case a.categories_id 
                                    when 23 then '\$' 
                                    when 36 then '\$\$' 
                                    when 8 then '\$\$\$' 
                                    end
                            ) as categoryname,
                            c.oneliner  as oneliner, 
                            c.writeup   as writeup,
                            cdf.dayno   as dayno
                    FROM    fixeditin f 
                            INNER JOIN CityDayFixedItin cdf ON f.FixedItin_id = cdf.FixedItin_id
                            INNER JOIN vw_hoteldetails h ON h.cities_id=cdf.cities_id
                            INNER JOIN cities c on c.cities_id = h.cities_id
                            LEFT JOIN addresscategories a ON a.addressbook_id = h.addressbook_id
                    WHERE   cdf.EndOfTour <> 1 AND
                            a.categories_id in (23, 36, 8) AND
                            a.ranking = 1 AND
                            f.url like '$tour'
                    ) a 
            WHERE rn = 1
            ORDER BY dayno, category ASC";

            return database('sqlserver')->selectall_arrayref( $qry, { Slice => {} } );
}

1;


