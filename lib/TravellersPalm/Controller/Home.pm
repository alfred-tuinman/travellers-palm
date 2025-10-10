package TravellersPalm::Controller::Home;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use TravellersPalm::Functions qw(email_request webtext);
use Data::Dumper;

# $Data::Dumper::Indent = 1;   # pretty-print with indentation

# use TravellersPalm::Database::General;


sub index ($self) {
    my $tags = metatags => TravellersPalm::Database::General::metatags( 
      ( split '/', $self->req->url->path )[-1] );
    my $slidetext = web(163);
    my @slides    = $slidetext->{data}->{writeup} =~ /\G(?=.)([^\n]*)\n?/sg;
  
    unshift @slides, 'dummy item';

    $self->render(
        template => 'home',
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
        home                 => 1
    )
}

sub about ($self) {
    my $tags = metatags => TravellersPalm::Database::General::metatags( 
      ( split '/', $self->req->url->path )[-1] );

    $self->render(
      template => 'about',
        metatags                => $tags,
        totalcities             => TravellersPalm::Database::Cities::totalcities(),
        totalitineraries        => TravellersPalm::Database::Itineraries::totalitineraries(),
        totaltrains             => TravellersPalm::Database::General::totaltrains(),
        intro                   => webtext(9),
        philosophy              => webtext(170),
        sustainable_tourism     => webtext(171),
        responsible_tourism     => webtext(172),
        meet_the_team           => webtext(31),
        why_travel_with_us      => webtext(12),
        what_is_travellers_palm => webtext(8),
        hans                    => webtext(164),
        sucheta                 => webtext(165),
        phil                    => webtext(166),
        shalome                 => webtext(167),
        crumb                   => ' <li class="active">About Us</li>',
        page_title              => 'About Us'  
      );
}

sub before_you_go ($self) {
    my $tags = metatags => TravellersPalm::Database::General::metatags( 
      ( split '/', $self->req->url->path )[-1] );

    $self->render(
      template => 'before_you_go',
      metatags        => $tags,
      before_you_go   => webtext(17),
        getting_ready   => webtext(168),
        right_attitude  => webtext(169),
        page_title      => 'Before You Go',
        crumb           => '<li class="active">Before You Go</li>'
    );
}

sub contact_us ($self) {
    my $params = $self->req->params->to_hash;
    my $ok     = 0;
    my $error  = 0;

    if ($self->req->method eq 'POST') {
        $ok    = TravellersPalm::Functions::email_request($params);
        $error = $ok ? 0 : 1;
    }

    $self->render(
        template => 'contact',
        error    => $error,
        %$params
    );
}

sub get_enquiry ($self) {
    my $email = ( user_is_registered() ? user_email() : "" );
    my $tags = metatags => TravellersPalm::Database::General::metatags( 
      ( split '/', $self->req->url->path )[-1] );

    $self->render(
      template => 'enquiry',  
      metatags => $tags,
      email => $email
    )
}

sub post_enquiry ($self) {
    my $email = ( user_is_registered() ? user_email() : "" );
    my $tags = metatags => TravellersPalm::Database::General::metatags( 
      ( split '/', $self->req->url->path )[-1] );
    my $params = $self->req->params->to_hash;

    TravellersPalm::Functions::email_request($params);
    
    $self->render(template => 'enquiry_thankyou',
        metatags => $tags,
        subject  => $params->{subject},
        email    => $email
    )
}

sub faq ($self) { 
  my $tags = metatags => TravellersPalm::Database::General::metatags( 
      ( split '/', $self->req->url->path )[-1] );

  $self->render(
    template => 'faq',
    metatags => $tags) 
}

sub policies ($self){ 
    my @fields = (
      webtext(124), webtext(125), webtext(126), webtext(127),
      webtext(128), webtext(129), webtext(130), webtext(131),
      webtext(132), webtext(133), webtext(134), webtext(135),
      webtext(136), webtext(137), webtext(191), webtext(138),
      webtext(139), webtext(140), webtext(141), webtext(142),
      webtext(143), webtext(144), webtext(145), webtext(146),
    );

  my $tags = metatags => TravellersPalm::Database::General::metatags( 
      ( split '/', $self->req->url->path )[-1] );

  $self->render(
      template => 'policies',
      metatags   => $tags,
      conditions => webtext(15),
      terms      => webtext(35),
      privacy    => webtext(16),
      fields     => \@fields,
      about      => webtext(208),
      crumb      => '<li class="active">Our Policies</li>',
      page_title => 'Our Policies'
  );
}

sub search_results ($self) { 
  my $tags = metatags => TravellersPalm::Database::General::metatags( 
      ( split '/', $self->req->url->path )[-1] );

  $self->render(
    template => 'search_results',
      metatags            => $tags,
      why_travel_with_us  => webtext(12),
      extensive_knowledge => webtext(153),
      highly_selective    => webtext(154),
      unbiased            => webtext(155),
      unrivalled_coverage => webtext(156),
      in_charge           => webtext(157),
      value_for_money     => webtext(158),
      page_title          => 'Search Results',
      crumb               => '<li class="active">Search Results</li>'
    ) 
}

sub site_map ($self) { 
    my $textfile = $self->config->{root}.'/url-report.txt';
    my @report   = ();
    my $tags = metatags => TravellersPalm::Database::General::metatags( 
      ( split '/', $self->req->url->path )[-1] );

    if (open(my $fh, '<:encoding(UTF-8)', $textfile)) {
        while (my $row = <$fh>) {
            chomp $row;
            $row =~ /^$/ and next; # blank line
            push @report, {url => $row};
        }
    }

    $self->render(
        template => 'site_map',
        metatags    => $tags,
        report      => \@report,
        crumb       => ' <li class="active">Sitemap</li>',
        page_title  => 'Sitemap'
    ) 
}

sub state ($self){ 
  my $tags = metatags => TravellersPalm::Database::General::metatags( 
      ( split '/', $self->req->url->path )[-1] );

  $self->render(
    template => 'state',
    metatags => $tags) 
}

sub sustainable_tourism ($self) { 
  my $sustainable = webtext(13);
  my $tags = metatags => TravellersPalm::Database::General::metatags( 
      ( split '/', $self->req->url->path )[-1] );

  $self->render(
      template => 'sustainable_tourism',
      metatags    => $tags,
      sustainable => $sustainable,
      crumb       => '<li class="active">'.$sustainable->{title}.'</li>',
      page_title  => $sustainable->{title}
  ) 
}

sub testimonials ($self)      { 
  my $tags = metatags => TravellersPalm::Database::General::metatags( 
      ( split '/', $self->req->url->path )[-1] );

  $self->render(
      template => 'testimonials',
      metatags    => $tags,
      page_title  => 'Testimonials',
      crumb       =>  '<li><a href="[% request.uri_base %]/about-us">About us</a></li>
                      <li class="active">Testimonials</li>' 
  )
}

sub travel_ideas ($self) {
  my $tags = metatags => TravellersPalm::Database::General::metatags( 
      ( split '/', $self->req->url->path )[-1] );
 
  $self->render(
      template => 'travel_ideas',
      metatags        => $tags,
      page_title      => 'Travel Ideas',
      crumb           => '<li class="active">Travel Ideas</li>'
    ) 
}

sub what_to_expect ($self) {   
  my $tags = metatags => TravellersPalm::Database::General::metatags( 
      ( split '/', $self->req->url->path )[-1] );  
  my $expect = webtext($self,21);
  my $title = $expect->{title} // 'What to Expect';

  $self->dump_log("3. Webtext(21) returned:", $expect);

  $self->render(
    template        => 'what_to_expect',
    metatags        => $tags,
    what_to_expect  => $expect,
    special_hotels  => webtext($self,147),
    eat_drink       => webtext($self,148),
    private_car     => webtext($self,149),
    travel_by_train => webtext($self,150),
    fly_in_comfort  => webtext($self,151),
    delays          => webtext($self,152),
    before_you_go   => webtext($self,17),
    getting_ready   => webtext($self,168),
    right_attitude  => webtext($self,169),
    crumb           => '<li class="active">$title</li>',
    page_title      => $title,
  ); 
}

sub why_travel_with_us ($self){ 
    my $tags = metatags => TravellersPalm::Database::General::metatags( 
      ( split '/', $self->req->url->path )[-1] );

    $self->render(
        template => 'why_travel_with_us',
        metatags => $tags
    ) 
}

1;
