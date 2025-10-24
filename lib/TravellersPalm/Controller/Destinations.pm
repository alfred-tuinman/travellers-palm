package TravellersPalm::Controller::Destinations;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use TravellersPalm::Database::Itineraries qw(itinerary itinerary_cost);
use TravellersPalm::Database::Itinerary qw(route_listing itinerary_details);
use TravellersPalm::Database::General qw(metatags regionsurl regions);
use TravellersPalm::Database::States qw(states);
use TravellersPalm::Database::Themes qw(themes);
use TravellersPalm::Constants qw(:all);
use TravellersPalm::Functions qw(boldify email_request ourtime url2text webtext);


# -------------------------------
# Controller Actions
# -------------------------------

# → single destination page
sub show_destination ($self) {
    my $destination = $self->param('destination');
    my $crumb = "<li>Destinations</li><li class='active'>" . url2text($destination) . "</li>";

    $self->render(
        template    => 'destination',
        metatags    => TravellersPalm::Database::General::metatags($destination, $self),
        destination => $destination,
        crumb       => $crumb,
        page_title  => url2text($destination),
        writeup     => webtext(7),
    );
}

# → regions overview
sub show_region_list ($self) {
    my $dest    = $self->stash('destination');
    my $view    = $self->stash('view') // 'list';  # default if missing
    my $content = webtext(7);

    my $crumb = "<li>Destinations</li>"
              . "<li class='active'>" . url2text(REGIONS) . "</li>"
              . "<li><a href='" . $self->req->url->base . "/destinations/" . url2text(REGIONS) . "/$dest'>"
              . url2text($dest) . "</a></li>";

    my $metatags = TravellersPalm::Database::General::metatags(REGIONS, $self);

    $self->render(
        template   => 'regions',
        metatags   => $metatags,
        writeup    => boldify($content->{writeup}),
        page_title => url2text(REGIONS),
        regions    => regions(),  # multi-row
        crumb      => $crumb,
        pathname   => REGIONS,
        country    => $dest,
    );
}

# → state overview
sub show_state_list ($self) {
    my $dest   = $self->stash('destination');
    my $view   = $self->stash('view') // 'list';  # default if missing
    my $states = states($dest);
    my @filtered = grep { $_->{state} } @$states;

    my $crumb = "<li>Destinations</li>"
              . "<li><a href='" . $self->req->url->base . "/destinations/$dest'>"
              . url2text($dest) . "</a></li>"
              . "<li class='active'>" . url2text(STATES) . "</li>";

    $self->render(
        template   => 'state',
        metatags   => metatags(STATES),
        writeup    => boldify(webtext(122)),
        states     => \@filtered,
        country    => $dest,
        random     => 1 + int(rand 35),
        crumb      => $crumb,
        call       => webtext(175),
        page_title => url2text(STATES),
        pathname   => STATES,
    );
}

# → state-specific listings
sub show_state_detail ($self) {
    my $dest  = $self->stash('destination');
    my $state = $self->stash('state');
    my $view  = $self->stash('view');
    my $order = $self->stash('order');

    $self->dump_log("View is $view", $self->stash);

    if ($view =~ /^(grid|block|list)$/) {
        route_listing($dest, STATES, $view, $order, $state);
    } else {
        route_itinerary($dest, $view, STATES, $state);
    }
}

# → themes overview
sub show_theme_list ($self) {
    my ($destination) = @{ $self->stash('splat') // [] };
    my $view  = $self->stash('view') // 'list';  # default if missing
    my $crumb = "<li>Destinations</li>"
              . "<li><a href='" . $self->req->url->base . "/destinations/$destination'>"
              . url2text($destination) . "</a></li>"
              . "<li class='active'>" . url2text(THEMES) . "</li>";

    $self->render(
        template   => 'theme',
        metatags   => metatags(THEMES),
        themes     => themes($self),
        crumb      => $crumb,
        pathname   => THEMES,
        page_title => url2text(THEMES),
        country    => $destination,
    );
}

# → theme-specific listings
sub show_theme_detail ($self) {
    my $dest  = $self->stash('destination');
    my $theme = $self->stash('theme');
    my $view  = $self->stash('view') ;
    my $order = $self->stash('order');

    $self->dump_log("Stash is ", $self->stash);

    if ($view =~ /^(grid|block|list)$/) {
        route_listing($dest, THEMES, $view, $order, $theme);
    } else {
        route_itinerary($dest, $view, THEMES, $theme);
    }
}

# → trip form handler
sub plan_your_trip ($self) {
    my $params = $self->req->params->to_hash;
    my $ok     = 0;
    my $error  = 0;
    my $plan   = webtext(73);
    my $crumb  = "<li><a href='" . $self->req->url->base . $self->req->url->path . "'>"
               . $plan->{title} . "</a></li>";

    if ($self->req->method eq 'POST') {
        $ok = email_request($params);
        $error = $ok ? 0 : 1;
    }

    my $template = $ok ? 'email_thankyouforrequest' : 'plan_your_trip';

    $self->dump_log("Params are ", $params);

    $self->render(
        template   => $template,
        metatags   => metatags((split '/', $self->req->url->path->to_string)[-1]),
        plan_your_trip   => $plan,
        get_inspired     => webtext(173),
        quote            => webtext(174),
        plan_and_refine  => webtext(184),
        arrangements     => webtext(185),
        why_book_with_us => webtext(14),
        error            => $error,
        crumb            => $crumb,
        %$params,
        page_title => $plan->{title},
    );
}


# -----------------------------
# Listing routes
# -----------------------------
sub route_listing ($self) {
    my $destination = $self->stash('destination');
    my $option      = $self->stash('option');
    my $view        = $self->stash('view') // 'list';
    my $order       = $self->stash('order') // 'days';
    my $region      = $self->stash('region');

    my $session_currency = $self->session_currency;

    my %valid = map { $_ => 1 } qw(grid block list);
    return $self->render(status => 400, text => "Invalid view '$view'")
        unless $valid{$view};

    my $crumb = sprintf(
        "<li>Destinations</li><li><a href='%s/destinations/%s'>%s</a></li>",
        $self->req->url->base,
        $destination,
        url2text($destination)
    );

    my ($itineraries, $states, $state, $stateinfo, $state_writeup, $regioninfo, $places, $filter, $regions);

    if ($option eq TAILOR) {
        $itineraries = itineraries(option => 'itin', currency => $session_currency, order => $order);
        $filter      = 'tailor';
        $crumb     .= "<li class='active'>" . url2text(TAILOR) . "</li>";
    }
    elsif ($option eq REGIONS) {
        $itineraries = modules(region => $region, currency => $session_currency, order => $order);
        $regioninfo  = regionsurl($region);
        $regions     = regions();
        $filter      = 'regions';

        $crumb .= sprintf(
            "<li><a href='%s/destinations/%s/%s'>%s</a></li><li class='active'>%s</li>",
            $self->req->url->base,
            $destination,
            REGIONS,
            url2text(REGIONS),
            $regioninfo->{title}
        );
    }
    elsif ($option eq STATES) {
        $state       = $region;
        $stateinfo   = statesurl($state);
        $itineraries = toursinstate(state => $state, currency => $session_currency, order => $order);
        $states      = states($destination);
        $filter      = 'states';

        $crumb .= sprintf(
            "<li><a href='%s/destinations/%s/%s'>%s</a></li><li class='active'>%s</li>",
            $self->req->url->base,
            $destination,
            STATES,
            url2text(STATES),
            url2text($state)
        );

        ($state_writeup, $places) = linkify(addptags($stateinfo->{webwriteup}));
    }

    my ($min_duration, $max_duration, $min_cost, $max_cost) = (30, 0, 1_000_000, 0);
    for my $trip (@$itineraries) {
        $min_duration = $trip->{numdays} if $trip->{numdays} < $min_duration;
        $max_duration = $trip->{numdays} if $trip->{numdays} > $max_duration;
        $min_cost     = $trip->{cost}    if $trip->{cost}    < $min_cost;
        $max_cost     = $trip->{cost}    if $trip->{cost}    > $max_cost;
    }

    if ($option eq STATES) {
        return $self->render(
            template      => 'states',
            metatags      => $stateinfo,
            country       => $destination,
            itineraries   => $itineraries,
            states        => $states,
            crumb         => $crumb,
            stateinfo     => $stateinfo,
            filter        => $filter,
            pathname      => STATES,
            state         => $state,
            display       => $view,
            order         => $order,
            state_intro   => addptags($stateinfo->{writeup}),
            state_writeup => $state_writeup,
            cities        => $places,
            min_cost      => $min_cost,
            max_cost      => $max_cost,
            min_duration  => $min_duration,
            max_duration  => $max_duration,
        );
    }

    return $self->render(
        template          => 'tours',
        metatags          => metatags(TAILOR),
        country           => $destination,
        itineraries       => $itineraries,
        tripideas         => themes('TRIPIDEAS'),
        crumb             => $crumb,
        filter            => $filter,
        display           => $view,
        pathname          => $option,
        order             => $order,
        min_cost          => $min_cost,
        max_cost          => $max_cost,
        min_duration      => $min_duration,
        max_duration      => $max_duration,
        page_title        => ($option eq REGIONS) ? $regioninfo->{title} : url2text($option),
        regionname        => $region,
        special_interests => webtext(190),
        regions           => $regions,
        currency          => $session_currency,
    );
}

# -----------------------------
# Single itinerary route
# -----------------------------
sub route_itinerary ($self) {
    my $destination = $self->stash('destination');
    my $tour        = $self->stash('tour');
    my $option      = $self->stash('option');
    my $theme       = $self->stash('theme');
    my $session_currency = $self->session_currency;

    my $itinerary = itinerary($tour);

    unless (ref $itinerary eq 'HASH') {
        return $self->render(
            template => 'special_404',
            message  => "$tour has been misspelled or is not on file.",
            url      => $self->req->url->path,
        );
    }

    my $cost          = itinerary_cost($itinerary->{fixeditin_id}, $session_currency);
    my $startcity     = $itinerary->{startcity} ? city($itinerary->{startcity}) : '';
    my $endcity       = city($itinerary->{endcity});
    my $category      = $itinerary->{readytours} ? 'ready tour' : 'module';
    my $inclusions    = $itinerary->{inclusions};
    my $ourtime       = ourtime();
    my $daybyday      = daybyday($tour);
    my $accommodation = youraccommodation($tour);
    my $similartours  = $startcity ? similartours($startcity->{cities_id}, $session_currency) : [];
    my $placesyou     = placesyouwillvisit($tour);
    my $itin          = $itinerary->{itinerary};

    $inclusions =~ s/\{/<br><h4>/g;
    $inclusions =~ s/\}/<\/h4>/g;
    $itin       =~ s/\{/<br><b>/g;

    my $crumb = sprintf(
        "<li>Destinations</li><li><a href='%s/destinations/%s'>%s</a></li>",
        $self->req->url->base,
        $destination,
        url2text($destination)
    );

    $self->render(
        template        => 'itinerary',
        metatags        => $itinerary,
        inclusions      => $inclusions,
        tourdata        => $itinerary,
        cost            => $cost,
        startcity       => $startcity,
        endcity         => $endcity,
        itinerary       => $itin,
        country         => $destination,
        tours           => $similartours,
        days            => $daybyday,
        places          => $placesyou,
        accommodation   => $accommodation,
        ourtime         => $ourtime->strftime('%H:%M'),
        ourdate         => $ourtime->strftime('%d %B,%Y'),
        timediff        => 0,
        pathname        => $option,
        crumb           => $crumb,
        tweak           => webtext(118),
        need_help       => webtext(176),
        plan_your_trip  => webtext(73),
        plan_and_refine => webtext(184),
        arrangements    => webtext(185),
        page_title      => $itinerary->{title},
    );
}

1;
