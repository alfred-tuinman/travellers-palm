package TravellersPalm::Controller::Destinations;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use TravellersPalm::Functions qw(boldify email_request ourtime url2text webtext);
use TravellersPalm::Database::General qw(metatags); 
use TravellersPalm::Database::States qw(states);
use TravellersPalm::Database::Themes qw(themes);
use TravellersPalm::Constants qw(:all);

# -------------------------------
# Controller Actions
# -------------------------------

# → single destination page
sub show_destination ($self) {
    my $destination = $self->param('destination');
    my $crumb = "<li>Destinations</li><li class='active'>" . url2text($destination) . "</li>";

    $self->render(
        template    => 'destination',
        metatags    => TravellersPalm::Database::General::metatags($self, $destination),
        destination => $destination,
        crumb       => $crumb,
        page_title  => url2text($destination),
        writeup     => webtext(7),
    );
}

# → tailor listings
sub show_tailor ($self) {
    my ($destination, $arg) = @{ $self->stash('splat') // [] };
    my @arg = ref $arg eq 'ARRAY' ? @$arg : ();
    my $view  = $arg[0];
    my $order = $arg[1] // 'popularity';

    if ($view =~ /^(grid|block|list)$/) {
        TravellersPalm::FunctionsRouter::route_listing($destination, TAILOR(), $view, $order);
    } else {
        TravellersPalm::FunctionsRouter::route_itinerary($destination, $view, TAILOR());
    }
}

# → regions overview
sub show_region_list ($self) {
    my ($destination) = @{ $self->stash('splat') // [] };
    my $content = webtext(7);

    my $crumb = "<li>Destinations</li>"
        . "<li><a href='" . $self->req->url->base . "/destinations/$destination'>"
        . url2text($destination) . "</a></li>"
        . "<li class='active'>" . url2text(REGIONS()) . "</li>";

    $self->render(
        template   => 'regions',
        metatags   => TravellersPalm::Database::General::metatags($self,REGION()),
        writeup    => boldify($content->{writeup}),
        page_title => url2text(REGIONS()),
        regions    => regions(),
        crumb      => $crumb,
        pathname   => REGIONS(),
        country    => $destination,
    );
}

# → region-specific listings
sub show_region_detail ($self) {
    my ($destination, $arg) = @{ $self->stash('splat') // [] };
    my @arg = ref $arg eq 'ARRAY' ? @$arg : ();

    my $region = $arg[0];
    my $view   = $arg[1] // 'list';
    my $order  = $arg[2] // 'popularity';

    if ($view =~ /^(grid|block|list)$/) {
        TravellersPalm::FunctionsRouter::route_listing($destination, REGIONS(), $view, $order, $region);
    } else {
        TravellersPalm::FunctionsRouter::route_itinerary($destination, $view, REGIONS(), $region);
    }
}

# → state overview
sub show_state_list ($self) {
    my ($destination) = @{ $self->stash('splat') // [] };
    my $states = TravellersPalm::Database::States::states($self,$destination);
    my @filtered = grep { $_->{state} } @$states;

    my $crumb = "<li>Destinations</li>"
        . "<li><a href='" . $self->req->url->base . "/destinations/$destination'>"
        . url2text($destination) . "</a></li>"
        . "<li class='active'>" . url2text(STATES()) . "</li>";

    $self->render(
        template   => 'state',
        metatags   => TravellersPalm::Database::General::metatags($self,STATES()),
        writeup    => boldify(webtext(122)),
        states     => \@filtered,
        country    => $destination,
        random     => 1 + int(rand 35),
        crumb      => $crumb,
        call       => webtext(175),
        page_title => url2text(STATES()),
        pathname   => STATES(),
    );
}

# → state-specific listings
sub show_state_detail ($self) {
    my ($destination, $arg) = @{ $self->stash('splat') // [] };
    my @arg = ref $arg eq 'ARRAY' ? @$arg : ();
    my $state = $arg[0];
    my $view  = $arg[1] // 'list';
    my $order = $arg[2] // 'popularity';

    if ($view =~ /^(grid|block|list)$/) {
        TravellersPalm::FunctionsRouter::route_listing($destination, STATES(), $view, $order, $state);
    } else {
        TravellersPalm::FunctionsRouter::route_itinerary($destination, $view, STATES(), $state);
    }
}

# → themes overview
sub show_theme_list ($self) {
    my ($destination) = @{ $self->stash('splat') // [] };
    my $crumb = "<li>Destinations</li>"
        . "<li><a href='" . $self->req->url->base . "/destinations/$destination'>"
        . url2text($destination) . "</a></li>"
        . "<li class='active'>" . url2text(THEMES()) . "</li>";

    $self->render(
        template   => 'theme',
        metatags   => TravellersPalm::Database::General::metatags($self,THEMES()),
        themes     => TravellersPalm::Database::Themes::themes($self),
        crumb      => $crumb,
        pathname   => THEMES(),
        page_title => url2text(THEMES()),
        country    => $destination,
    );
}

# → theme-specific listings
sub show_theme_detail ($self) {
    my ($destination, $arg) = @{ $self->stash('splat') // [] };
    my @arg = ref $arg eq 'ARRAY' ? @$arg : ();

    my $theme = $arg[0];
    my $view  = $arg[1] // 'list';
    my $order = $arg[2] // 'popularity';

    if ($view =~ /^(grid|block|list)$/) {
        TravellersPalm::FunctionsRouter::route_listing($destination, THEMES(), $view, $order, $theme);
    } else {
        TravellersPalm::FunctionsRouter::route_itinerary($destination, $view, THEMES(), $theme);
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

    $self->render(
        template   => $template,
        metatags   => TravellersPalm::Database::General::metatags($self,(split '/', $self->req->url->path->to_string)[-1]),
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

1;
