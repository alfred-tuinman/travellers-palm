package TravellersPalm::Controller::Destinations;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use TravellersPalm::Constants qw(:all);
use TravellersPalm::Functions qw(addptags boldify email_request ourtime url2text);

# Ensure modules are loaded
BEGIN { 
  require TravellersPalm::Database::General; 
  require TravellersPalm::Database::States; 
}

# -----------------------------
# Utility to get last path segment
# -----------------------------
sub _last_path_segment ($self) {
    my $req  = $self->req;
    my $path = $req->url->path->to_string;
    my ($last) = reverse grep { length } split('/', $path);
    return $last;
}

sub regions ($self) {
    my $country = $self->stash('country'); 
    my $content = TravellersPalm::Database::General::webtext(7, $self);
    my $webpage = TravellersPalm::Database::General::webpages(11, $self);
  
    my $crumb    = "<li>Destinations</li>
                    <li><a href='".$self->req."/destinations/$country'>" . url2text($country) . "</a></li>
                    <li class='active'>Regions</li>";

    $self->render(
        template   => 'regions',
        metatags   => TravellersPalm::Database::General::metatags(REGIONS, $self),
        writeup    => boldify( addptags( $content->{writeup} ) ),
        page_title => url2text(REGIONS),
        regions    => TravellersPalm::Database::General::regions($self),
        crumb      => $crumb,
        pathname   => REGIONS,
        country    => $country,
    );
};

sub states ($self) {

    my $crumb    = "<li>Destinations</li>
                 <li><a href='".$self->req."/destinations/india'>India</a></li>
                 <li class='active'>States</li>";

    $self->render(
        template        => 'states',
        metatags        => TravellersPalm::Database::General::metatags(STATES, $self),
        writeup         => boldify( TravellersPalm::Database::General::webtext(122, $self) ),
        states          => TravellersPalm::Database::States::states('IN','order',$self),
        country         => 'India',
        random          => 1 + int( rand 35 ),
        crumb           => $crumb,
        call            => TravellersPalm::Database::General::webtext(175, $self),
        page_title      => url2text(STATES),
        pathname        => STATES,
    );
};

sub themes($self) {
    my $country = $self->stash('country'); 

    my $crumb = "<li>Destinations</li>
                 <li><a href='".$self->req."/destinations/$country'>" . url2text($country) . "</a></li>
                 <li class='active'>Themes</a></li>";

    $self->render (
        template => 'themes',
        metatags   => TravellersPalm::Database::General::metatags(THEMES, $self),
        themes     => TravellersPalm::Database::General::themes($self),
        crumb      => $crumb,
        pathname   => THEMES,
        page_title => url2text(THEMES),
        country    => $country,
    );
};



# -----------------------------
# Show state list or single destination
# -----------------------------
sub show_state_list ($self) {
    my $req        = $self->req;
    my $state_name = $self->stash('destination') || '';
    my $tags       = TravellersPalm::Database::General::metatags($self->_last_path_segment, $self);

    # Batch fetch webtexts for this page
    my @ids      = (201,202,203,204); # adjust IDs as needed
    my $webtexts = TravellersPalm::Database::General::webtext_multi(\@ids, $self);

    # Fetch themes and destinations for this state
    my $themes = TravellersPalm::Database::Themes::themes('STATE', $self);
    my $cities = TravellersPalm::Database::Cities::cities_in_state($state_name, $self);

    $self->render(
        template => 'destinations/state_list',
        metatags => $tags,
        state    => $state_name,
        themes   => $themes,
        cities   => $cities,
        intro    => $webtexts->{201},
        tips     => $webtexts->{202},
        gallery  => $webtexts->{203},
        faq      => $webtexts->{204},
    );
}

# -----------------------------
# Single destination page
# -----------------------------
sub show_destination ($self) {
    my $req         = $self->req;
    my $destination = $self->stash('destination') || '';
    my $tags        = TravellersPalm::Database::General::metatags($self->_last_path_segment, $self);

    # Batch fetch webtexts for this destination
    my @ids      = (301,302,303,304,305,306); # adjust IDs for content
    my $webtexts = TravellersPalm::Database::General::webtext_multi(\@ids, $self);

    # Fetch itineraries and related destinations
    my $itineraries = TravellersPalm::Database::Itineraries::by_destination($destination, $self);
    my $related     = TravellersPalm::Database::Cities::related_destinations($destination, $self);

    $self->render(
        template      => 'destinations/single',
        metatags      => $tags,
        destination   => $destination,
        intro         => $webtexts->{301},
        history       => $webtexts->{302},
        culture       => $webtexts->{303},
        activities    => $webtexts->{304},
        accommodation => $webtexts->{305},
        travel_tips   => $webtexts->{306},
        itineraries   => $itineraries,
        related       => $related,
    );
}

1;
