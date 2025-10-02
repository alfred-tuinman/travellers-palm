package TravellersPalm::Database::Themes;

use strict;
use warnings;

use Exporter 'import';
use TravellersPalm::Database::Connector qw();

our @EXPORT_OK = qw( 
    subthemes
    subthemes_id
    themes
    themes_subthemes
    themes_url 
    themetrips
    themeurl
    );


sub subthemes {

    my $themes_id = shift;
    my $sql       = "
            SELECT  subthemes_id    as subthemes_id, 
                    themes_id       as themes_id, 
                    title           as title, 
                    oneliner        as oneliner, 
                    introduction    as introduction, 
                    subtheme        as subtheme, 
                    url 
            FROM    subthemes 
            WHERE   themes_id = $themes_id
            ORDER   BY title";

    return TravellersPalm::Database::Connector::fetch_all( $sql);
}

sub subthemes_id {

    my $subthemes_id = shift;
    my $sql          = "
            SELECT  subthemes_id    as subthemes_id, 
                    themes_id       as themes_id, 
                    title           as title, 
                    oneliner        as oneliner, 
                    introduction    as introduction, 
                    subtheme        as subtheme, 
            FROM    subthemes 
            WHERE   subthemes_id = ?";

    return TravellersPalm::Database::Connector::fetch_row( $sql, [$subthemes_id],,'NAME_lc');
  }

sub themes {

    my $parameter = shift;
    my $order     = shift // 'title';

    my $condition = '';

    if ( defined($parameter) ) {
        $condition = ( uc($parameter) eq 'LIMIT' ) ? "WHERE themes_id < 7" : "WHERE themes_id > 6";
    }

    my $order_by;
    $order_by = 'pagename' if ( $order =~ m/title/i );
    $order_by = 'url'      if ( $order =~ m/url/i );

    my $sql =  "
        SELECT  pagename        as pagename, 
                introduction    as introduction, 
                url             as url, 
                oneliner        as oneliner, 
                meta_title      as title, 
                meta_descr      as meta_descr, 
                meta_keywords   as meta_keywords, 
                themes_id       as themes_id
        FROM    themes 
                $condition 
        ORDER   BY $order_by";

    return TravellersPalm::Database::Connector::fetch_all( $sql);
}


sub themes_subthemes {

    my $themes_id = shift;

    # for google map on theme page
    my $sql = "
        SELECT  s.cities_id         as id, 
                c.city              as name, 
                c.latitude          as lat, 
                c.longitude         as lng, 
                c.writeup           as descr,
                s.subthemes_id      as subthemes_id
        FROM    citythemes s 
                JOIN cities c ON c.cities_id=s.cities_id
                JOIN themes t on t.themes_id=s.themes_id
        WHERE   t.themes_id = $themes_id AND 
                c.latitude IS NOT NULL
        ORDER   BY s.subthemes_id";

    return TravellersPalm::Database::Connector::fetch_all( $sql);
}

sub themes_url {

    my $theme = shift;
    my $sql   = "
        SELECT  pagename        as pagename, 
                introduction    as introduction, 
                url, 
                oneliner        as oneliner, 
                meta_title      as title, 
                meta_descr      as meta_descr, 
                meta_keywords   as meta_keywords, 
                themes_id       as themes_id
        FROM    themes 
        WHERE   url like ? ";

    return TravellersPalm::Database::Connector::fetch_row( $sql, [$theme],,'NAME_lc');
}

sub themetrips {

    my $tour     = shift;
    my $currency = shift // 'USD';
    my $order    = shift // 'popularity';

    $tour = 1 if ( lc($tour) eq 'wildlife' );
    $tour = 2 if ( lc($tour) eq 'landscape' );
    $tour = 3 if ( lc($tour) eq 'adventure' );
    $tour = 4 if ( lc($tour) eq 'beaches' );
    $tour = 5 if ( lc($tour) eq 'religion' );
    $tour = 6 if ( lc($tour) eq 'monuments' );

    my $order_by = 'f.orderno';
    $order_by = 'f.orderno' if ( $order =~ m/popularity/i );
    $order_by = 'cost'      if ( $order =~ m/price/i );
    $order_by = 'numdays'   if ( $order =~ m/days/i );

    $order_by = 'f.title'   if ( $order =~ m/name/i );
    $order_by = 'f.url'     if ( $order =~ m/url/i );

    if ( $order =~ m/desc/i ) {
        $order_by .= ' DESC';
    }

    my $sql = "
            SELECT  f.fixeditin_id  as tourname,
                    f.title         as title,
                    f.oneliner      as oneliner,
                    f.introduction  as introduction,
                    LENGTH(f.introduction) as lengthintro,
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
                    inactivewef     as inactivewef,
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
                            c.currencycode  like ?
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
                                    th.Themes_id = ?
                            ) 
            ORDER BY ".$order_by ;

    return TravellersPalm::Database::Connector::fetch_row( $sql, [$currency,$tour]);
}

sub themeurl {

    my $url = shift;
    my $key = "themes:$url";
    my $sql = "
        SELECT  title           as title,
                introduction    as introduction,
                url,
                meta_title      as meta_title, 
                meta_descr      as meta_descr, 
                meta_keywords   as meta_keywords, 
                themes_id       as themes_id 
        FROM    themes 
        where   url like ?";

    return TravellersPalm::Database::Connector::fetch_row( $sql, [$url],,'NAME_lc');
}

1;
