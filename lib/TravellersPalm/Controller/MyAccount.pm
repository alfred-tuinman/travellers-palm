package TravellersPalm::Controller::MyAccount;

use Mojo::Base 'Mojolicious::Controller', -signatures;

BEGIN { require TravellersPalm::Database::Users; }

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
    TravellersPalm::Database::Users::register_user($params, $self);  # simplified call
    $self->render(template => 'my_account_register_thankyou');
}

# POST /mail-password
sub mail_password ($self) {
    my $params = $self->req->params->to_hash;
    TravellersPalm::Database::Users::send_password($params->{email}, $self);  # simplified call
    $self->render(template => 'my_account_password_emailed');
}

1;
