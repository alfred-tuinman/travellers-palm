package TravellersPalm::Database::Themes;

use strict;
use warnings;

use Exporter 'import';
use TravellersPalm::Database::Connector qw(fetch_all fetch_row);

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
    my $sql = q{
        SELECT  subthemes_id,
                themes_id,
                title,
                oneliner,
                introduction,
                subtheme,
                url
        FROM    subthemes
        WHERE   themes_id = ?
        ORDER BY title
    };
    return TravellersPalm::Database::Connector::fetch_all($sql, [$themes_id]);
}

sub subthemes_id {
    my $subthemes_id = shift;
    my $sql = q{
        SELECT  subthemes_id,
                themes_id,
                title,
                oneliner,
                introduction,
                subtheme,
                url
        FROM    subthemes
        WHERE   subthemes_id = ?
    };
    return TravellersPalm::Database::Connector::fetch_row($sql, [$subthemes_id], '', 'NAME_lc');
}

sub themes {
    my ($parameter, $order) = @_;
    $order //= 'title';

    my $condition = '';
    if (defined $parameter) {
        $condition = (uc($parameter) eq 'LIMIT')
            ? 'WHERE themes_id < 7'
            : 'WHERE themes_id > 6';
    }

    my $order_by = ($order =~ /url/i) ? 'url' : 'pagename';

    my $sql = qq{
        SELECT  pagename,
                introduction,
                url,
                oneliner,
                meta_title,
                meta_descr,
                meta_keywords,
                themes_id
        FROM    themes
        $condition
        ORDER BY $order_by
    };

    return TravellersPalm::Database::Connector::fetch_all($sql);
}

sub themes_subthemes {
    my $themes_id = shift;
    my $sql = q{
        SELECT  s.cities_id AS id,
                c.city      AS name,
                c.latitude  AS lat,
                c.longitude AS lng,
                c.writeup   AS descr,
                s.subthemes_id
        FROM    citythemes s
        JOIN    cities c ON c.cities_id = s.cities_id
        JOIN    themes t ON t.themes_id = s.themes_id
        WHERE   t.themes_id = ?
          AND   c.latitude IS NOT NULL
        ORDER BY s.subthemes_id
    };
    return TravellersPalm::Database::Connector::fetch_all($sql, [$themes_id]);
}

sub themes_url {
    my $theme = shift;
    my $sql = q{
        SELECT  pagename,
                introduction,
                url,
                oneliner,
                meta_title,
                meta_descr,
                meta_keywords,
                themes_id
        FROM    themes
        WHERE   url LIKE ?
    };
    return TravellersPalm::Database::Connector::fetch_row($sql, [$theme], '', 'NAME_lc');
}

sub themetrips {
    my ($tour, $currency, $order) = @_;
    $currency //= 'USD';
    $order    //= 'popularity';

    my %theme_map = (
        wildlife  => 1,
        landscape => 2,
        adventure => 3,
        beaches   => 4,
        religion  => 5,
        monuments => 6,
    );
    $tour = $theme_map{ lc($tour) } // $tour;

    my $order_by = 'f.orderno';
    $order_by = 'cost'    if $order =~ /price/i;
    $order_by = 'numdays' if $order =~ /days/i;
    $order_by = 'f.title' if $order =~ /name/i;
    $order_by = 'f.url'   if $order =~ /url/i;
    $order_by .= ' DESC'  if $order =~ /desc/i;

    my $sql = qq{
        SELECT  f.fixeditin_id  AS tourname,
                f.title,
                f.oneliner,
                f.introduction,
                LENGTH(f.introduction) AS lengthintro,
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
                    SELECT CAST(MIN(fc.cost) AS INT)
                    FROM   fixeditincosts fc
                    JOIN   currencies c ON fc.currencies_id = c.currencies_id
                    WHERE  fc.fixeditin_id = f.fixeditin_id
                      AND  principalagents_id = 68
                      AND  frompax = 2
                      AND  topax = 2
                      AND  wet IS NULL
                      AND  c.currencycode LIKE ?
                ) AS cost,
                (SELECT city FROM cities s WHERE s.cities_id = f.startcities_id) AS startcity,
                (SELECT city FROM cities e WHERE e.cities_id = f.endcities_id) AS endcity
        FROM    fixeditin f
        WHERE   f.fixeditin_id IN (
                    SELECT DISTINCT f.fixeditin_id
                    FROM   fixeditin f
                    JOIN   FixedItinThemes fit ON fit.fixeditin_id = f.fixeditin_id
                    JOIN   themes th ON fit.themes_id = th.themes_id
                    JOIN   fixeditincosts fc ON fc.fixeditin_id = f.fixeditin_id
                    WHERE  inactivewef IS NULL
                      AND  fc.principalagents_id = 68
                      AND  th.themes_id = ?
                )
        ORDER BY $order_by
    };

    return TravellersPalm::Database::Connector::fetch_all($sql, [$currency, $tour]);
}

sub themeurl {
    my $url = shift;
    my $sql = q{
        SELECT  title,
                introduction,
                url,
                meta_title,
                meta_descr,
                meta_keywords,
                themes_id
        FROM    themes
        WHERE   url LIKE ?
    };
    return TravellersPalm::Database::Connector::fetch_row($sql, [$url], '', 'NAME_lc');
}

1;
