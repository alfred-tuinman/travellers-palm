package TravellersPalm::Controller::Destinations;
use strict;
use warnings;
use Template;

use Dancer2;

use Data::FormValidator;
use Date::Manip::Date;
use Data::Dumper;

use TravellersPalm::Functions;
use TravellersPalm::Database;



get '/destinations/:destination' => sub {

    my $crumb  = "<li>Destinations</li>
                  <li class='active'>" . url2text( params->{destination} ) . "</li>";

    template destination => {
        metatags    => metatags(params->{destination}),
        destination => params->{destination},
        crumb       => $crumb,
        page_title  => url2text( params->{destination} ),
        writeup     => webtext(7),
    };
};

any [ 'get', 'post' ] => "/destinations/*/$TAILOR/**" => sub {

    # valid options are popularity (default), days and price

    my ( $destination, $arg ) = splat;

    my @arg   = @{$arg};
    my $view  = @$arg[0];
    my $order = @$arg[1] ? @$arg[1] : 'popularity';

    if ( $view eq 'grid' || $view eq 'block' || $view eq 'list' ) {
        route_listing( $destination, $TAILOR, $view, $order );
    }
    else {
        route_itinerary( $destination, @$arg[0], $TAILOR );
    }
};

get "/destinations/*/$REGIONS" => sub {

    my ($destination) = splat;
    my $content       = webtext(7);
    my $webpage       = webpages('11');
  
    my $crumb    = "<li>Destinations</li>
                    <li><a href='".request->uri_base."/destinations/$destination'>" . url2text($destination) . "</a></li>
                    <li class='active'>" . url2text($REGIONS) . "</li>";

    template regions => {
        metatags   => metatags("$REGIONS"),
        writeup    => boldify( addptags( $content->{writeup} ) ),
        page_title => url2text($REGIONS),
        regions    => regions(),
        crumb      => $crumb,
        pathname   => $REGIONS,
        country    => $destination,
    };
};

get "/destinations/*/$REGIONS/**" => sub {

   # e.g.
   # destinations/india/mini-itineraries/kolkata-the-east/list/popularity-desc
   # destinations/india/mini-itineraries/kolkata-the-east/kolkata
   # destinations/india/mini-itineraries/rajasthan-the-north/list
   # destinations/india/explore-by-region/mumbai-goa-the-deccan/mumbai
   my ( $destination, $arg ) = splat;

   my @arg    = @{$arg};
   my $region = @$arg[0];
   my $view   = @$arg[1] ? @$arg[1] : 'list';
   my $order  = @$arg[2] ? @$arg[2] : 'popularity';

   if ( $view eq 'grid' || $view eq 'block' || $view eq 'list' ) {
        route_listing( $destination, $REGIONS, $view, $order, $region );
    }
    else {
        route_itinerary( $destination, $view, $REGIONS, $region );
    }
};

get "/destinations/*/$STATES" => sub {

    my ($destination) = splat;

    my $state    = states($destination);
    my @states   = grep { $_->{state} } @$state;
    my $crumb    = "<li>Destinations</li>
                 <li><a href='".request->uri_base."/destinations/$destination'>". url2text($destination) . "</a></li>
                 <li class='active'>" . url2text($STATES) . "</li>";

    template state => {
        metatags        => metatags("$STATES"),
        writeup         => boldify( webtext(122) ),
        states          => \@states,
        country         => $destination,
        random          => 1 + int( rand 35 ),
        crumb           => $crumb,
        call            => webtext(175),
        page_title      => url2text($STATES),
        pathname        => $STATES,
    };
};

get "/destinations/*/$STATES/**" => sub {

    # e.g. destinations/india/explore-by-state/assam/list/days-desc

    my ( $destination, $arg ) = splat;

    my @arg   = @{$arg};
    my $state = @$arg[0];
    my $view  = @$arg[1] ? @$arg[1] : 'list';
    my $order = @$arg[2] ? @$arg[2] : 'popularity';

    if ( $view eq 'grid' || $view eq 'block' || $view eq 'list' ) {
        route_listing( $destination, $STATES, $view, $order, $state );
    }
    else {
        route_itinerary( $destination, $view, $STATES, $state );
    }
};

get "/destinations/*/$THEMES" => sub {

    my ($destination) = splat;

    my $crumb = "<li>Destinations</li>
                 <li><a href='".request->uri_base."/destinations/$destination'>" . url2text($destination) . "</a></li>
                 <li class='active'>" . url2text($THEMES) . "</a></li>";

    template theme => {
        metatags   => metatags("$THEMES"),
        themes     => themes(),
        crumb      => $crumb,
        pathname   => $THEMES,
        page_title => url2text($THEMES),
        country    => $destination,
    };
};

get "/destinations/*/$THEMES/**" => sub {

    my ( $destination, $arg ) = splat;
 
    my @arg   = @{$arg};
    my $theme = @$arg[0] // 'romance';
    my $view  = @$arg[1] ? @$arg[1] : 'list' ; # list, block or grid
    my $order = @$arg[2] ? @$arg[2] : 'popularity'; # days, price, popularity

    my $themeinfo = themes_url($theme);    
    my $ideas     = ($themeinfo->{themes_id} > 6) ? 1 : 0;
    my $exist     = itinerary_exist($view);
 
    if ($exist->{exist} > 0 ){
  
        route_itinerary( $destination, $view, $THEMES, $theme );
    } 
    else {
           
        my $itineraries = themetrips( $themeinfo->{themes_id}, $session_currency, $order );

        my $max = 0;
        my $themes ;
        my @subthemes;
        my @array  = ();
        my $subthemes ;
        my $markers;

        my @icons = (
             'blue-dot.png',   'orange-dot.png',
             'purple-dot.png', 'pink-dot.png',
             'yellow-dot.png', 'red-dot.png',
             'green-dot.png',  'blue-dot.png',
             'orange-dot.png', 'purple-dot.png'
             );

        foreach my $trip (@$itineraries) {
            $max = ( $trip->{lengthintro} > $max ) ? $trip->{lengthintro} : $max;
        }

        if ($ideas == 0){
            $themes = themes('LIMIT');

            $subthemes   = subthemes( $themeinfo->{themes_id} );
            $markers     = themes_subthemes( $themeinfo->{themes_id} );

            @subthemes = map {{   
                themes_id    => $_->{themes_id},
                oneliner     => $_->{oneliner},
                url          => $_->{url},
                subthemes_id => $_->{subthemes_id},
                introduction => boldify( addptags( $_->{introduction} ) ),
                subtheme     => $_->{subtheme},
                title        => $_->{title},
                }} @$subthemes;

            my $colour = -1;
            my $id     = 0;

            foreach my $mark (@$markers) {
                if ( $id ne $mark->{subthemes_id} ) {
                    $id = $mark->{subthemes_id};
                    $colour++;
                }
                $mark->{colour} = $icons[$colour];
                push @array, $mark;
            }
        } 
        else {
            $themes = themes('TRIPIDEAS');
        }
        
        # create or update tour popups and set data for sliders
        my $tt           = Template->new( config('app') );
        my $min_duration = 30;
        my $max_duration = 0;
        my $min_cost     = 1000000;
        my $max_cost     = 0;

        foreach my $trip (@$itineraries) {
            $min_duration = ( $trip->{numdays} < $min_duration ) ? $trip->{numdays} : $min_duration;
            $max_duration = ( $trip->{numdays} > $max_duration ) ? $trip->{numdays} : $max_duration;
            $min_cost     = ( $trip->{cost}    < $min_cost )     ? $trip->{cost}    : $min_cost;
            $max_cost     = ( $trip->{cost}    > $max_cost )     ? $trip->{cost}    : $max_cost;

            my @tourimages = images( $trip->{tourname}, 'ready tour', 'large' );
           
            my $vars = {
                items     => \@tourimages,
                imagepath => 'tours',
                uribase   => request->uri_base,
            };

            my $output = "public/ajax/slideshow-tour-" . $trip->{tourname} . ".html";
            if ( !( -e $output ) || ( -M $output > 30 ) ) {
                #$tt->process( "slideshowtour.tt", $vars, $output ) || die $tt->error;
            }
        }

        my $crumb = "<li>Destinations</li>
                    <li><a href='".request->uri_base."/destinations/$destination'>". url2text($destination) . "</a></li>
                    <li><a href='".request->uri_base."/destinations/$destination/$THEMES'>". url2text($THEMES) . "</a></li>
                    <li class='active'>" . $themeinfo->{pagename} . "</li>";
      
        template themes => {
            metatags        => $themeinfo,
            introduction    => boldify( addptags( $themeinfo->{introduction} ) ),
            theme           => $theme,
            themeinfo       => $themeinfo,
            themes          => \@$themes,
            subthemes       => \@subthemes,
            itineraries     => \@$itineraries,
            crumb           => $crumb,
            option          => $THEMES,
            pathname        => $THEMES.'/'.$themeinfo->{url},
            filter          => 'themes',
            country         => $destination,
            maxlen          => $max,
            markers         => \@array,
            sample          => webtext(183),
            display         => $view,
            order           => $order,
            min_cost        => $min_cost,
            max_cost        => $max_cost,
            min_duration    => $min_duration,
            max_duration    => $max_duration,
            ideas           => $ideas,
            page_title      => $themeinfo->{pagename},
        };
    }
};

any [ 'get', 'post' ] => '/plan-your-trip' => sub {
    
    my $ourtime         = ourtime();
    my $ok              = 0;
    my $error           = 0;
    my $plan_your_trip  = webtext(73);
    my $crumb           = "<li><a href='".request->uri_base.'/' . request->path . "'>".$plan_your_trip->title."</a></li>";
    
    if ( request->is_post ) {
        $ok = email_thankyouforrequest(params);
        $error = ($ok) ? 0 : 1;
    }

    if ($ok) {
        template email_thankyouforrequest => {
            metatags        => metatags( ( split '/', request->path )[-1] ),
            crumb           => $crumb,
            name            => params->{name},
            email           => params->{email},
            message         => params->{message},
            reference       => params->{reference},
            page_title      => $plan_your_trip->{title},
        };
    }
    else {
        template plan_your_trip => {
            metatags         => metatags( ( split '/', request->path )[-1] ),
            plan_your_trip   => $plan_your_trip,
            get_inspired     => webtext(173),
            quote            => webtext(174),
            plan_and_refine  => webtext(184),
            arrangements     => webtext(185),
            why_book_with_us => webtext(14),
            error            => $error,
            crumb            => $crumb,
            name             => params->{name},
            email            => params->{email},
            message          => params->{message},
            reference        => params->{reference},
            page_title       => $plan_your_trip->{title},
        };
    }
};
