package TravellersPalm::Database::States;

use strict;
use warnings;

use Exporter 'import';
use TravellersPalm::Database::Connector qw();

our @EXPORT_OK = qw( 
    state
    states
    statesurl
    );


sub state {

    my $states_id = shift // 0;
    my $sql       = "
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

    return TravellersPalm::Database::Connector::fetch_row( $sql, [$states_id],,'NAME_lc');
 }

sub states {

    my $country = shift;
    my $order = shift // 'state';

    $order = 'states.url' if ( $order =~ m/url/i );
    $order = 'state'      if ( $order =~ m/name/i );

    my $category_hotel = 27;
    my $sql = "
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
                    WHERE   addresscategories.categories_id = ? AND 
                    addresscategories.addressbook_id = vw_hoteldetails.addressbook_id AND 
                    vw_hoteldetails.states_id = states.states_id
                    ) AND
                    (c.url like ?%) 
            ORDER   BY  ". $order;

    return TravellersPalm::Database::Connector::fetch_all( $sql, [$category_hotel,$country]);
}

sub statesurl {

    my $url = shift;
    my $sql = " 
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

    return TravellersPalm::Database::Connector::fetch_row( $sql, [$url],,'NAME_lc');
}

1;