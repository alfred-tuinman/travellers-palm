package TravellersPalm::Controller::MyAccount;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use TravellersPalm::Database::Users qw(register_user send_password);
# use TravellersPalm::Functions qw(email_request);

sub login ($self) {
    $self->render(template => 'my_account_login');
}

sub register ($self) {
    my $params = $self->req->params->to_hash;
    TravellersPalm::Database::Users::register_user($c,$params);
    $self->render(template => 'my_account_register_thankyou');
}

sub mail_password ($self) {
    my $params = $self->req->params->to_hash;
    TravellersPalm::Database::Users::send_password($c,$params->{email});
    $self->render(template => 'my_account_password_emailed');
}

1;
