package TravellersPalm::Controller::MyAccount;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use TravellersPalm::Database::Users qw(register_user send_password);

# -----------------------------
# Controller Actions
# -----------------------------

# GET /login
sub login ($self) {
    $self->render(template => 'my_account_login');
}

# POST /register
sub register ($self) {
    my $params = $self->req->params->to_hash;
    register_user($params);  # simplified call
    $self->render(template => 'my_account_register_thankyou');
}

# POST /mail-password
sub mail_password ($self) {
    my $params = $self->req->params->to_hash;
    send_password($params->{email});  # simplified call
    $self->render(template => 'my_account_password_emailed');
}

1;
