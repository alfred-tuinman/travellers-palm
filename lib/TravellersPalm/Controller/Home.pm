package TravellersPalm::Controller::Home;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use TravellersPalm::Functions qw(email_request user_is_registered user_email webtext);
use TravellersPalm::Database::Themes qw(themes);
use TravellersPalm::Database::Cities qw(totalcities);
use TravellersPalm::Database::Itineraries qw(totalitineraries);
use TravellersPalm::Database::General qw(metatags web webpages totaltrains);
use Data::Dumper;

# → home page
sub index ($self) {
    my $page = (split '/', $self->req->url->path)[-1];

    my $tags = metatags($page);
    my $slidetext = web(163);

    my @slides = $slidetext->{writeup} ? split /\n/, $slidetext->{writeup} : ();
    unshift @slides, 'dummy item';

    $self->render(
        template             => 'home',
        metatags             => webpages(6),
        themes               => themes('LIMIT'),
        tripideas            => themes('TRIPIDEAS'),
        country              => 'india',
        slides               => \@slides,
        the_travel_experts1  => webtext(119),
        the_travel_experts2  => webtext(120),
        the_travel_experts3  => webtext(121),
        tailor_made_tours    => webtext(187),
        mini_itineraries     => webtext(188),
        best_places_to_visit => webtext(189),
        about                => webtext(60),
        home                 => 1,
    );
}

# → about page
sub about ($self) {
    my $tags = metatags((split '/', $self->req->url->path)[-1]);

    $self->render(
        template               => 'about',
        metatags               => $tags,
        totalcities            => totalcities(),
        totalitineraries       => totalitineraries(),
        totaltrains            => totaltrains(),
        intro                  => webtext(9),
        philosophy             => webtext(170),
        sustainable_tourism    => webtext(171),
        responsible_tourism    => webtext(172),
        meet_the_team          => webtext(31),
        why_travel_with_us     => webtext(12),
        what_is_travellers_palm=> webtext(8),
        hans                   => webtext(164),
        sucheta                => webtext(165),
        phil                   => webtext(166),
        shalome                => webtext(167),
        crumb                  => '<li class="active">About Us</li>',
        page_title             => 'About Us',
    );
}

# → before_you_go page
sub before_you_go ($self) {
    my $tags = metatags((split '/', $self->req->url->path)[-1]);

    $self->render(
        template       => 'before_you_go',
        metatags       => $tags,
        before_you_go  => webtext(17),
        getting_ready  => webtext(168),
        right_attitude => webtext(169),
        page_title     => 'Before You Go',
        crumb          => '<li class="active">Before You Go</li>',
    );
}

# → contact form
sub contact_us ($self) {
    my $params = $self->req->params->to_hash;
    my $error = 0;

    if ($self->req->method eq 'POST') {
        my $ok = email_request($params);
        $error = $ok ? 0 : 1;
    }

    $self->render(
        template => 'contact',
        error    => $error,
        %$params,
    );
}

# → enquiry page
sub get_enquiry ($self) {
    my $email = user_is_registered() ? user_email() : "";
    my $tags  = metatags((split '/', $self->req->url->path)[-1]);

    $self->render(
        template => 'enquiry',
        metatags => $tags,
        email    => $email,
    );
}

sub post_enquiry ($self) {
    my $email  = user_is_registered() ? user_email() : "";
    my $tags   = metatags((split '/', $self->req->url->path)[-1]);
    my $params = $self->req->params->to_hash;

    email_request($params);

    $self->render(
        template => 'enquiry_thankyou',
        metatags => $tags,
        subject  => $params->{subject},
        email    => $email,
    );
}

# → faq page
sub faq ($self) {
    my $tags = metatags((split '/', $self->req->url->path)[-1]);

    $self->render(
        template => 'faq',
        metatags => $tags,
    );
}

# → policies page
sub policies ($self) {
    my @fields = map { webtext($_) } (124..146, 191, 208);
    my $tags = metatags((split '/', $self->req->url->path)[-1]);

    $self->render(
        template   => 'policies',
        metatags   => $tags,
        conditions => webtext(15),
        terms      => webtext(35),
        privacy    => webtext(16),
        fields     => \@fields,
        about      => webtext(208),
        crumb      => '<li class="active">Our Policies</li>',
        page_title => 'Our Policies',
    );
}

# → search results page
sub search_results ($self) {
    my $tags = metatags((split '/', $self->req->url->path)[-1]);

    $self->render(
        template             => 'search_results',
        metatags             => $tags,
        why_travel_with_us   => webtext(12),
        extensive_knowledge  => webtext(153),
        highly_selective     => webtext(154),
        unbiased             => webtext(155),
        unrivalled_coverage  => webtext(156),
        in_charge            => webtext(157),
        value_for_money      => webtext(158),
        page_title           => 'Search Results',
        crumb                => '<li class="active">Search Results</li>',
    );
}

# → site map page
sub site_map ($self) {
    my $tags = metatags((split '/', $self->req->url->path)[-1]);
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

# → state page
sub state ($self) {
    my $tags = metatags((split '/', $self->req->url->path)[-1]);

    $self->render(
        template => 'state',
        metatags => $tags,
    );
}

# → sustainable tourism page
sub sustainable_tourism ($self) {
    my $tags       = metatags((split '/', $self->req->url->path)[-1]);
    my $sustainable = webtext(13);

    $self->render(
        template    => 'sustainable_tourism',
        metatags    => $tags,
        sustainable => $sustainable,
        crumb       => '<li class="active">'.$sustainable->{title}.'</li>',
        page_title  => $sustainable->{title},
    );
}

# → testimonials page
sub testimonials ($self) {
    my $tags = metatags((split '/', $self->req->url->path)[-1]);

    $self->render(
        template    => 'testimonials',
        metatags    => $tags,
        page_title  => 'Testimonials',
        crumb       => '<li><a href="[% request.uri_base %]/about-us">About us</a></li>
                        <li class="active">Testimonials</li>',
    );
}

# → travel ideas
sub travel_ideas ($self) {
    my $tags = metatags((split '/', $self->req->url->path)[-1]);

    $self->render(
        template    => 'travel_ideas',
        metatags    => $tags,
        page_title  => 'Travel Ideas',
        crumb       => '<li class="active">Travel Ideas</li>',
    );
}

# → what to expect
sub what_to_expect ($self) {
    my $tags   = metatags((split '/', $self->req->url->path)[-1]);
    my $expect = webtext(21);
    my $title  = $expect->{title} // 'What to Expect';

    $self->render(
        template        => 'what_to_expect',
        metatags        => $tags,
        what_to_expect  => $expect,
        special_hotels  => webtext(147),
        eat_drink       => webtext(148),
        private_car     => webtext(149),
        travel_by_train => webtext(150),
        fly_in_comfort  => webtext(151),
        delays          => webtext(152),
        before_you_go   => webtext(17),
        getting_ready   => webtext(168),
        right_attitude  => webtext(169),
        crumb           => '<li class="active">'.$title.'</li>',
        page_title      => $title,
    );
}

# → why travel with us
sub why_travel_with_us ($self) {
    my $tags = metatags((split '/', $self->req->url->path)[-1]);

    $self->render(
        template => 'why_travel_with_us',
        metatags => $tags,
    );
}

1;
