package TravellersPalm::Controller::Itineraries;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use POSIX qw(strftime);
use TravellersPalm::Constants qw(:all);
use TravellersPalm::Database::Itineraries qw(
    itineraries itinerary itinerary_cost placesyouwillvisit similartours toursinstate youraccommodation
);
use TravellersPalm::Database::Themes qw(themes themes_url);
use TravellersPalm::Database::General qw(daybyday modules regions regionsurl hotel metatags);
use TravellersPalm::Database::States qw(states statesurl);
use TravellersPalm::Database::Cities qw(city);
use TravellersPalm::Database::Images qw(images);
use TravellersPalm::Functions qw(ourtime webtext addptags linkify url2text);

my $session_currency = 'USD';

# -----------------------------
# Listing routes
# -----------------------------
sub route_listing ($self) {
    my $destination = $self->stash('destination');
    my $option      = $self->stash('option');
    my $view        = $self->stash('view') // 'list';
    my $order       = $self->stash('order') // 'days';
    my $region      = $self->stash('region');

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
