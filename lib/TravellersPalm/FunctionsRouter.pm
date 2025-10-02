package TravellersPalm::FunctionsRouter;

use strict;
use warnings FATAL => 'all';

use Dancer2;

use Exporter qw{ import };
use POSIX qw( strftime );

use TravellersPalm::Constants qw(
  $TAILOR 
  $THEMES 
  $STATES 
  $REGIONS 
  $IDEAS 
  $session_country 
  $session_currency);

our @EXPORT = qw{ route_listing route_itinerary };


sub route_listing {
    my $destination = shift;
    my $option      = shift;    # TAILOR THEMES STATES REGIONS or IDEAS
    my $view        = shift;    # list, block or grid
    my $order       = shift;    # days, price, popularity
    my $region      = shift;    # region or state


    my $crumb = "<li>Destinations</li>
                 <li><a href=".request->uri_base."/destinations/$destination>" . url2text($destination) . "</a></li>";

    my $itineraries;
    my $states;
    my $state;
    my $stateinfo;
    my $state_writeup;
    my $regioninfo;
    my $places;
    my $filter;
    my $regions;

    if ( $option eq $TAILOR ) {
        $itineraries = itineraries( option => 'itin', currency => $session_currency, order => $order );
        $filter      = 'tailor';

        $crumb .= "<li class='active'>" . url2text($TAILOR) . "</li>";
    }
    elsif ( $option eq $REGIONS ) {

        $itineraries = modules( region => $region, currency => $session_currency, order => $order );
        $regioninfo  = regionsurl( $region );
        $regions     = regions();
        $filter      = 'regions';     

        my $metatags;
        $metatags->{meta_descr}     = $regioninfo->{introduction};
        $metatags->{meta_keywords}  = $regioninfo->{meta_keywords};
        $metatags->{meta_title}     = $regioninfo->{oneliner};

        $crumb .=  "<li><a href='".request->uri_base."/destinations/$destination/$REGIONS'>". url2text($REGIONS) . "</a></li>
                    <li class='active'>" . $regioninfo->{title} . "</li>";
    }
    elsif ( $option eq $STATES ) {

        $state       = $region;
        $stateinfo   = statesurl($state);
        $itineraries = toursinstate( state => $state, currency=> $session_currency, order=> $order );
        $states      = states($destination);
        $filter      = 'states';
        $crumb      .= "<li><a href='".request->uri_base."/destinations/$destination/$STATES'>" . url2text($STATES) . "</a></li>
                        <li class='active'>" . url2text($state) . "</li>";

        ( $state_writeup, $places ) = linkify( addptags( $stateinfo->{webwriteup} ) );
    }

    # set data for sliders
    my $min_duration = 30;
    my $max_duration = 0;
    my $min_cost     = 1000000;
    my $max_cost     = 0;

    foreach my $trip (@$itineraries) {
        $min_duration = ( $trip->{numdays} < $min_duration ) ? $trip->{numdays} : $min_duration;
        $max_duration = ( $trip->{numdays} > $max_duration ) ? $trip->{numdays} : $max_duration;
        $min_cost     = ( $trip->{cost}    < $min_cost )     ? $trip->{cost}    : $min_cost;
        $max_cost     = ( $trip->{cost}    > $max_cost )     ? $trip->{cost}    : $max_cost;
    }

    if ( $option eq $STATES ) {

        # create or update city popups
        my $config  = { RELATIVE => 1, INCLUDE_PATH => [ "../views" ] };
        my $tt      = Template->new($config);

        foreach my $cityid_array (@$places) {
            my $vars = {
                items      => images( $cityid_array->{cities_id}, 'city', 'large' ),
                imagepath  => 'city',
                uribase    => request->uri_base,
                webwriteup => addptags( $cityid_array->{writeup} ),
                cityinfo   => city( $cityid_array->{cities_id} ),
            };
    
            my $output = "../public/ajax/slideshow-city-" . $cityid_array->{cities_id} . ".html";
           
            unless ( -f $output && -M $output < 30 ) { 
                # $tt->process( 'slideshowcity.tt', $vars, $output ) || die $tt->error;
            }
        }

        template states => {
            metatags      => $stateinfo,
            country       => $destination,
            itineraries   => \@$itineraries,
            states        => \@$states,
            crumb         => $crumb,
            stateinfo     => $stateinfo,
            filter        => $filter,
            pathname      => $STATES,
            state         => $state,
            display       => $view,
            order         => $order,
            state_intro   => addptags( $stateinfo->{writeup} ),
            state_writeup => $state_writeup,
            cities        => \@$places,
            display       => $view,
            min_cost      => $min_cost,
            max_cost      => $max_cost,
            min_duration  => $min_duration,
            max_duration  => $max_duration,
        };
    }
    else {
    	
        template tours => {
            metatags          => metatags($TAILOR),
            country           => $destination,
            itineraries       => \@$itineraries,
            tripideas         => themes('TRIPIDEAS'),
            crumb             => $crumb,
            filter            => $filter,
            display           => $view,
            pathname          => $option,
            display           => $view,
            order             => $order,
            min_cost          => $min_cost,
            max_cost          => $max_cost,
            min_duration      => $min_duration,
            max_duration      => $max_duration,
            page_title        => ($option eq $REGIONS) ? $regioninfo->{title} : url2text($option),
            regionname        => $region,
            special_interests => webtext(190),
            regions           => \@$regions,
            currency          => $session_currency,
        };
    }
}

sub route_itinerary {

    my $destination = shift;
    my $tour        = shift;    # url of the tour name
    my $option      = shift;    # TAILOR, IDEAS, THEMES, or STATES
    my $theme       = shift;    # theme or region or state
    
    my $itinerary = itinerary( $tour );

    if (ref $itinerary ne ref {}) {
        return template special_404 => { 
            message => "$tour has been misspelled and/or is not on file.",
            url     => request->path, 
        };
    }

    my $cost            = itinerary_cost( $itinerary->{fixeditin_id}, $session_currency );
    my $startcity       = ( exists $itinerary->{startcity} ) ? city( $itinerary->{startcity} ) : '';
    my $endcity         = city( $itinerary->{endcity} );
    my $days            = ( $itinerary->{days} ? $itinerary->{days} : '' );
    my $category        = ( $itinerary->{readytours} ? 'ready tour' : 'module' );
    my $inclusions      = $itinerary->{inclusions};
    my $ourtime         = ourtime();
    my $daybyday        = daybyday($tour);
    my $accommodation   = youraccommodation($tour);
    my $similartours    = similartours( $startcity->{cities_id}, $session_currency );
    my $placesyou       = placesyouwillvisit($tour);
    my $itin            = $itinerary->{itinerary};

    $inclusions =~ s/\{/<br><h4>/;
    $inclusions =~ s/\}/<\/h4>/;
    $itin =~ s/\{/<br><b>/g;
    # set path for popups

    my $tt = Template->new( { 
    	RELATIVE => 0, 
    	INCLUDE_PATH => config->{root}.'/views',
    });

    my $imagedir = 'http://images.travellers-palm.com';

    # create or update city popups
    foreach my $cityid_array (@$daybyday) {
        my $vars = {
            items => images( $cityid_array->{cities_id}, 'city', 'large' ),
            imagepath  => 'city',
            uribase    => request->uri_base,
            webwriteup => addptags( $cityid_array->{writeup} ),
            cityinfo   => city( $cityid_array->{cities_id} ),
            IMAGE      => $imagedir,
        };
        my $output = config->{root}.'/public/ajax/slideshow-city-' . $cityid_array->{cities_id} . '.html';
        unless ( -f $output && -M $output < 30 ) { 
            $tt->process( 'slideshowcity.tt', $vars, $output ) || die $tt->error;
        }
    }

    # create or update tour popups
    my $vars = {
        items      => images( $itinerary->{tourname}, $category, 'large' ),
        imagepath  => $itinerary->{readytours} ? 'tour' : 'module' ,
        uribase    => request->uri_base,
        IMAGE      => $imagedir,
    };

    my $output = config->{root}.'/public/ajax/slideshow-tour-' . $itinerary->{fixeditin_id} .'.html';
    
    unless ( -f $output && -M $output < 30 ) {
        $tt->process( "slideshowtour.tt", $vars, $output ) || die $tt->error;
    }
   
    # create or update hotel popups
    foreach my $hotel_array (@$accommodation) {
        my $vars = {
            items     => images( $hotel_array->{hotel_id}, 'hotel', 'large' ),
            imagepath => 'hotel',
            uribase   => request->uri_base,
            writeup   => addptags( $hotel_array->{description} ),
            hotelinfo => hotel( $hotel_array->{hotel_id} ),
            IMAGE      => $imagedir,
        };
        
        my $output = config->{root}.'/public/ajax/slideshow-hotel-' . $hotel_array->{hotel_id} . '.html';
       
        unless ( -f $output && -M $output < 30 ) {
            $tt->process( "slideshowhotel.tt", $vars, $output ) || die $tt->error;
        }
    }

    my $themeinfo;
    my $regioninfo;
    my $image;
 
    my $crumb =    "<li>Destinations</li>
                    <li><a href='".request->uri_base."/destinations/$destination'>". url2text($destination) . "</a></li>";

    if ( $option eq $TAILOR ) {
        $image  = qq/tour_$itinerary->{tourname}_large_1.jpg/;

        $crumb .= "<li><a href='".request->uri_base."/destinations/$destination/$TAILOR/list'>". url2text($TAILOR) . "</a></li>
                   <li class='active'>" . $itinerary->{title} . "</li>";
    }
    elsif ( $option eq $THEMES ) {

        $themeinfo = themes_url($theme);
        $image     = ($itinerary->{readytours} ? 'tour' : 'mod') . "_$itinerary->{tourname}_large_1.jpg";

        $crumb .= " <li><a href='".request->uri_base."/destinations/$destination/$THEMES'>". url2text($THEMES). "</a></li>
                    <li><a href='".request->uri_base."/destinations/$destination/$THEMES/$theme'>". $themeinfo->{pagename} . "</a></li>
                    <li class='active'>" . $itinerary->{title} . "</li>";
    }
    elsif ( $option eq $REGIONS ) {

        $regioninfo = regionsurl($theme);
        $image = qq/mod_$itinerary->{tourname}_large_1.jpg/;

        $crumb .= " <li><a href='".request->uri_base."/destinations/$destination/$REGIONS'>" . url2text($REGIONS) . "</a></li>
                    <li><a href='".request->uri_base."/destinations/$destination/$REGIONS/"  . $regioninfo->{url} . "/list'>". $regioninfo->{title} . "</a></li>
                    <li class='active'>" . $itinerary->{title} . "</li>";
    }
    elsif ( $option eq $STATES ) {

        $image = ($itinerary->{readytours} ? 'tour' : 'mod') . "_$itinerary->{tourname}_large_1.jpg";

        $crumb .= " <li><a href='".request->uri_base."/destinations/$destination/$STATES'>" . url2text($STATES) . "</a></li>
                    <li><a href='".request->uri_base."/destinations/$destination/$STATES/"  . $theme . "/list'>". url2text($theme) . "</a></li>
                    <li class='active'>" . $itinerary->{title} . "</li>";
    }

    return template itinerary => {
        metatags        => $itinerary,
        inclusions      => $inclusions,
        tourdata        => $itinerary,
        cost            => $cost,
        startcity       => $startcity,
        endcity         => $endcity,
        itinerary       => $itin,
        country         => $destination,
        image           => $image, 
        tours           => \@$similartours,
        days            => \@$daybyday,
        places          => \@$placesyou,
        accommodation   => \@$accommodation,
        ourtime         => $ourtime->strftime('%H:%M'),
        ourdate         => $ourtime->strftime('%d %B,%Y'),
        timediff        => 0, #timediff(),
        pathname        => $option,
        crumb           => $crumb,
        imagepath       => 'tour',
        tweak           => webtext(118),
        need_help       => webtext(176),
        themeinfo       => $themeinfo,  
        plan_your_trip  => webtext(73),
        plan_and_refine => webtext(184),
        arrangements    => webtext(185),
        page_title      => $itinerary->{title},
    };
};