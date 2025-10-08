package TravellersPalm::Controller::Home;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use TravellersPalm::Functions qw(webtext);
use TravellersPalm::Database::General;

sub index ($self) {
    $self->render(template => 'home');
}

sub before_you_go ($self) {
    $self->render(template => 'before_you_go');
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
        template => 'contact_us',
        error    => $error,
        %$params
    );
}

sub get_enquiry ($self) {
    $self->render(template => 'enquiry');
}

sub post_enquiry ($self) {
    my $params = $self->req->params->to_hash;
    TravellersPalm::Functions::email_request($params);
    $self->render(template => 'enquiry_thankyou');
}

sub faq ($self)               { $self->render(template => 'faq') }
sub policies ($self)          { $self->render(template => 'policies') }
sub search_results ($self)    { $self->render(template => 'search_results') }
sub site_map ($self)          { $self->render(template => 'site_map') }
sub state ($self)             { $self->render(template => 'state') }
sub sustainable_tourism ($self){ $self->render(template => 'sustainable_tourism') }
sub testimonials ($self)      { $self->render(template => 'testimonials') }
sub travel_ideas ($self)      { $self->render(template => 'travel_ideas') }
sub what_to_expect ($self)    { $self->render(template => 'what_to_expect') }
sub why_travel_with_us ($self){ $self->render(template => 'why_travel_with_us') }

1;
