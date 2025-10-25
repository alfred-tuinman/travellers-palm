package TravellersPalm::Controller::Itineraries;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use POSIX qw(strftime);
use TravellersPalm::Constants qw(:all);
use TravellersPalm::Functions qw(ourtime addptags linkify url2text);

BEGIN { require TravellersPalm::Database::General; }

my $session_currency = 'USD';

# -----------------------------
# Listing routes
# -----------------------------
sub route_listing ($self) {
    my $req         = $self->req;
    my $destination = $self->stash('destination');
    my $option      = $self->stash('option');
    my $view        = $self->stash('view') // 'list';
    my $order       = $self->stash('order') // 'days';
    my $region      = $self->stash('region');

    return $self->render(status => 400, text => "Invalid view '$view'")
        unless $view =~ /^(grid|block|list)$/;

    my $crumb = sprintf(
        "<li>Destinations</li><li><a href='%s/destinations/%s'>%s</a></li>",
        $req->url->base,
        $destination,
        url2text($destination)
    );

    my ($itineraries, $states, $state, $stateinfo, $state_writeup, $regioninfo, $places, $filter, $regions);

    if ($option eq TAILOR) {
        $itineraries = TravellersPalm::Database::Itineraries::itineraries(
            option   => 'itin',
            currency => $session_currency,
            order    => $order,
            $self
        );
        $filter = 'tailor';
        $crumb .= "<li class='active'>" . url2text(TAILOR) . "</li>";
    }
    elsif ($option eq REGIONS) {
        $itineraries = TravellersPalm::Database::General::modules(
            region   => $region,
            currency => $session_currency,
            order    => $order,
            $self
        );
        $regioninfo = TravellersPalm::Database::General::regionsurl($region, $self);
        $regions    = TravellersPalm::Database::General::regions($self);
        $filter     = 'regions';

        $crumb .= sprintf(
            "<li><a href='%s/destinations/%s/%s'>%s</a></li><li class='active'>%s</li>",
            $req->url->base,
            $destination,
            REGIONS,
            url2text(REGIONS),
            $regioninfo->{title}
        );
    }
    elsif ($option eq STATES) {
        $state       = $region;
        $stateinfo   = TravellersPalm::Database::States::statesurl($state, $self);
        $itineraries = TravellersPalm::Database::States::toursinstate(
            state    => $state,
            currency => $session_currency,
            order    => $order,
            $self
        );
        $states = TravellersPalm::Database::States::states($destination, $self);
        $filter = 'states';

        $crumb .= sprintf(
            "<li><a href='%s/destinations/%s/%s'>%s</a></li><li class='active'>%s</li>",
            $req->url->base,
            $destination,
            STATES,
            url2text(STATES),
            url2text($state)
        );

        ($state_writeup, $places) = linkify(addptags($stateinfo->{webwriteup}));
    }

    # Min/max calculations
    my ($min_duration, $max_duration, $min_cost, $max_cost) = (30, 0, 1_000_000, 0);
    for my $trip (@$itineraries) {
        $min_duration = $trip->{numdays} if $trip->{numdays} < $min_duration;
        $max_duration = $trip->{numdays} if $trip->{numdays} > $max_duration;
        $min_cost     = $trip->{cost}    if $trip->{cost}    < $min_cost;
        $max_cost     = $trip->{cost}    if $trip->{cost}    > $max_cost;
    }

    # Batch webtexts for templates
    my $webtexts = TravellersPalm::Database::General::webtext_multi([190, 118, 176, 73, 184, 185], $self);

    if ($option eq STATES) {
        return $self->render(
            template        => 'states',
            metatags        => $stateinfo,
            country         => $destination,
            itineraries     => $itineraries,
            states          => $states,
            crumb           => $crumb,
            stateinfo       => $stateinfo,
            filter          => $filter,
            pathname        => STATES,
            state           => $state,
            display         => $view,
            order           => $order,
            state_intro     => addptags($stateinfo->{writeup}),
            state_writeup   => $state_writeup,
            cities          => $places,
            min_cost        => $min_cost,
            max_cost        => $max_cost,
            min_duration    => $min_duration,
            max_duration    => $max_duration,
        );
    }

    return $self->render(
        template          => 'tours',
        metatags          => TravellersPalm::Database::General::metatags(TAILOR, $self),
        country           => $destination,
        itineraries       => $itineraries,
        tripideas         => TravellersPalm::Database::Themes::themes('TRIPIDEAS', $self),
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
        special_interests => $webtexts->{190},
        regions           => $regions,
        currency          => $session_currency,
    );
}

# -----------------------------
# Single itinerary route
# -----------------------------
sub route_itinerary ($self) {
    my $req         = $self->req;
    my $destination = $self->stash('destination');
    my $tour        = $self->stash('tour');
    my $option      = $self->stash('option');

    my $itinerary = itinerary($tour);
    return $self->render(
        template => 'special_404',
        message  => "$tour has been misspelled or is not on file.",
        url      => $req->url->path,
    ) unless ref $itinerary eq 'HASH';

    my $cost        = TravellersPalm::Database::Itineraries::itinerary_cost($itinerary->{fixeditin_id}, $session_currency, $self);
    my $startcity   = $itinerary->{startcity} ? TravellersPalm::Database::Cities::city($itinerary->{startcity}, $self) : '';
    my $endcity     = TravellersPalm::Database::Cities::city($itinerary->{endcity}, $self);
    my $inclusions  = $itinerary->{inclusions};
    my $itin        = $itinerary->{itinerary};
    my $ourtime     = ourtime();

    $inclusions =~ s/\{/<br><h4>/g;
    $inclusions =~ s/\}/<\/h4>/g;
    $itin       =~ s/\{/<br><b>/g;

    my $webtexts = TravellersPalm::Database::General::webtext_multi([118, 176, 73, 184, 185], $self);

    my $crumb = sprintf(
        "<li>Destinations</li><li><a href='%s/destinations/%s'>%s</a></li>",
        $req->url->base,
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
        tours           => $startcity ? TravellersPalm::Database::Itineraries::similartours($startcity->{cities_id}, $session_currency, $self) : [],
        days            => TravellersPalm::Database::General::daybyday($tour, $self),
        places          => TravellersPalm::Database::Itineraries::placesyouwillvisit($tour, $self),
        accommodation   => TravellersPalm::Database::Itineraries::youraccommodation($tour, $self),
        ourtime         => $ourtime->strftime('%H:%M'),
        ourdate         => $ourtime->strftime('%d %B,%Y'),
        timediff        => 0,
        pathname        => $option,
        crumb           => $crumb,
        tweak           => $webtexts->{118},
        need_help       => $webtexts->{176},
        plan_your_trip  => $webtexts->{73},
        plan_and_refine => $webtexts->{184},
        arrangements    => $webtexts->{185},
        page_title      => $itinerary->{title},
    );
}

1;
