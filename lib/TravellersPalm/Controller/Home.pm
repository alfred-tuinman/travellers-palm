package TravellersPalm::Controller::Home;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use TravellersPalm::Functions qw(email_request user_is_registered user_email);
use Data::Dumper;

BEGIN {
    require TravellersPalm::Database::General;
    require TravellersPalm::Database::Themes;
}

# -----------------------------
# Utility to get last path segment
# -----------------------------
sub _last_path_segment ($self) {
    my $req = $self->req;
    my $path = $req->url->path->to_string;
    my ($last) = reverse grep { length } split('/', $path);
    return $last;
}

# -----------------------------
# Home page
# -----------------------------
sub index ($self) {
    my $country   = $self->stash('country');  
    my $req       = $self->req;
    my $tags      = TravellersPalm::Database::General::metatags(6, $self);
    my $slidetext = TravellersPalm::Database::General::web(163, $self);
    my @slides    = $slidetext->{writeup} ? split /\n/, $slidetext->{writeup} : ();
    unshift @slides, 'dummy item';

    my @ids = (119,120,121,187,188,189,60);
    my $webtexts = TravellersPalm::Database::General::webtext_multi(\@ids, $self);

    $self->render(
        template             => 'home',
        metatags             => $tags,
        themes               => TravellersPalm::Database::Themes::themes('LIMIT', $self),
        tripideas            => TravellersPalm::Database::Themes::themes('TRIPIDEAS', $self),
        country              => 'india',
        slides               => \@slides,
        the_travel_experts1  => $webtexts->{119},
        the_travel_experts2  => $webtexts->{120},
        the_travel_experts3  => $webtexts->{121},
        tailor_made_tours    => $webtexts->{187},
        mini_itineraries     => $webtexts->{188},
        best_places_to_visit => $webtexts->{189},
        about                => $webtexts->{60},
        home                 => 1,
    );
}

# -----------------------------
# About page
# -----------------------------
sub about ($self) {
    my $req = $self->req;
    my $tags = TravellersPalm::Database::General::metatags($self->_last_path_segment, $self);

    my @ids = (9, 170, 171, 172, 8, 12, 31, 164, 165, 166, 167);
    my $webtexts = TravellersPalm::Database::General::webtext_multi(\@ids, $self);

    $self->render(
        template               => 'about',
        metatags               => $tags,
        intro                  => $webtexts->{9},
        philosophy             => $webtexts->{170},
        sustainable_tourism    => $webtexts->{171},
        responsible_tourism    => $webtexts->{172},
        what_is_travellers_palm=> $webtexts->{8},
        why_travel_with_us     => $webtexts->{12},
        meet_the_team          => $webtexts->{31},
        hans                   => $webtexts->{164},
        sucheta                => $webtexts->{165},
        phil                   => $webtexts->{166},
        shalome                => $webtexts->{167},
        totalcities            => TravellersPalm::Database::Cities::totalcities($self),
        totalitineraries       => TravellersPalm::Database::Itineraries::totalitineraries($self),
        totaltrains            => TravellersPalm::Database::Itineraries::totaltrains($self),
        crumb                  => '<li class="active">About Us</li>',
        page_title             => 'About Us',
    );
}

# -----------------------------
# Before You Go
# -----------------------------
sub before_you_go ($self) {
    my $req = $self->req;
    my $tags = TravellersPalm::Database::General::metatags($self->_last_path_segment, $self);

    my @ids = (17,168,169);
    my $webtexts = TravellersPalm::Database::General::webtext_multi(\@ids, $self);

    $self->render(
        template       => 'before_you_go',
        metatags       => $tags,
        before_you_go  => $webtexts->{17},
        getting_ready  => $webtexts->{168},
        right_attitude => $webtexts->{169},
        page_title     => 'Before You Go',
        crumb          => '<li class="active">Before You Go</li>',
    );
}

# -----------------------------
# Contact form
# -----------------------------
sub contact_us ($self) {
    my $req    = $self->req;
    my $params = $req->params->to_hash;
    my $error  = 0;

    if ($req->method eq 'POST') {
        $error = email_request($params) ? 0 : 1;
    }

    $self->render(
        template => 'contact',
        error    => $error,
        %$params,
    );
}

# -----------------------------
# Enquiry page
# -----------------------------
sub get_enquiry ($self) {
    my $req   = $self->req;
    my $email = TravellersPalm::Database::Users::user_is_registered($self) ? user_email() : "";
    my $tags  = TravellersPalm::Database::General::metatags($self->_last_path_segment, $self);

    $self->render(
        template => 'enquiry',
        metatags => $tags,
        email    => $email,
    );
}

sub post_enquiry ($self) {
    my $req    = $self->req;
    my $params = $req->params->to_hash;
    my $email  = TravellersPalm::Database::Users::user_is_registered($self) ? user_email() : "";
    my $tags   = TravellersPalm::Database::General::metatags($self->_last_path_segment, $self);

    email_request($params);

    $self->render(
        template => 'enquiry_thankyou',
        metatags => $tags,
        subject  => $params->{subject},
        email    => $email,
    );
}

# -----------------------------
# FAQ page
# -----------------------------
sub faq ($self) {
    my $req  = $self->req;
    my $tags = TravellersPalm::Database::General::metatags($self->_last_path_segment, $self);

    $self->render(
        template => 'faq',
        metatags => $tags,
    );
}

# -----------------------------
# Policies
# -----------------------------
sub policies ($self) {
    my $req  = $self->req;
    my $tags = TravellersPalm::Database::General::metatags($self->_last_path_segment, $self);

    my @field_ids = (124..146, 191, 208);
    my $fields = TravellersPalm::Database::General::webtext_multi(\@field_ids, $self);

    $self->render(
        template   => 'policies',
        metatags   => $tags,
        conditions => $fields->{15},
        terms      => $fields->{35},
        privacy    => $fields->{16},
        fields     => [ map { $fields->{$_} } @field_ids ],
        about      => $fields->{208},
        crumb      => '<li class="active">Our Policies</li>',
        page_title => 'Our Policies',
    );
}

# -----------------------------
# Search results
# -----------------------------
sub search_results ($self) {
    my $req  = $self->req;
    my $tags = TravellersPalm::Database::General::metatags($self->_last_path_segment, $self);

    my @ids = (12,153,154,155,156,157,158);
    my $webtexts = TravellersPalm::Database::General::webtext_multi(\@ids, $self);

    $self->render(
        template             => 'search_results',
        metatags             => $tags,
        why_travel_with_us   => $webtexts->{12},
        extensive_knowledge  => $webtexts->{153},
        highly_selective     => $webtexts->{154},
        unbiased             => $webtexts->{155},
        unrivalled_coverage  => $webtexts->{156},
        in_charge            => $webtexts->{157},
        value_for_money      => $webtexts->{158},
        page_title           => 'Search Results',
        crumb                => '<li class="active">Search Results</li>',
    );
}

# -----------------------------
# Site map
# -----------------------------
sub site_map ($self) {
    my $req      = $self->req;
    my $tags     = TravellersPalm::Database::General::metatags($self->_last_path_segment, $self);
    my $textfile = $self->config->{root}.'/url-report.txt';
    my @report;

    if (open(my $fh, '<:encoding(UTF-8)', $textfile)) {
        while (<$fh>) {
            chomp;
            next if /^$/;
            push @report, { url => $_ };
        }
        close $fh;
    }

    $self->render(
        template    => 'site_map',
        metatags    => $tags,
        report      => \@report,
        crumb       => '<li class="active">Sitemap</li>',
        page_title  => 'Sitemap',
    );
}

# -----------------------------
# Sustainable tourism
# -----------------------------
sub sustainable_tourism ($self) {
    my $req         = $self->req;
    my $tags        = TravellersPalm::Database::General::metatags($self->_last_path_segment, $self);
    my $sustainable = TravellersPalm::Database::General::webtext(13, $self);

    $self->render(
        template    => 'sustainable_tourism',
        metatags    => $tags,
        sustainable => $sustainable,
        crumb       => '<li class="active">'.$sustainable->{title}.'</li>',
        page_title  => $sustainable->{title},
    );
}

# -----------------------------
# Testimonials
# -----------------------------
sub testimonials ($self) {
    my $req  = $self->req;
    my $tags = TravellersPalm::Database::General::metatags($self->_last_path_segment, $self);

    $self->render(
        template    => 'testimonials',
        metatags    => $tags,
        page_title  => 'Testimonials',
        crumb       => '<li><a href="[% request.uri_base %]/about-us">About us</a></li>
                        <li class="active">Testimonials</li>',
    );
}

# -----------------------------
# Travel ideas
# -----------------------------
sub travel_ideas ($self) {
    my $req  = $self->req;
    my $tags = TravellersPalm::Database::General::metatags($self->_last_path_segment, $self);

    $self->render(
        template    => 'travel_ideas',
        metatags    => $tags,
        page_title  => 'Travel Ideas',
        crumb       => '<li class="active">Travel Ideas</li>',
    );
}

# -----------------------------
# What to expect
# -----------------------------
sub what_to_expect ($self) {
    my $req  = $self->req;
    my $tags = TravellersPalm::Database::General::metatags($self->_last_path_segment, $self);

    my @ids = (17,168,169,21,147,148,149,150,151,152);
    my $webtexts = TravellersPalm::Database::General::webtext_multi(\@ids, $self);

    my $expect = $webtexts->{21};
    my $title  = $expect->{title} // 'What to Expect';

    $self->render(
        template        => 'what_to_expect',
        metatags        => $tags,
        what_to_expect  => $webtexts->{21},
        special_hotels  => $webtexts->{147},
        eat_drink       => $webtexts->{148},
        private_car     => $webtexts->{149},
        travel_by_train => $webtexts->{150},
        fly_in_comfort  => $webtexts->{151},
        delays          => $webtexts->{152},
        before_you_go   => $webtexts->{17},
        getting_ready   => $webtexts->{168},
        right_attitude  => $webtexts->{169},
        crumb           => '<li class="active">'.$title.'</li>',
        page_title      => $title,
    );
}

# -----------------------------
# Why travel with us
# -----------------------------
sub why_travel_with_us ($self) {
    my $req  = $self->req;
    my $tags = TravellersPalm::Database::General::metatags($self->_last_path_segment, $self);

    $self->render(
        template => 'why_travel_with_us',
        metatags => $tags,
    );
}

1;
