package TravellersPalm::Database::Itineraries;

use strict;
use warnings;

use Exporter 'import';
use TravellersPalm::Database::Connector qw(fetch_all fetch_row);

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

# -----------------------------
# Check if itinerary is quoted
# -----------------------------
sub isquoted {
    my ($user, $id) = @_;
    my $sql = "SELECT COUNT(*) FROM quotes WHERE username = ? AND id = ?";
    return fetch_row($sql, [$user, $id], $c);
}

# -----------------------------
# Get itinerary cost
# -----------------------------
sub itincost {
    my ($itinid, $currency) = @_;
    my $sql = qq/
        SELECT cost
        FROM fixeditincosts fc
        JOIN currencies c ON fc.currencies_id = c.currencies_id
        WHERE fixeditin_id = ?
          AND principalagents_id = 68
          AND frompax = 2
          AND topax = 2
          AND c.currencycode = ?
        ORDER BY wef DESC
        LIMIT 1
    /;

    my $cost = fetch_row($sql, [$itinid, $currency], $c);
    return int($cost);
}

# -----------------------------
# List itineraries
# -----------------------------
sub itineraries {
    my %args = (
        currency => 'USD',
        order    => 'popularity',
        option   => '',
        @_,
    );

    return 0 unless ($args{option} eq '' || $args{option} eq 'all' || $args{option} eq 'itin');

    my $order_by = 'f.orderno';
    $order_by = 'cost'    if $args{order} =~ /price/i;
    $order_by = 'numdays' if $args{order} =~ /days/i;
    $order_by = 'f.title' if $args{order} =~ /name/i;
    $order_by = 'f.url'   if $args{order} =~ /url/i;
    $order_by .= ' DESC' if $args{order} =~ /desc/i;

    my $condition = '(f.readytours = 1 OR r.url IS NOT NULL)';
    if ($args{option} eq 'itin') {
        $condition = 'f.readytours = 1';
    } elsif ($args{option} && $args{option} ne 'all') {
        $condition = 'r.url LIKE ?';
    }

    my $sql = qq/
        SELECT f.fixeditin_id AS tourname,
               f.title, f.oneliner, f.introduction, itinerary,
               triphighlights, quotes, adv, f.regions_id, readytours,
               itindates, inclusions, prices, f.orderno,
               f.meta_title, f.meta_descr, f.meta_keywords, f.url,
               (
                   SELECT CAST(MIN(fc.cost) AS INT)
                   FROM fixeditincosts fc
                   JOIN currencies c ON fc.currencies_id = c.currencies_id
                   WHERE fc.fixeditin_id = f.fixeditin_id
                     AND principalagents_id = 68
                     AND frompax = 2
                     AND topax = 2
                     AND wet IS NULL
                     AND c.currencycode LIKE ?
               ) AS cost,
               (
                   SELECT COUNT(fi.dayno)
                   FROM CityDayFixedItin fi
                   WHERE fi.fixeditin_id = f.fixeditin_id
               ) AS numdays,
               (
                   SELECT t.url
                   FROM fixeditinthemes fit
                   JOIN themes t ON t.themes_id = fit.themes_id
                   WHERE fit.fixeditin_id = f.fixeditin_id
               ) AS themes
        FROM fixeditin f
        LEFT JOIN regions r ON r.regions_id = f.regions_id
        WHERE $condition
        ORDER BY $order_by
    /;

    my @params = ($args{currency});
    push @params, $args{option} if $args{option} && $args{option} ne 'all' && $args{option} ne 'itin';
    return fetch_all($sql, \@params, $c);
}

# -----------------------------
# Single itinerary by URL
# -----------------------------
sub itinerary {
    my $tour = shift or die('No tour name passed');

    my $sql = qq/
        SELECT f.fixeditin_id AS tourname,
               f.fixeditin_id,
               f.title, f.oneliner, f.introduction, itinerary,
               triphighlights, quotes, adv, f.regions_id, readytours,
               itindates, inclusions, prices, f.orderno, days, duration,
               inactivewef, f.meta_title, f.meta_descr, f.meta_keywords, f.url,
               (SELECT ec.cities_id
                FROM cities ec
                JOIN citydayfixeditin cde ON cde.cities_id = ec.cities_id
                WHERE cde.fixeditin_id = f.fixeditin_id
                ORDER BY dayno DESC LIMIT 1) AS endcity,
               (SELECT sc.cities_id
                FROM cities sc
                JOIN citydayfixeditin cds ON cds.cities_id = sc.cities_id
                WHERE cds.fixeditin_id = f.fixeditin_id AND dayno = 1) AS startcity
        FROM fixeditin f
        WHERE f.url = ?
    /;

    return fetch_row($sql, [$tour], $c, 'NAME_lc');
}

# -----------------------------
# Itinerary cost
# -----------------------------
sub itinerary_cost {
    my ($fixeditin_id, $currencycode) = @_;
    $fixeditin_id  //= 0;
    $currencycode  //= 'USD';

    my $sql = qq/
        SELECT CAST(MIN(fc.cost) AS INT) AS cost,
               c.currencycode,
               c.symbol
        FROM fixeditincosts fc
        JOIN currencies c ON fc.currencies_id = c.currencies_id
        WHERE principalagents_id = 68
          AND frompax = 2
          AND topax = 2
          AND wet IS NULL
          AND fixeditin_id = ?
          AND c.currencycode LIKE ?
        GROUP BY c.currencycode, c.symbol
    /;

    return fetch_row($sql, [$fixeditin_id, $currencycode], $c, 'NAME_lc');
}

# -----------------------------
# Check itinerary existence
# -----------------------------
sub itinerary_exist {
    my $tour = shift;

    my $sql = "SELECT f.fixeditin_id FROM fixeditin f WHERE f.url = ?";
    my $row = fetch_row($sql, [$tour], $c, 'NAME_lc');
    return { exist => $row ? $row->{fixeditin_id} : 0 };
}

# -----------------------------
# Itinerary by ID
# -----------------------------
sub itinerary_id {
    my $id = shift // 0;

    my $sql = qq/
        SELECT title, oneliner, introduction, itinerary,
               triphighlights, quotes, adv, regions_id,
               readytours, url, itindates, inclusions, prices,
               orderno, days, duration,
               (SELECT CAST(MIN(c.cost) AS INT) FROM fixeditincosts c WHERE c.fixeditin_id = f.fixeditin_id) AS cost
        FROM fixeditin f
        WHERE fixeditin_id = ?
    /;

    return fetch_row($sql, [$id], $c, 'NAME_lc');
}

# -----------------------------
# Places you will visit
# -----------------------------
sub placesyouwillvisit {
    my $tour = shift;
    my $sql = qq/
        SELECT city, cities_id, oneliner, writeup, url, dayno, imagename, latitude, longitude
        FROM (
            SELECT c.city, c.cities_id, c.oneliner, c.writeup, c.url,
                   cdf.dayno, c.latitude, c.longitude
            FROM fixeditin f
            INNER JOIN CityDayFixedItin cdf ON f.fixeditin_id = cdf.fixeditin_id
            INNER JOIN cities c ON cdf.cities_id = c.cities_id
            WHERE f.url LIKE ?
            ORDER BY c.city
        ) a
        JOIN images i ON a.cities_id = i.ImageObjectId
        WHERE ImageCategories_id = 1 AND ImageTypes_id = 4 AND srno < 6
        ORDER BY dayno
    /;

    return fetch_all($sql, [$tour], $c);
}

# -----------------------------
# Similar tours
# -----------------------------
sub similartours {
    my ($city, $currency) = @_;
    $city     //= 0;
    $currency //= 'USD';

    my $sql = qq/
        SELECT f.fixeditin_id AS tourname, f.title, f.oneliner, f.introduction,
               itinerary, f.regions_id, readytours, f.startcities_id AS scity,
               prices, f.orderno, days AS numdays, f.url,
               (SELECT CAST(MIN(fc.cost) AS INT)
                FROM fixeditincosts fc
                JOIN currencies c ON fc.currencies_id = c.currencies_id
                WHERE fc.fixeditin_id = f.fixeditin_id
                  AND principalagents_id = 68
                  AND frompax = 2
                  AND topax = 2
                  AND c.currencycode LIKE ?) AS cost
        FROM fixeditin f
        LEFT JOIN regions r ON r.regions_id = f.regions_id
        WHERE (f.readytours = 1 OR r.url IS NOT NULL)
          AND inactivewef IS NULL
          AND f.startcities_id = ?
        ORDER BY RANDOM()
        LIMIT 3
    /;

    return fetch_all($sql, [$currency, $city], $c);
}

# -----------------------------
# Trip ideas
# -----------------------------
sub tripideas_trips {
    my ($tour, $currency, $exchrate, $order) = @_;
    $tour     = lc($tour);
    $currency //= 'USD';
    $order    //= 'popularity';

    my $order_by = 'f.orderno';
    $order_by = 'cost'    if $order eq 'price';
    $order_by = 'numdays' if $order eq 'days';
    $order_by .= ' DESC'  if $order =~ /desc/i;

    # prepare tour for LIKE
    $tour = "%$tour%";

    my $sql = <<'SQL';
SELECT f.fixeditin_id AS tourname,
       f.title,
       f.oneliner,
       f.introduction,
       CHAR_LENGTH(f.introduction) AS lengthintro,
       itinerary,
       triphighlights,
       quotes,
       adv,
       f.regions_id,
       readytours,
       itindates,
       inclusions,
       prices,
       f.orderno,
       days AS numdays,
       duration,
       inactivewef,
       f.meta_title,
       f.meta_descr,
       f.meta_keywords,
       f.url,
       f.startcities_id AS scity,
       (
           SELECT CAST(MIN(fc.cost / ?) AS INT)
           FROM fixeditincosts fc
           JOIN currencies c ON fc.currencies_id = c.currencies_id
           WHERE fc.fixeditin_id = f.fixeditin_id
             AND fc.principalagents_id = 68
             AND frompax = 2
             AND topax = 2
             AND c.currencycode = 'INR'
       ) AS cost,
       (SELECT city FROM cities s WHERE s.cities_id = f.startcities_id) AS startcity,
       (SELECT city FROM cities e WHERE e.cities_id = f.endcities_id) AS endcity
FROM fixeditin f
WHERE f.fixeditin_id IN (
    SELECT DISTINCT f.fixeditin_id
    FROM fixeditin f
    INNER JOIN FixedItinThemes fit ON fit.fixeditin_id = f.fixeditin_id
    INNER JOIN themes th ON fit.themes_id = th.themes_id
    INNER JOIN fixeditincosts fc ON fc.fixeditin_id = f.fixeditin_id
    WHERE f.inactivewef IS NULL
      AND fc.principalagents_id = 68
      AND th.url LIKE ?
)
SQL

    # append validated ORDER BY outside the heredoc
    $sql .= "\nORDER BY $order_by";

    return TravellersPalm::Database::Connector::fetch_all($sql, [$exchrate, $tour], $c);
}


# -----------------------------
# Total itineraries
# -----------------------------
sub totalitineraries {
    my $sql = qq/
        SELECT fixeditin_id
        FROM fixeditin f
        LEFT JOIN regions r ON r.regions_id = f.regions_id
        WHERE (f.readytours = 1 OR r.url IS NOT NULL)
          AND inactivewef IS NULL
        ORDER BY days
    /;

    my $rows = fetch_all($sql, [], $c);
    return scalar @$rows;
}

# -----------------------------
# Tours in a state
# -----------------------------
sub toursinstate {
    my %args = (
        currency => 'USD',
        order    => 'popularity',
        state    => '',
        @_,
    );

    my $order_by = 'f.orderno';
    $order_by = 'cost'    if $args{order} =~ /price/i;
    $order_by = 'numdays' if $args{order} =~ /days/i;
    $order_by = 'f.title' if $args{order} =~ /name/i;
    $order_by = 'f.url'   if $args{order} =~ /url/i;
    $order_by .= ' DESC' if $args{order} =~ /desc/i;

    my $sql = qq/
        SELECT f.fixeditin_id AS tourname, f.title, f.oneliner,
               SUBSTR(f.introduction,0,400) AS introduction, itinerary,
               triphighlights, quotes, adv, f.regions_id, readytours,
               itindates, inclusions, prices, f.orderno, days AS numdays,
               duration, f.inactivewef, f.meta_title, f.meta_descr, f.meta_keywords,
               f.url, f.startcities_id AS scity,
               (SELECT CAST(MIN(fc.cost) AS INT)
                FROM fixeditincosts fc
                JOIN currencies c ON fc.currencies_id = c.currencies_id
                WHERE fc.fixeditin_id = f.fixeditin_id
                  AND principalagents_id = 68
                  AND frompax = 2
                  AND topax = 2
                  AND wet IS NULL
                  AND c.currencycode LIKE ?) AS cost,
               s.city AS startcity,
               (SELECT city FROM cities e WHERE e.cities_id = f.endcities_id) AS endcity,
               s.latitude, s.longitude
        FROM fixeditin f
        INNER JOIN cities s ON s.cities_id = f.startcities_id
        WHERE f.fixeditin_id IN (
            SELECT DISTINCT f.fixeditin_id
            FROM fixeditin f
            INNER JOIN CityDayFixedItin cd ON cd.fixeditin_id = f.fixeditin_id
            INNER JOIN cities c ON cd.cities_id = c.cities_id
            INNER JOIN states st ON st.states_id = c.states_id
            INNER JOIN fixeditincosts fc ON fc.fixeditin_id = f.fixeditin_id
            WHERE fc.principalagents_id = 68
              AND f.inactivewef IS NULL
              AND st.url LIKE ?
        )
        ORDER BY $order_by
    /;

    return fetch_all($sql, [$args{currency}, $args{state}], $c);
}

# -----------------------------
# Your accommodation
# -----------------------------
sub youraccommodation {
    my $tour = shift;

    my $sql = qq/
        SELECT DISTINCT c.city, h.addressbook_id AS hotel_id, h.organisation AS hotel,
               SUBSTR(h.description,1,80) AS truncated_description,
               CASE a.categories_id
                   WHEN 23 THEN 10
                   WHEN 36 THEN 20
                   WHEN 8  THEN 30
               END AS category,
               CASE a.categories_id
                   WHEN 23 THEN '\$'
                   WHEN 36 THEN '\$\$'
                   WHEN 8  THEN '\$\$\$'
               END AS categoryname,
               c.oneliner, c.writeup
        FROM fixeditin f
        INNER JOIN CityDayFixedItin cdf ON f.fixeditin_id = cdf.fixeditin_id
        INNER JOIN vw_hoteldetails h ON h.cities_id = cdf.cities_id
        INNER JOIN cities c ON c.cities_id = h.cities_id
        LEFT JOIN addresscategories a ON a.addressbook_id = h.addressbook_id
        WHERE cdf.EndOfTour <> 1
          AND a.categories_id IN (23, 36, 8)
          AND a.ranking = 1
          AND f.url LIKE ?
        ORDER BY cdf.dayno, category ASC
    /;

    return fetch_all($sql, [$tour], $c);
}

1;
