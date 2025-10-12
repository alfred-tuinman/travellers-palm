package TravellersPalm::Controller::Itineraries;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use POSIX qw(strftime);
use TravellersPalm::Constants;

my $session_currency = 'USD';

# /destinations/:destination/:option/:view/:order/:region
sub route_listing ($self) {
  my $destination = $self->param('destination');
  my $option      = $self->param('option');
  my $view        = $self->param('view');
  my $order       = $self->param('order');
  my $region      = $self->param('region');

  my $crumb = qq{
    <li>Destinations</li>
    <li><a href="@{[$self->req->url->base]}destinations/$destination">@{[url2text($destination)]}</a></li>
  };

  my ($itineraries, $states, $stateinfo, $filter, $regions, $regioninfo);

  if ($option eq TAILOR()) {
    $itineraries = TravellersPalm::Database::Itineraries::itineraries(
      option => 'itin', 
      currency => $session_currency, 
      order => $order
    );
    $filter      = 'tailor';
    $crumb      .= "<li class='active'>" . url2text(TAILOR()) . "</li>";
  }
  elsif ($option eq REGIONS()) {
    $itineraries = TravellersPalm::Database::General::modules(
      region => $region, 
      currency => $session_currency, 
      order => $order
    );
    $regioninfo  = TravellersPalm::Database::General::regionsurl($region);
    $regions     = TravellersPalm::Database::General::regions();
    $filter      = 'regions';
    $crumb      .= "<li class='active'>" . $regioninfo->{title} . "</li>";
  }

elsif ($option eq STATES()) {
    my $state = $region;
    my $stateinfo = TravellersPalm::Database::States::statesurl($state);
    my $itineraries = TravellersPalm::Database::Itineraries::toursinstate(
        state    => $state,
        currency => $session_currency,
        order    => $order
    );
    my $states = TravellersPalm::Database::States::states($destination);
    my $filter = 'states';

    my $crumb .= sprintf(
        "<li><a href='%s/destinations/%s/%s'>%s</a></li>
         <li class='active'>%s</li>",
        $self->req->url->base,
        $destination,
        STATES(),
        url2text(STATES()),
        url2text($state)
    );
}

  # compute min/max
  my ($min_duration, $max_duration, $min_cost, $max_cost) = (30, 0, 1_000_000, 0);
  for my $trip (@$itineraries) {
    $min_duration = $trip->{numdays} if $trip->{numdays} < $min_duration;
    $max_duration = $trip->{numdays} if $trip->{numdays} > $max_duration;
    $min_cost     = $trip->{cost}    if $trip->{cost}    < $min_cost;
    $max_cost     = $trip->{cost}    if $trip->{cost}    > $max_cost;
  }

  $self->render(
    template     => $option eq STATES() ? 'states' : 'tours',
    itineraries  => $itineraries,
    crumb        => $crumb,
    filter       => $filter,
    view         => $view,
    order        => $order,
    min_duration => $min_duration,
    max_duration => $max_duration,
    min_cost     => $min_cost,
    max_cost     => $max_cost,
    country      => $destination,
    regioninfo   => $regioninfo,
    regions      => $regions,
  );
}

# /destinations/:destination/:tour/:option/:theme
sub route_listing ($self, $destination, $option, $view = undef, $order = undef, $region = undef) {
    # $destination = $self->param('destination');
    # $option      = $self->param('option');
    $view = $view // 'list';
    $order = $order // 'days';
    
    my $crumb = sprintf(
        "<li>Destinations</li><li><a href='%s/destinations/%s'>%s</a></li>",
        $self->req->url->base,
        $destination,
        url2text($destination)
    );

    my ($itineraries, $states, $state, $stateinfo, $state_writeup, $regioninfo, $places, $filter, $regions);

    if ($option eq TAILOR()) {
        $itineraries = TravellersPalm::Database::Itineraries::itineraries(
          option => 'itin', 
          currency => $session_currency, 
          order => $order
        );
        $filter      = 'tailor';
        $crumb      .= "<li class='active'>" . url2text(TAILOR()) . "</li>";
    }
    elsif ($option eq REGIONS()) {
        $itineraries = TravellersPalm::Database::General::modules(
          region => $region, 
          currency => $session_currency, 
          order => $order
        );
        $regioninfo  = TravellersPalm::Database::Regions::regionsurl($region);
        $regions     = TravellersPalm::Database::Regions::regions();
        $filter      = 'regions';

        my $metatags = {
            meta_descr    => $regioninfo->{introduction},
            meta_keywords => $regioninfo->{meta_keywords},
            meta_title    => $regioninfo->{oneliner},
        };

        $crumb .= sprintf(
            "<li><a href='%s/destinations/%s/%s'>%s</a></li><li class='active'>%s</li>",
            $self->req->url->base,
            $destination,
            REGIONS(),
            url2text(REGIONS()),
            $regioninfo->{title}
        );
    }
    elsif ($option eq STATES()) {
        $state       = $region;
        $stateinfo   = TravellersPalm::Database::States::statesurl($state);
        $itineraries = TravellersPalm::Database::States::toursinstate(
          state => $state, 
          currency => $session_currency, 
          order => $order
        );
        $states      = TravellersPalm::Database::States::states($destination);
        $filter      = 'states';

        $crumb .= sprintf(
            "<li><a href='%s/destinations/%s/%s'>%s</a></li><li class='active'>%s</li>",
            $self->req->url->base,
            $destination,
            STATES(),
            url2text(STATES()),
            url2text($state)
        );

        ($state_writeup, $places) = linkify(addptags($stateinfo->{webwriteup}));
    }

    # min/max for sliders
    my ($min_duration, $max_duration, $min_cost, $max_cost) = (30, 0, 1_000_000, 0);
    for my $trip (@$itineraries) {
        $min_duration = $trip->{numdays} if $trip->{numdays} < $min_duration;
        $max_duration = $trip->{numdays} if $trip->{numdays} > $max_duration;
        $min_cost     = $trip->{cost}    if $trip->{cost}    < $min_cost;
        $max_cost     = $trip->{cost}    if $trip->{cost}    > $max_cost;
    }

    if ($option eq STATES()) {
        # optional city popups via Template Toolkit
        my $tt = Template->new({ RELATIVE => 1, INCLUDE_PATH => ["../templates"] });
        for my $city (@$places) {
            my $vars = {
                items      => TravellersPalm::Database::Images::images($city->{cities_id}, 'city', 'large'),
                imagepath  => 'city',
                uribase    => $self->req->url->base,
                webwriteup => addptags($city->{writeup}),
                cityinfo   => TravellersPalm::Database::Cities::city($city->{cities_id}),
            };
            my $output = "../public/ajax/slideshow-city-$city->{cities_id}.html";
            # $tt->process('slideshowcity.tt', $vars, $output) unless -f $output && -M $output < 30;
        }

        return $self->render(
            template      => 'states',
            metatags      => $stateinfo,
            country       => $destination,
            itineraries   => $itineraries,
            states        => $states,
            crumb         => $crumb,
            stateinfo     => $stateinfo,
            filter        => $filter,
            pathname      => STATES(),
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
    else {
        return $self->render(
            template          => 'tours',
            metatags          => metatags(TAILOR()),
            country           => $destination,
            itineraries       => $itineraries,
            tripideas         => TravellersPalm::Database::Themes::themes('TRIPIDEAS'),
            crumb             => $crumb,
            filter            => $filter,
            display           => $view,
            pathname          => $option,
            order             => $order,
            min_cost          => $min_cost,
            max_cost          => $max_cost,
            min_duration      => $min_duration,
            max_duration      => $max_duration,
            page_title        => ($option eq REGIONS()) ? $regioninfo->{title} : url2text($option),
            regionname        => $region,
            special_interests => webtext(190),
            regions           => $regions,
            currency          => $session_currency,
        );
    }
}

sub route_itinerary ($self,$destination,$tour,$option = undef,$theme = undef) {
    my $itinerary = TravellersPalm::Database::itinerary($tour);

    unless (ref $itinerary eq 'HASH') {
        return $self->render(
            template => 'special_404',
            message  => "$tour has been misspelled and/or is not on file.",
            url      => $self->req->url->path,
        );
    }

    my $cost = TravellersPalm::Database::itinerary_cost(
      $itinerary->{fixeditin_id}, 
      $session_currency
    );
    my $startcity     = $itinerary->{startcity} ? city($itinerary->{startcity}) : '';
    my $endcity       = TravellersPalm::Database::city($itinerary->{endcity});
    my $category      = $itinerary->{readytours} ? 'ready tour' : 'module';
    my $inclusions    = $itinerary->{inclusions};
    my $ourtime       = ourtime();
    my $daybyday      = TravellersPalm::Database::daybyday($tour);
    my $accommodation = TravellersPalm::Database::youraccommodation($tour);
    my $similartours  = $startcity ? TravellersPalm::Database::similartours($startcity->{cities_id}, $session_currency) : [];
    my $placesyou     = TravellersPalm::Database::placesyouwillvisit($tour);
    my $itin          = $itinerary->{itinerary};

    $inclusions =~ s/\{/<br><h4>/g;
    $inclusions =~ s/\}/<\/h4>/g;
    $itin =~ s/\{/<br><b>/g;

    my $tt = Template->new({
        RELATIVE     => 0,
        INCLUDE_PATH => $self->app->config->{root} ? $self->app->config->{root}.'/templates'
                                                   : $self->app->home->child('templates')->to_string,
    });

    my $imagedir = 'http://images.travellers-palm.com';

    # city popups
    for my $city (@$daybyday) {
        my $vars = {
            items      => images($city->{cities_id}, 'city', 'large'),
            imagepath  => 'city',
            uribase    => $self->req->url->base,
            webwriteup => addptags($city->{writeup}),
            cityinfo   => city($city->{cities_id}),
            IMAGE      => $imagedir,
        };
        my $output = $self->app->config->{root}.'/public/ajax/slideshow-city-' . $city->{cities_id} . '.html';
        $tt->process('slideshowcity.tt', $vars, $output) unless -f $output && -M $output < 30;
    }

    # tour popup
    my $vars = {
        items     => TravellersPalm::Database::images($itinerary->{tourname}, $category, 'large'),
        imagepath => $itinerary->{readytours} ? 'tour' : 'module',
        uribase   => $self->req->url->base,
        IMAGE     => $imagedir,
    };
    my $output = $self->app->config->{root}.'/public/ajax/slideshow-tour-' . $itinerary->{fixeditin_id} . '.html';
    $tt->process('slideshowtour.tt', $vars, $output) unless -f $output && -M $output < 30;

    # hotel popups
    for my $hotel (@$accommodation) {
        my $vars = {
            items     => TravellersPalm::Database::images($hotel->{hotel_id}, 'hotel', 'large'),
            imagepath => 'hotel',
            uribase   => $self->req->url->base,
            writeup   => addptags($hotel->{description}),
            hotelinfo => TravellersPalm::Database::hotel($hotel->{hotel_id}),
            IMAGE     => $imagedir,
        };
        my $output = $self->app->config->{root}.'/public/ajax/slideshow-hotel-' . $hotel->{hotel_id} . '.html';
        $tt->process('slideshowhotel.tt', $vars, $output) unless -f $output && -M $output < 30;
    }

    # breadcrumb and image logic
    my ($themeinfo, $regioninfo, $image);
    my $crumb = sprintf(
        "<li>Destinations</li><li><a href='%s/destinations/%s'>%s</a></li>",
        $self->req->url->base,
        $destination,
        url2text($destination),
    );

    if ($option eq TAILOR()) {
        $image = "tour_$itinerary->{tourname}_large_1.jpg";
        $crumb .= "<li><a href='".$self->req->url->base."/destinations/$destination/".TAILOR()."/list'>".url2text(TAILOR())."</a></li>
                   <li class='active'>$itinerary->{title}</li>";
    }
    elsif ($option eq THEMES()) {
        $themeinfo = themes_url($theme);
        $image     = ($itinerary->{readytours} ? 'tour' : 'mod') . "_$itinerary->{tourname}_large_1.jpg";
        $crumb .= "<li><a href='".$self->req->url->base."/destinations/$destination/".THEMES()."'>".url2text(THEMES())."</a></li>
                   <li><a href='".$self->req->url->base."/destinations/$destination/".THEMES()."/$theme'>$themeinfo->{pagename}</a></li>
                   <li class='active'>$itinerary->{title}</li>";
    }
    elsif ($option eq REGIONS()) {
        $regioninfo = TravellersPalm::Database::regionsurl($theme);
        $image = "mod_$itinerary->{tourname}_large_1.jpg";
        $crumb .= "<li><a href='".$self->req->url->base."/destinations/$destination/".REGIONS()."'>".url2text(REGIONS())."</a></li>
                   <li><a href='".$self->req->url->base."/destinations/$destination/".REGIONS()."/$regioninfo->{url}/list'>$regioninfo->{title}</a></li>
                   <li class='active'>$itinerary->{title}</li>";
    }
    elsif ($option eq STATES()) {
        $image = ($itinerary->{readytours} ? 'tour' : 'mod') . "_$itinerary->{tourname}_large_1.jpg";
        $crumb .= "<li><a href='".$self->req->url->base."/destinations/$destination/".STATES()."'>".url2text(STATES())."</a></li>
                   <li><a href='".$self->req->url->base."/destinations/$destination/".STATES()."/$theme/list'>".url2text($theme)."</a></li>
                   <li class='active'>$itinerary->{title}</li>";
    }

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
        image           => $image,
        tours           => $similartours,
        days            => $daybyday,
        places          => $placesyou,
        accommodation   => $accommodation,
        ourtime         => $ourtime->strftime('%H:%M'),
        ourdate         => $ourtime->strftime('%d %B,%Y'),
        timediff        => 0,
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
    );
}

1;
