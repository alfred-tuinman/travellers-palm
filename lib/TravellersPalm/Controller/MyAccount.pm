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

# -----------------------------
# POST /login - Process login with optional 2FA
# -----------------------------
sub process_login ($self) {
    my $params = $self->req->params->to_hash;
    my $username = $params->{username} || '';
    my $password = $params->{password} || '';
    my $totp_code = $params->{totp_code} || '';
    
    # Attempt login with 2FA check
    my $user = TravellersPalm::Database::Users::user_ok_with_2fa(
        $username, $password, $totp_code, $self
    );
    
    if ($user) {
        # Login successful
        $self->session(user_id => $user->{rowid});
        $self->session(username => $username);
        $self->redirect_to('/dashboard'); # or wherever you want to redirect
    } else {
        # Login failed
        $self->stash(
            error => 'Invalid credentials or 2FA code',
            username => $username
        );
        $self->render(template => 'my_account_login');
    }
}

# -----------------------------
# GET /2fa/setup - Show 2FA setup page
# -----------------------------
sub setup_2fa ($self) {
    # TEST: Gmail SMTP with STARTTLS fix
    die "Testing Gmail SMTP with STARTTLS configuration fix";
    
    my $user_id = $self->session('user_id');
    unless ($user_id) {
        return $self->redirect_to('/login');
    }
    
    # Check if 2FA is already enabled
    my $has_2fa = TravellersPalm::Database::Users::user_has_2fa($user_id, $self);
    
    $self->stash(
        user_id => $user_id,
        has_2fa => $has_2fa
    );
    $self->render(template => '2fa_setup');
}

# -----------------------------
# POST /2fa/enable - Enable 2FA for user
# -----------------------------
sub enable_2fa ($self) {
    my $user_id = $self->session('user_id');
    unless ($user_id) {
        return $self->redirect_to('/login');
    }
    
    my $params = $self->req->params->to_hash;
    my $verification_code = $params->{verification_code} || '';
    
    # Generate secret and verify the code
    my $secret = TravellersPalm::Database::Users::generate_2fa_secret($user_id, $self);
    
    if (TravellersPalm::Database::Users::verify_2fa_code($user_id, $verification_code, $self)) {
        # Enable 2FA
        TravellersPalm::Database::Users::enable_2fa($user_id, $self);
        $self->stash(success => '2FA enabled successfully!');
    } else {
        $self->stash(error => 'Invalid verification code. Please try again.');
    }
    
    $self->render(template => '2fa_setup');
}

# -----------------------------
# POST /2fa/disable - Disable 2FA for user
# -----------------------------
sub disable_2fa ($self) {
    my $user_id = $self->session('user_id');
    unless ($user_id) {
        return $self->redirect_to('/login');
    }
    
    TravellersPalm::Database::Users::disable_2fa($user_id, $self);
    $self->stash(success => '2FA disabled successfully!');
    $self->render(template => '2fa_setup');
}

# -----------------------------
# GET /2fa/qr - Generate QR code URL for 2FA setup
# -----------------------------
sub generate_qr_code ($self) {
    my $user_id = $self->session('user_id');
    unless ($user_id) {
        return $self->redirect_to('/login');
    }
    
    # Get user email (you may need to adjust this based on your user table structure)
    my $username = $self->session('username') || 'user@travellerspalm.com';
    
    # Generate secret
    my $secret = TravellersPalm::Database::Users::generate_2fa_secret($user_id, $self);
    
    # Generate QR code data
    my $qr_data = TravellersPalm::Database::Users::generate_2fa_qr_data($username, $secret, $self);
    
    # Return JSON with QR data for frontend to generate QR code
    $self->render(json => {
        qr_url => $qr_data->{qr_url},
        secret => $qr_data->{secret},
        success => 1
    });
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
