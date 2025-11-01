package TravellersPalm::Controller::StaticPages;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use TravellersPalm::Controller::Utils qw(last_path_segment);
use TravellersPalm::Functions qw(email_request user_email);

=head1 NAME

TravellersPalm::Controller::StaticPages - Static and informational pages

=head1 DESCRIPTION

Handles about, before you go, policies, FAQ, site map, sustainable tourism, testimonials, travel ideas, what to expect, and why travel with us pages.

=cut

sub about ($self) {
    my $tags = TravellersPalm::Database::General::metatags(last_path_segment($self), $self);
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

sub before_you_go ($self) {
    my $tags = TravellersPalm::Database::General::metatags(last_path_segment($self), $self);
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

sub faq ($self) {
    my $tags = TravellersPalm::Database::General::metatags(last_path_segment($self), $self);
    $self->render(
        template => 'faq',
        metatags => $tags,
    );
}

sub policies ($self) {
    my $tags = TravellersPalm::Database::General::metatags(last_path_segment($self), $self);
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

sub search_results ($self) {
    my $tags = TravellersPalm::Database::General::metatags(last_path_segment($self), $self);
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

sub site_map ($self) {
    my $tags     = TravellersPalm::Database::General::metatags(last_path_segment($self), $self);
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

sub sustainable_tourism ($self) {
    my $tags        = TravellersPalm::Database::General::metatags(last_path_segment($self), $self);
    my $sustainable = TravellersPalm::Database::General::webtext(13, $self);
    $self->render(
        template    => 'sustainable_tourism',
        metatags    => $tags,
        sustainable => $sustainable,
        crumb       => '<li class="active">'.$sustainable->{title}.'</li>',
        page_title  => $sustainable->{title},
    );
}

sub testimonials ($self) {
    my $tags = TravellersPalm::Database::General::metatags(last_path_segment($self), $self);
    $self->render(
        template    => 'testimonials',
        metatags    => $tags,
        page_title  => 'Testimonials',
        crumb       => '<li><a href="[% request.uri_base %]/about-us">About us</a></li>
                        <li class="active">Testimonials</li>',
    );
}

sub travel_ideas ($self) {
    my $tags = TravellersPalm::Database::General::metatags(last_path_segment($self), $self);
    $self->render(
        template    => 'travel_ideas',
        metatags    => $tags,
        page_title  => 'Travel Ideas',
        crumb       => '<li class="active">Travel Ideas</li>',
    );
}

sub what_to_expect ($self) {
    my $tags = TravellersPalm::Database::General::metatags(last_path_segment($self), $self);
    $self->render(
        template    => 'what_to_expect',
        metatags    => $tags,
        page_title  => 'What to Expect',
        crumb       => '<li class="active">What to Expect</li>',
    );
}

sub why_travel_with_us ($self) {
    my $tags = TravellersPalm::Database::General::metatags(last_path_segment($self), $self);
    $self->render(
        template    => 'why_travel_with_us',
        metatags    => $tags,
        page_title  => 'Why Travel With Us',
        crumb       => '<li class="active">Why Travel With Us</li>',
    );
}

# Home page and enquiry methods
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

    email_request($params, $self);

    $self->render(
        template => 'enquiry_thankyou',
        metatags => $tags,
        subject  => $params->{subject},
        email    => $email,
    );
}


1;

__END__

=head1 NAME

TravellersPalm::Controller::StaticPages - Static and informational pages

=head1 DESCRIPTION

Handles about, before you go, policies, FAQ, site map, sustainable tourism, testimonials, travel ideas, what to expect, and why travel with us pages.

=head1 AUTHOR

Travellers Palm Team

=head1 LICENSE

See the main project LICENSE file.

=cut
