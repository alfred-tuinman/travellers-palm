package TravellersPalm::Controller::Destinations;

use strict;
use warnings;

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

use TravellersPalm::Functions qw/boldify email_request ourtime url2text webtext/;
use TravellersPalm::Database::Connector qw(dbh);
use TravellersPalm::Database::States;
use TravellersPalm::Database::General;
use TravellersPalm::Constants ;

our $TAILOR   	= 'ready-tours';
our $STATES   	= 'explore-by-state';
our $THEMES   	= 'explore-by-interest';
our $REGIONS  	= 'explore-by-region';


# ------------------------------------------------------------------
#                     named subroutines
# ------------------------------------------------------------------

sub show_destination {
    my $destination = route_parameters->get('destination');

    my $crumb = "<li>Destinations</li>
                 <li class='active'>" . url2text($destination) . "</li>";

    template('destination') => {
        metatags    => TravellersPalm::Database::General::metatags($destination),
        destination => $destination,
        crumb       => $crumb,
        page_title  => url2text($destination),
        writeup     => webtext(7),
    };
}

sub show_tailor {
    my ($destination, $arg) = @{ request->splat };

    my @arg   = @$arg;                 # if second capture is an arrayref
    my $view  = $arg[0];
    my $order = $arg[1] // 'popularity';

    if ( $view =~ /^(grid|block|list)$/ ) {
        TravellersPalm::FunctionsRouter::route_listing( $destination, $TAILOR, $view, $order );
    }
    else {
        TravellersPalm::FunctionsRouter::route_itinerary( $destination, $view, $TAILOR );
    }
}


sub show_region_list {
    my ($destination) = @{ request->splat };

    my $content = webtext(7);
    my $webpage = webpages('11');

    my $crumb = "<li>Destinations</li>
                 <li><a href='".request->uri_base."/destinations/$destination'>"
                 . url2text($destination) . "</a></li>
                 <li class='active'>" . url2text($REGIONS) . "</li>";

    template('regions') => {
        metatags   => TravellersPalm::Database::General::metatags("$REGIONS"),
        writeup    => boldify( addptags( $content->{writeup} ) ),
        page_title => url2text($REGIONS),
        regions    => regions(),
        crumb      => $crumb,
        pathname   => $REGIONS,
        country    => $destination,
    };
}

sub show_region_detail {
    my ( $destination, $arg ) =  @{ request->splat };

    my @arg    = @$arg;
    my $region = $arg[0];
    my $view   = $arg[1] // 'list';
    my $order  = $arg[2] // 'popularity';

    if ( $view =~ /^(grid|block|list)$/ ) {
        TravellersPalm::FunctionsRouter::route_listing( $destination, $REGIONS, $view, $order, $region );
    }
    else {
        TravellersPalm::FunctionsRouter::route_itinerary( $destination, $view, $REGIONS, $region );
    }
}

sub show_state_list {
    my ($destination) =  @{ request->splat };

    my $state    = TravellersPalm::Database::States::states($destination);
    my @states   = grep { $_->{state} } @$state;

    my $crumb = "<li>Destinations</li>
                 <li><a href='".request->uri_base."/destinations/$destination'>"
                 . url2text($destination) . "</a></li>
                 <li class='active'>" . url2text($STATES) . "</li>";

    template('state') => {
        metatags   => TravellersPalm::Database::General::metatags("$STATES"),
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
    my ( $destination, $arg ) = @{ request->splat };

    my @arg   = @$arg;
    my $state = $arg[0];
    my $view  = $arg[1] // 'list';
    my $order = $arg[2] // 'popularity';

    if ( $view =~ /^(grid|block|list)$/ ) {
        TravellersPalm::FunctionsRouter::route_listing( $destination, $STATES, $view, $order, $state );
    }
    else {
        TravellersPalm::FunctionsRouter::route_itinerary( $destination, $view, $STATES, $state );
    }
}

sub show_theme_list {
    my ($destination) = @{ request->splat };

    my $crumb = "<li>Destinations</li>
                 <li><a href='".request->uri_base."/destinations/$destination'>"
                 . url2text($destination) . "</a></li>
                 <li class='active'>" . url2text($THEMES) . "</li>";

    template('theme') => {
        metatags   => TravellersPalm::Database::General::metatags("$THEMES"),
        themes     => TravellersPalm::Database::Themes::themes(),
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
    my $params         = params();
    my $plan_your_trip = webtext(73);
    my $crumb          = "<li><a href='".request->uri_base.'/'.request->path."'>"
                           .$plan_your_trip->title."</a></li>";

    if ( request->is_post ) {
        $ok = email_request($params);
        $error = $ok ? 0 : 1;
    }

    if ($ok) {
      template('email_thankyouforrequest') => {
          metatags   => TravellersPalm::Database::General::metatags( ( split '/', request->path )[-1] ),
          crumb      => $crumb,
          name       => $params->{name},
          email      => $params->{email},
          message    => $params->{message},
          reference  => $params->{reference},
          page_title => $plan_your_trip->{title},
      };

    }
    else {
        template('plan_your_trip') => {
            metatags         => TravellersPalm::Database::General::metatags( ( split '/', request->path )[-1] ),
            plan_your_trip   => $plan_your_trip,
            get_inspired     => webtext(173),
            quote            => webtext(174),
            plan_and_refine  => webtext(184),
            arrangements     => webtext(185),
            why_book_with_us => webtext(14),
            error            => $error,
            crumb            => $crumb,
            name             => $params->{name},
            email            => $params->{email},
            message          => $params->{message},
            reference        => $params->{reference},
            page_title       => $plan_your_trip->{title},
        };
    }
}

1;
