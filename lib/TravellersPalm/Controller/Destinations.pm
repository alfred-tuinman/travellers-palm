package TravellersPalm::Controller::Destinations;

use strict;
use warnings;

use Dancer2 appname => 'TravellersPalm';      # link to main app
use Dancer2::Plugin::Database;

use Template;
use Data::FormValidator;
use Date::Manip::Date;
use Data::Dumper;
use DateTime::Format::Strptime;
use Digest::MD5 qw/md5_hex/;
use MIME::Lite;
use URI::http;
use JSON qw//;
use Exporter 'import';

use TravellersPalm::FunctionsRouter qw/route_listing route_itinerary/;
use TravellersPalm::Database::States;

our @EXPORT_OK  = qw/register_routes/; # _OK means on request only, not automatic
our $TAILOR   	= 'ready-tours', 
our $STATES   	= 'explore-by-state';
our $THEMES   	= 'explore-by-interest';
our $REGIONS  	= 'explore-by-region';

sub register_routes {

    get '/destinations/:destination' => \&show_destination;

    any [ 'get', 'post' ] => "/destinations/*/$TAILOR/**" => \&show_tailor;

    get "/destinations/*/$REGIONS" => \&show_region_list;
    get "/destinations/*/$REGIONS/**" => \&show_region_detail;

    get "/destinations/*/$STATES" => \&show_state_list;
    get "/destinations/*/$STATES/**" => \&show_state_detail;

    get "/destinations/*/$THEMES" => \&show_theme_list;
    get "/destinations/*/$THEMES/**" => \&show_theme_detail;

    any [ 'get', 'post' ] => '/plan-your-trip' => \&plan_your_trip;
}

# ------------------------------------------------------------------
#                     named subroutines
# ------------------------------------------------------------------

sub show_destination {
    my $destination = route_parameters->get('destination');

    my $crumb = "<li>Destinations</li>
                 <li class='active'>" . url2text($destination) . "</li>";

    template destination => {
        metatags    => metatags($destination),
        destination => $destination,
        crumb       => $crumb,
        page_title  => url2text($destination),
        writeup     => webtext(7),
    };
}

sub show_tailor {
    my ( $destination, $arg ) = splat;
    my @arg   = @$arg;
    my $view  = $arg[0];
    my $order = $arg[1] // 'popularity';

    if ( $view =~ /^(grid|block|list)$/ ) {
        route_listing( $destination, $TAILOR, $view, $order );
    }
    else {
        route_itinerary( $destination, $view, $TAILOR );
    }
}

sub show_region_list {
    my ($destination) = splat;

    my $content = webtext(7);
    my $webpage = webpages('11');

    my $crumb = "<li>Destinations</li>
                 <li><a href='".request->uri_base."/destinations/$destination'>"
                 . url2text($destination) . "</a></li>
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
}

sub show_region_detail {
    my ( $destination, $arg ) = splat;

    my @arg    = @$arg;
    my $region = $arg[0];
    my $view   = $arg[1] // 'list';
    my $order  = $arg[2] // 'popularity';

    if ( $view =~ /^(grid|block|list)$/ ) {
        route_listing( $destination, $REGIONS, $view, $order, $region );
    }
    else {
        route_itinerary( $destination, $view, $REGIONS, $region );
    }
}

sub show_state_list {
    my ($destination) = splat;

    my $state    = states($destination);
    my @states   = grep { $_->{state} } @$state;

    my $crumb = "<li>Destinations</li>
                 <li><a href='".request->uri_base."/destinations/$destination'>"
                 . url2text($destination) . "</a></li>
                 <li class='active'>" . url2text($STATES) . "</li>";

    template state => {
        metatags   => metatags("$STATES"),
        writeup    => boldify( webtext(122) ),
        states     => \@states,
        country    => $destination,
        random     => 1 + int(rand 35),
        crumb      => $crumb,
        call       => webtext(175),
        page_title => url2text($STATES),
        pathname   => $STATES,
    };
}

sub show_state_detail {
    my ( $destination, $arg ) = splat;

    my @arg   = @$arg;
    my $state = $arg[0];
    my $view  = $arg[1] // 'list';
    my $order = $arg[2] // 'popularity';

    if ( $view =~ /^(grid|block|list)$/ ) {
        route_listing( $destination, $STATES, $view, $order, $state );
    }
    else {
        route_itinerary( $destination, $view, $STATES, $state );
    }
}

sub show_theme_list {
    my ($destination) = splat;

    my $crumb = "<li>Destinations</li>
                 <li><a href='".request->uri_base."/destinations/$destination'>"
                 . url2text($destination) . "</a></li>
                 <li class='active'>" . url2text($THEMES) . "</li>";

    template theme => {
        metatags   => metatags("$THEMES"),
        themes     => themes(),
        crumb      => $crumb,
        pathname   => $THEMES,
        page_title => url2text($THEMES),
        country    => $destination,
    };
}

sub show_theme_detail {
    # Full body of your long theme route goes here…
    # copy everything from your original big get "/destinations/*/$THEMES/**" block
    # and paste inside this sub
}

sub plan_your_trip {
    my $ourtime        = ourtime();
    my $ok             = 0;
    my $error          = 0;
    my $plan_your_trip = webtext(73);
    my $crumb          = "<li><a href='".request->uri_base.'/'.request->path."'>"
                           .$plan_your_trip->title."</a></li>";

    if ( request->is_post ) {
        $ok = email_thankyouforrequest(params);
        $error = $ok ? 0 : 1;
    }

    if ($ok) {
        template email_thankyouforrequest => {
            metatags   => metatags( ( split '/', request->path )[-1] ),
            crumb      => $crumb,
            name       => params->{name},
            email      => params->{email},
            message    => params->{message},
            reference  => params->{reference},
            page_title => $plan_your_trip->{title},
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
}

1;
