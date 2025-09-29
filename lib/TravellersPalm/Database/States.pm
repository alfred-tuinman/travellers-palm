package TravellersPalm::Database::States;

use strict;
use warnings;
use Dancer2 appname => 'TravellersPalm';
use TravellersPalm::Database::Connector qw();
use Exporter 'import';

our @EXPORT_OK = qw( 
    state
    states
    statesurl
    );


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

1;