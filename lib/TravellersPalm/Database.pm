package TravellersPalm::Database;

use 5.24.0;
use strict;
use warnings;

use Dancer2;
use Dancer2::Plugin::Database;
use Data::Dumper;

use Exporter qw{import};
our @EXPORT = qw{
    airports
    categories
    city
    cityhotels
    cityid
    citythemes
    countries_url
    currencies
    currency
    daybyday
    exchangerate
    exchange_rates
    exchange_rates_historical
    exchange_rates_update
    hotel
    imageproperties
    imageproperties_id
    image
    images
    imagesall
    images_delete
    images_update
    images_dropdown
    imgupload_type
    isquoted
    itincost
    itineraries
    itinerary
    itinerary_cost
    itinerary_exist
    itinerary_id
    metatags
    modules
    nearcities
    placesyouwillvisit
    randomcities
    regionnames
    regions
    regionsurl
    similartours
    state
    states
    statesurl
    statetours
    subthemes
    subthemes_id
    themes
    themes_subthemes
    themes_url
    themetrips
    themeurl
    totalcities
    totalitineraries
    totaltrains
    toursinstate
    tripideas_trips
    user_exist
    user_insert
    user_ok
    user_update
    webpages
    web
    youraccommodation
};

our $VERSION = '0.3';

# ------------- SUBROUTINES/METHODS ------------------



sub airports {

    my $country = shift;

    return 0 unless ($country);

    my $qry = "
            SELECT city, 
            RTRIM(citycode
            FROM cities c INNER JOIN countries co ON co.countries_id=c.countries_id
            WHERE airport = 1 AND  nighthalt = 1 AND  citycode IS NOT NULL AND co.url = '$country' 
            ORDER BY c.city;";

            return database('sqlserver')->selectall_arrayref( $qry, { Slice => {} } );
}

sub categories {

    my $qry = q/
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

            return database('sqlserver')->selectall_arrayref( $qry, { Slice => {} } );
}

sub city {

    my $cities_id = shift // 0;

    my $qry = "
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
            WHERE cities_id = ? ";

            my $sth = database('sqlserver')->prepare($qry);
            $sth->execute($cities_id);
            my $row = $sth->fetchrow_hashref('NAME_lc');
            $sth->finish;

            return $row;
}

sub cityhotels {

    # given hotel preference, returns default
    # hotel *and* all hotels in a city

    my $cityid = shift;
    my $qry    = q/
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
            #
            my $sth = database('sqlserver')->prepare($qry);
            $sth->execute($cityid);
            my $hotels = $sth->fetchall_arrayref( {} );
            $sth->finish;

            return $hotels;
}

sub cityid {

    my $city = shift;

        my $sth = database('sqlserver')->prepare(q/SELECT cities_id FROM cities WHERE city = ?/);
        $sth->execute($city);
        my $row = $sth->fetchrow_arrayref;
        $sth->finish;

        return $row ? $row->[0] : undef;
}

sub citythemes {

    my $subthemes_id = shift;

    # subtheme: themes_id, title, oneliner, introduction, subtheme, url
    # for google map on theme page
    my $qry = "
        SELECT  s.cities_id     as id, 
                c.city          as name, 
                c.latitude      as lat, 
                c.longitude     as lng, 
                c.writeup       as descr
        FROM    citythemes s JOIN cities c ON c.cities_id=s.cities_id
        WHERE   s.subthemes_id = $subthemes_id";

        return database('sqlserver')->selectall_arrayref( $qry, { Slice => {} } );
}

sub countries_url {

    my ( $column, $country ) = @_;
    
    my $qry = qq/
        SELECT  countries_id, 
                country, 
                isd, 
                gmt, 
                countrycode, 
                writeup, 
                currencies_id 
        FROM    countries 
        WHERE   $column = ?/;

        my $sth = database('sqlserver')->prepare($qry);
        $sth->execute($country);
        my $row = $sth->fetchrow_hashref('NAME_lc');
        $sth->finish;

        return $row;
}

sub currencies {

    my $currencycode = shift // '';
       $currencycode = uc $currencycode ;
    my $option       = (length $currencycode > 0 ) ? " AND currencycode like '$currencycode' " : '';

    my $qry = qq/
        SELECT currencycode, currency, symbol, c.currencies_id, wef 
        FROM 
        (
            SELECT   currencies_id, max(wef) wef
            FROM     currencydetails
            GROUP BY currencies_id
        ) temp  
        JOIN currencies c ON c.currencies_id = temp.currencies_id 
        WHERE c.hdfccode IS NOT NULL $option 
        ORDER BY currencycode;/;

        return database('sqlserver')->selectall_arrayref( $qry, { Slice => {} } );
}

sub currency {
    my $newcurrency = shift ;
    my $currency    = 'USD';

    if ( defined $newcurrency ) {
        my $exist = currencies($newcurrency);
        if (scalar $exist) {
            $currency = $newcurrency;
        }
    }
    return $currency;
}

sub daybyday {

    my $tour = shift;
    my $qry  = "
        SELECT  
        c.dayno         as dayno, 
        c.dayitinerary  as dayitinerary, 
        c.cities_id     as cities_id, 
        c.endoftour     as endoftour,
        (select city from cities s where s.cities_id=c.cities_id) as city
        FROM    fixeditin f INNER JOIN CityDayFixedItin c on f.FixedItin_id = c.FixedItin_id
        WHERE   f.url like '$tour' ORDER BY c.dayno";

        return database('sqlserver')->selectall_arrayref( $qry, { Slice => {} } );
}

sub exchangerate {

    my $currencycode = shift;

    return 0 unless $currencycode;

    my $qry = "
        SELECT  exchangerate 
        FROM    currencydetails d
                RIGHT JOIN currencies c ON c.currencies_id = d.currencies_id
        WHERE   currencycode = '$currencycode'
        ORDER   BY wef DESC
                LIMIT 1;";

        my $data = database('sqlserver')->selectrow_array( $qry, { Slice => {} } );
        return $data;
}

sub exchange_rates {

    my $qry = "
        SELECT  currency, exchange_rate, strftime('%d/%m/%Y',datetime(date, 'unixepoch')) as date
        FROM    exchange_rates
        WHERE   strftime('%d/%m/%Y',datetime(date, 'unixepoch')) = strftime('%d/%m/%Y','now')
        ORDER BY currency DESC;";

    return database('sqlite')->selectall_arrayref( $qry, { Slice => {} } ); 
}

sub exchange_rates_historical {

    my $qry = "
        SELECT  currency, strftime('%d/%m/%Y',datetime(date, 'unixepoch')) as date, exchange_rate 
        FROM    exchange_rates
        WHERE   currency = ?
        ORDER   BY date DESC";

    my $data;
    $data->{AUD} = database('sqlite')->selectall_arrayref( $qry, { Slice => {} } ,'AUD');
    $data->{EUR} = database('sqlite')->selectall_arrayref( $qry, { Slice => {} } ,'EUR');
    $data->{GBP} = database('sqlite')->selectall_arrayref( $qry, { Slice => {} } ,'GBP');
    $data->{USD} = database('sqlite')->selectall_arrayref( $qry, { Slice => {} } ,'USD');
    
    return $data;
}

sub exchange_rates_update {

    my $rates = shift;

    # create table exchange_rates (exchange_rates_id integer primary key, currency text NOT NULL, date text NOT NULL, exchange_rate text NOT NULL);

    my $qry = qq(INSERT INTO exchange_rates (currency,date,exchange_rate) VALUES (?,(strftime('%s','now')),?);); 

    my $sth = database('sqlite')->prepare($qry);
    $sth->execute( 'AUD',$rates->{AUD} );
    $sth->execute( 'EUR',$rates->{EUR} );
    $sth->execute( 'GBP',$rates->{GBP} );
    $sth->execute( 'USD',$rates->{USD} );
    $sth->finish;

    return exchange_rates();
}


sub hotel {

    my $hotel_id = shift // 0;
    my $qry      = q/
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

            my $sth = database('sqlserver')->prepare($qry);
            $sth->execute($hotel_id);
            my $row = $sth->fetchrow_hashref('NAME_lc');
            $sth->finish;

            return $row;
}

sub imageproperties {
    my ( $imgcat, $imgtype ) = @_;

    if ( defined($imgcat) and defined($imgtype) ) {

        my $qry = '
                SELECT  imageproperties_id  as imagecategories_id,
                        imagetypes_id       as imagetypes_id, 
                        imagepattern        as imagepattern, 
                        imagewidth          as imagewidth, 
                        imageheight         as imageheight,
                        imagecategories_id  as imagecategories_id
                FROM    imageproperties 
                WHERE   imagecategories_id = ? AND 
                        imagetypes_id = ?';

                my $sth = database('sqlserver')->prepare($qry);
                $sth->execute( $imgcat, $imgtype );
                my $row = $sth->fetchrow_hashref('NAME_lc');
                $sth->finish;

                return $row;
    }
    return 0;
}

sub imageproperties_id {
    my $id = shift // 0;

    my $qry = '
            SELECT  imageproperties_id  as imagecategories_id,
                    imagetypes_id       as imagetypes_id, 
                    imagepattern        as imagepattern, 
                    imagewidth          as imagewidth, 
                    imageheight         as imageheight,
                    imagecategories_id  as imagecategories_id
            FROM    imageproperties 
            WHERE   imageproperties_id = ?';

    my $sth = database('sqlserver')->prepare($qry);
    $sth->execute( $id );
    my $row = $sth->fetchrow_hashref('NAME_lc');
    $sth->finish;

    return $row;
}

sub image {

    my $imagename = shift;

    my $qry = '
            SELECT  images_id,
                    imagename           as imagename, 
                    width               as width, 
                    height              as height,
                    category            as category,
                    title               as title,
                    alttag              as alttag,
                    srno                as srno,
                    imagecategories_id  as imagecategories_id,
                    filesize            as filesize,
                    type                as type,
                    imageobjectid       as imageobjectid,
                    imagetypes_id       as imagetypes_id
            FROM    images 
            WHERE   imagename like ?';

            my $sth = database('sqlserver')->prepare($qry);
            $sth->execute($imagename);
            my $row = $sth->fetchrow_hashref('NAME_lc');
            $sth->finish;

            return $row;
    return 0;
}


sub images {

    my $id       = shift // 0;
    my $category = shift // 0;
    my $type     = shift // 0;

    my $row;

    $category = 1 if ( lc($category) eq q/city/ );
    $category = 2 if ( lc($category) eq q/hotel/ );
    $category = 3 if ( lc($category) eq q/module/ );
    $category = 4 if ( lc($category) eq q/ready tour/ );
    $category = 5 if ( lc($category) eq q/state/ );
    $type     = 2 if ( lc($type)     eq q/collage/ );
    $type     = 3 if ( lc($type)     eq q/defaulthotel/ );
    $type     = 4 if ( lc($type)     eq q/large/ );
    $type     = 5 if ( lc($type)     eq q/main/ );
    $type     = 6 if ( lc($type)     eq q/small/ );

    eval {
        my $qry = qq/ 
             SELECT  width                as width,
                     height               as height,
                     title                as title,
                     alttag               as alttag,
                     filesize             as filesize,
                     imagename            as imagename,
                     imageobjectid        as imageobjectid,
                     imagecategories_id   as imagecategories_id,
                     imagetypes_id        as imagetypes_id 
             FROM    images 
             WHERE   imageobjectid = ? AND 
                     imagecategories_id = ? AND 
                     imagetypes_id = ? 
             ORDER   BY imagename
             LIMIT   10 ; /;

             my $sth = database('sqlserver')->prepare($qry);
             $sth->execute( $id, $category, $type );
             $row = $sth->fetchall_arrayref( {} );
             $sth->finish;
    };

    print "An error occurred: $@\n" if $@;
    return $row;
}


sub imagesall {

    my $id  = shift // 0;
    my $qry = qq/
            SELECT  imagename       as imagename, 
                    ImageName2      as imagename2
            FROM    images 
            WHERE   ImageCategories_id = $id 
            ORDER   BY imagename/;

            return database('sqlserver')->selectall_arrayref( $qry, { Slice => {} } );
}

sub images_delete {

    my $imagename = shift // 0 ;
    my $qry       = qq/DELETE FROM images WHERE imagename like '$imagename'/ ;
    my $sth       = database('sqlserver')->prepare($qry);
    my $ok        = $sth->execute();
    $sth->finish;
    return;
}

sub images_dropdown 
{
    # used by upload.travellers-palm.com
    # , imagetype, t.imagetypes_id,ImagePattern,imagewidth,imageheight
    my $qry = " SELECT  imagefolder, 
                        (SELECT imagetype FROM imagetypes WHERE imagetypes_id =p.imagetypes_id) as imagetype, 
                        ImageCategories_Id, 
                        ImagePattern,
                        ImageWidth,
                        ImageHeight,
                        ImageProperties_id
                FROM    ImageProperties p 
                ORDER BY imagefolder;";

    my $data = database('sqlserver')->selectall_arrayref( $qry, { Slice => {} } );
    return $data;
}

sub images_update {

    my %args = (
        alttag              => '',
        filesize            => 0,
        height              => 0,
        imagecategories_id  => 0,
        imagename           => '',
        imageobjectid       => 0,
        images_id           => 0,
        imagetypes_id       => 0,
        srno                => 0,
        title               => '',
        tineye              => 0,
        width               => 0,
        @_ ,
        );


    my $onfile = image( lc $args{imagename} );

    if ( ref $onfile eq ref {} ) {

        my $qry = qq(UPDATE images SET imagefolder = ? );
        my @val = () ; 
        push(@val,q/NULL/);

        if (length $args{imagename}    > 0 )   { $qry .= qq( ,imagename           = ? );  push(@val, lc qq($args{imagename})    );} 
        if ($args{imagecategories_id}  > 0 )   { $qry .= qq( ,imagecategories_id  = ? );  push(@val, $args{imagecategories_id}  );}
        if ($args{imagetypes_id}       > 0 )   { $qry .= qq( ,imagetypes_id       = ? );  push(@val, $args{imagetypes_id}       );}
        if ($args{width}               > 0 )   { $qry .= qq( ,width               = ? );  push(@val, $args{width}               );}
        if ($args{height}              > 0 )   { $qry .= qq( ,height              = ? );  push(@val, $args{height}              );}
        if ($args{filesize}            > 0 )   { $qry .= qq( ,filesize            = ? );  push(@val, $args{filesize}            );}
        if (length($args{alttag})      > 0 )   { $qry .= qq( ,alttag              = ? );  push(@val, qq($args{alttag})          );}
        if (length($args{title})       > 0 )   { $qry .= qq( ,title               = ? );  push(@val, qq($args{title})           );} 
        if ($args{srno}                > 0 )   { $qry .= qq( ,srno                = ? );  push(@val, $args{srno}                );}
        if ($args{imageobjectid}       > 0 )   { $qry .= qq( ,imageobjectid       = ? );  push(@val, $args{imageobjectid}       );} 
        if ($args{tineye}             != 0 )   { $qry .= qq( ,tineye              = ? );  push(@val, ($args{tineye} < 0) ? 0: $args{tineye} );} 
        
        if (($args{imagecategories_id} == 1) && length($args{title}) == 0 )  
        { $qry .= qq( ,title  = ? );  push(@val, qq($args{alttag}) );}

        $qry .= qq( WHERE images_id = ?) ;
        push(@val, $onfile->{images_id});

        my $sth = database('sqlserver')->prepare($qry);
        $sth->execute( @val );
        $sth->finish;
        return {
            status  => 1,
            message => lc $args{imagename} . q( updated),
        };
    }
    else {
        # insert
        if (length $args{imagename} > 0) {

            my $qry  = q/imagename/;
            my @val  = (lc qq($args{imagename}) );
            my $plh  = qq(?);
=head
            my @columns = split ( /\s+/, 'imagecategories_id imagetypes_id width height filesize alttag title srno imageobjectid tineye');
            while $column in @columns{
                if( $column eq 'alttag'|| $column eq 'title'){
                    if (length $args{alttag} > 0) 
                        $qry .= qq(,$column);
                        $plh .= q(,?); 
                        push(@val,qq('$args{$column}'));
                    }
                }
                elsif ($args{$column} > 0)   {
                    $qry .= qq(,$column);
                    $plh .= q(,?); 
                    push(@val,$args{$column});
                }; 
            };
=cut
            if ($args{imagecategories_id}   > 0)   {  $qry .= q(,imagecategories_id)    ;  $plh .= q(,?); push(@val,$args{imagecategories_id});    }; 
            if ($args{imagetypes_id}        > 0)   {  $qry .= q(,imagetypes_id)         ;  $plh .= q(,?); push(@val,$args{imagetypes_id});         };
            if ($args{width}                > 0)   {  $qry .= q(,width)                 ;  $plh .= q(,?); push(@val,$args{width});                 };
            if ($args{height}               > 0)   {  $qry .= q(,height)                ;  $plh .= q(,?); push(@val,$args{height});                };
            if ($args{filesize}             > 0)   {  $qry .= q(,filesize)              ;  $plh .= q(,?); push(@val,$args{filesize});              };
            if (length $args{alttag}        > 0)   {  $qry .= q(,alttag)                ;  $plh .= q(,?); push(@val,qq($args{alttag}));            };
            if (length $args{title}         > 0)   {  $qry .= q(,title)                 ;  $plh .= q(,?); push(@val,qq($args{title}));             };
            if ($args{srno}                 > 0)   {  $qry .= q(,srno)                  ;  $plh .= q(,?); push(@val,$args{srno});                  };
            if ($args{imageobjectid}        > 0)   {  $qry .= q(,imageobjectid)         ;  $plh .= q(,?); push(@val,$args{imageobjectid});         };
            if ($args{tineye}              != 0)   {  $qry .= q(,tineye)                ;  $plh .= q(,?); push(@val,($args{tineye} < 0 ) ? 0 : $args{tineye}); };

            $qry = qq(INSERT INTO images ($qry) VALUES ($plh);); 

            my $sth = database('sqlserver')->prepare($qry);
            $sth->execute( @val );
            $sth->finish;
            return {
                status  => 1,
                message => lc $args{imagename} . q( inserted),
            };
        }
        return {
            status  => 0,
            message => 'Request to insert failed: no image name passed',
        };
    }
}


sub imgupload_type {
    my $imgcat = shift // 0;
    my $option = shift // 0;
    
    my $qry = "SELECT t.imagetypes_id,t.imagetype FROM imagetypes t";

    if ($imgcat > 0) {
        $qry .= ' INNER JOIN imageproperties p on t.imagetypes_id=p.imagetypes_id 
        WHERE p.imagecategories_id = ' . $imgcat;
    }

    my $sth = database('sqlserver')->prepare($qry);
    $sth->execute();

    my @results = ();
    while ( my $row = $sth->fetchrow_hashref ) {
        push @results, $row;
    }
    $sth->finish();

    return @results;
}

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

sub metatags {

    my $url = shift // 'index';

    my $data;
    $data->{meta_descr} = '';
    $data->{meta_title}       = '';
    $data->{meta_keywords}    = '';

    my $qry = " 
        SELECT  meta_title      as meta_title, 
                meta_descr      as meta_descr, 
                meta_keywords   as meta_keywords
        FROM    webpages 
        WHERE   url = ?";

            my $sth = database('sqlserver')->prepare($qry);
            $sth->execute($url);
            my ($row) = $sth->fetchrow_hashref('NAME_lc');
            $sth->finish;

            if ( ref($row) eq "HASH" ) {
                $data = $row;
            }
            return $data;
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

    my $qry = "
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

        return database('sqlserver')->selectall_arrayref( $qry, { Slice => {} } );
}

sub nearcities {

    my $cityid  = shift;
    my $qry     = "
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
                    nearcities.maincities_id = ?";

            my $sth = database('sqlserver')->prepare($qry);
            $sth->execute($cityid);
            my $nearcities = $sth->fetchall_arrayref( {} );
            $sth->finish;

            return $nearcities;
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

sub randomcities {

    my $qry = "
        SELECT  DISTINCT cities.cities_id   as cities_id, 
                cities.city                 as city
        FROM    cities, defaulthotels
        WHERE   cities.nighthalt = 1 and
                cities.display = 1 and
                cities.countries_id = 200 and
                defaulthotels.cities_id = cities.cities_id
        ORDER   BY 2";

        my $sth = database('sqlserver')->prepare($qry);
        $sth->execute;
        my $rndcities = $sth->fetchall_arrayref( {} );
        $sth->finish;

        return $rndcities;
    
    my $key = "randomcities" . ':' . join( ':', @_ );

    my $cityid = $_[0];
    my %seen = map { $_ => 1 } @_;
    foreach ( @{ nearcities($cityid) } ) {
        $seen{ $_->{cities_id} } = 1;
    }

    my @rndcities = grep { !exists $seen{ $_->{cities_id} } } @$rndcities;

    return \@rndcities;
    
}

sub regionnames {

    my $qry = "
        SELECT  title as title
        FROM    regions 
        ORDER   BY orderno";

        return database('sqlserver')->selectall_arrayref( $qry, { Slice => {} } );
}

sub regions {

    my $order = shift // 'orderno';

    $order = 'title' if ( $order =~ m/name/i );
    $order = 'url'   if ( $order =~ m/url/i );

    my $qry = " 
        SELECT  regions_id      as regions_id,
                title           as title,
                oneliner        as oneliner,
                introduction    as introduction,
                region          as region,
                url             as url
        FROM    regions 
        ORDER   BY $order";

        return database('sqlserver')->selectall_arrayref( $qry, { Slice => {} } );
}

sub regionsurl {

    my $url = shift;
    my $qry = " 
        SELECT  regions_id      as regions_id,
                title           as title,
                oneliner        as oneliner,
                introduction    as introduction,
                region          as region,
                url             as url
        FROM    regions 
        WHERE   url = ?";

            my $sth = database('sqlserver')->prepare($qry);
            $sth->execute($url);
            my $row = $sth->fetchrow_hashref('NAME_lc');
            $sth->finish;

            return $row;
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

sub state {

    my $states_id = shift // 0;
    my $qry       = "
            SELECT  states_id,
                    statecode,
                    state,
                    countries_id,
                    printstate,
                    oneliner,
                    writeup,
                    webwriteup      as webwriteup,
                    latitude        as latitude,
                    longitude       as longitude,
                    meta_title      as meta_title, 
                    meta_descr      as meta_descr, 
                    meta_keywords   as meta_keywords, 
                    url 
            FROM    states 
            WHERE   states_id = ?";

            my $sth = database('sqlserver')->prepare($qry);
            $sth->execute($states_id);
            my $row = $sth->fetchrow_hashref('NAME_lc');
            $sth->finish;

            return $row;
}

sub states {

    my $country = shift;
    my $order = shift // 'state';

    $order = 'states.url' if ( $order =~ m/url/i );
    $order = 'state'      if ( $order =~ m/name/i );

    my $category_hotel = 27;
    my $qry = "
            SELECT  states_id, 
                    statecode, 
                    state, 
                    states.countries_id, 
                    printstate, 
                    oneliner, 
                    states.writeup, 
                    webwriteup      as webwriteup,
                    latitude        as latitude,
                    longitude       as longitude,
                    meta_title      as meta_title, 
                    meta_descr      as meta_descr, 
                    meta_keywords   as meta_keywords, 
                    states.url
            FROM    states INNER JOIN countries c on c.countries_id=states.countries_id 
            WHERE   states_id IN 
                    (
                    SELECT  DISTINCT states.states_id 
                    FROM    vw_hoteldetails, addresscategories, states
                    WHERE   addresscategories.categories_id = $category_hotel AND 
                    addresscategories.addressbook_id = vw_hoteldetails.addressbook_id AND 
                    vw_hoteldetails.states_id = states.states_id
                    ) AND
                    (c.url like '" . $country . "%') 
            ORDER   BY  ". $order;

        return database('sqlserver')->selectall_arrayref( $qry, { Slice => {} } );
}

sub statesurl {

    my $url = shift;
    my $qry = " 
            SELECT  states_id, 
                    statecode, 
                    state, 
                    countries_id, 
                    oneliner, 
                    writeup, 
                    webwriteup      as webwriteup,
                    latitude        as latitude,
                    longitude       as longitude,
                    meta_title      as meta_title, 
                    meta_descr      as meta_descr, 
                    meta_keywords   as meta_keywords, 
                    url
            FROM    states 
            WHERE   url like ?";

            my $sth = database('sqlserver')->prepare($qry);
               $sth->execute($url);
            my $row = $sth->fetchrow_hashref('NAME_lc');
            $sth->finish;
            return $row;
}

sub subthemes {

    my $themes_id = shift;
    my $qry       = "
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

            return database('sqlserver')->selectall_arrayref( $qry, { Slice => {} } );
}

sub subthemes_id {

    my $subthemes_id = shift;
    my $qry          = "
            SELECT  subthemes_id    as subthemes_id, 
                    themes_id       as themes_id, 
                    title           as title, 
                    oneliner        as oneliner, 
                    introduction    as introduction, 
                    subtheme        as subtheme, 
            FROM    subthemes 
            WHERE   subthemes_id = ?";

            my $sth = database('sqlserver')->prepare($qry);
            $sth->execute($subthemes_id);
            my $row = $sth->fetchrow_hashref('NAME_lc');
            $sth->finish;
            return $row;
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

    my $qry =  "
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

    my $test = database('sqlserver')->selectall_arrayref( $qry, { Slice => {} } );

    return $test;
}


sub themes_subthemes {

    my $themes_id = shift;

    # for google map on theme page
    my $qry = "
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

        return database('sqlserver')->selectall_arrayref( $qry, { Slice => {} } );
}

sub themes_url {

    my $theme = shift;
    my $qry   = "
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

            my $sth = database('sqlserver')->prepare($qry);
            $sth->execute($theme);
            my $row = $sth->fetchrow_hashref('NAME_lc');
            $sth->finish;

        return $row;
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

    my $qry = "
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
                            c.currencycode  like '".$currency."'
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
                                    th.Themes_id = ".$tour."
                            ) 
            ORDER BY ".$order_by ;

    return database('sqlserver')->selectall_arrayref( $qry, { Slice => {} } );
}

sub themeurl {

    my $url = shift;
    my $key = "themes:$url";
    my $qry = "
        SELECT  title           as title,
                introduction    as introduction,
                url,
                meta_title      as meta_title, 
                meta_descr      as meta_descr, 
                meta_keywords   as meta_keywords, 
                themes_id       as themes_id 
        FROM    themes 
        where   url like ?";

            my $sth = database('sqlserver')->prepare($qry);
            $sth->execute($url);
            my $row = $sth->fetchrow_hashref('NAME_lc');
            $sth->finish;

            return $row;
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

sub totalcities {

    my $qry = "
            SELECT  DISTINCT cities.cities_id  as cities
            FROM    cities, 
                    defaulthotels
            WHERE   cities.nighthalt = 1 and
                    cities.display = 1 and
                    cities.countries_id = 200 and
                    defaulthotels.cities_id = cities.cities_id";

            my $sth = database('sqlserver')->prepare($qry);
            $sth->execute();
            my $rows = $sth->fetchall_arrayref( {} );
            $sth->finish;

            return ( 0 + @{$rows} );
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

sub totaltrains {

    my $qry = "
        SELECT  startname as startname 
        from    zz_trains";

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

=cut
sub user_exist {


    my $user = shift;

    my $qry = "
            SELECT  rowid,
                    username 
            FROM    users 
            WHERE   username LIKE ? ";

            my $sth = database('sqlserver')->prepare($qry);
            $sth->execute($user);
            my $rows = $sth->rows;
            $sth->finish;

            return $rows;
}
=cut

sub user_insert {

    use DateTime;

    my $emailid = shift;

    my $qry = "INSERT INTO users ( username, active, registeredon ) VALUES ( ?, ?, ? )";
    my $sth = database('sqlserver')->prepare($qry);

    my $now = DateTime->now->datetime;
    $now =~ y/T/ /;

    print STDERR Dumper( [ $emailid, 1, $now, ] );

    $sth->execute( $emailid, 1, $now, );

    return;
}

sub user_ok {

    my $username = shift;
    my $password = shift;

    my $qry = "
            SELECT  rowid as rowid 
            FROM    users 
            WHERE   username LIKE ? AND 
                    password LIKE ?";

            my $sth = database('sqlserver')->prepare($qry);
            $sth->execute( $username, $password );
            my $row = $sth->fetchrow_hashref('NAME_lc');
            $sth->finish;

            return $row ? $row : 0;
}

sub user_update {

    my ( $userid, $md5passwd ) = @_;

    my $qry = "UPDATE users SET password = ? WHERE rowid = ?";

    my $sth = database('sqlserver')->prepare($qry);
    $sth->execute( $md5passwd, $userid );
    $sth->finish;

    return 1;
}

sub webpages {

    my $id = shift;
    my $qry = " 
        SELECT  pagename        as pagename, 
                url, 
                meta_title      as meta_title, 
                meta_descr      as meta_descr, 
                meta_keywords   as meta_keywords
        FROM    webpages 
        WHERE   webpages_id = ?";

            my $sth = database('sqlserver')->prepare($qry);
            $sth->execute($id);
            my ($data) = $sth->fetchrow_hashref('NAME_lc');
            $sth->finish;
            return $data;
}

sub web {

    my $id  = shift // 0;
    my $qry = " 
            SELECT  srno        as srno, 
                    title       as title, 
                    pagename    as pagename, 
                    writeup     as writeup, 
                    webpages_id as webpages_id 
            FROM    Web 
            WHERE   Web_id = ?";

            my $sth = database('sqlserver')->prepare($qry);
            $sth->execute($id);
            my ($text) = $sth->fetchrow_hashref('NAME_lc');

            $sth->finish;

            my $data;
            $data->{rows} = defined (scalar $text) ? (scalar $text) : 0 ;
            $data->{data} = $text;

            return $data;
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