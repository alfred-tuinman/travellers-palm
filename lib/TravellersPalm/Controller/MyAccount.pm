package TravellersPalm::Controller::MyAccount;

use Mojo::Base 'Mojolicious::Controller', -signatures;

BEGIN { require TravellersPalm::Database::Users; }

# -----------------------------
# GET /login
# -----------------------------
sub login ($self) {
        $self->render(template => 'my_account_login');
}

# -----------------------------
# POST /register
# -----------------------------
sub register ($self) {
        my $req    = $self->req;
        my $params = $req->params->to_hash;

        TravellersPalm::Database::Users::register_user($params, $self);

        $self->render(template => 'my_account_register_thankyou');
}

# -----------------------------
# POST /mail-password
# -----------------------------
sub mail_password ($self) {
        my $req    = $self->req;
        my $params = $req->params->to_hash;

        TravellersPalm::Database::Users::send_password($params->{email}, $self);

        $self->render(template => 'my_account_password_emailed');
}

1;

__END__

=head1 NAME

TravellersPalm::Controller::MyAccount - Controller for user account actions

=head1 DESCRIPTION

Handles login, registration, and password reset for user accounts.

=head2 login

    $self->login

Renders the login page.

=head2 register

    $self->register

Handles user registration and renders thank you page.

=head2 mail_password

    $self->mail_password

Handles password reset and renders confirmation page.

=head1 AUTHOR

Travellers Palm Team

=head1 LICENSE

See the main project LICENSE file.

=cut
