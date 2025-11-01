package TravellersPalm::Database::Users;

use strict;
use warnings;

use Data::Dumper;
use DateTime;
use Digest::MD5 qw(md5_hex);
use Exporter 'import';
use TravellersPalm::Database::Core::Connector qw(fetch_all fetch_row insert_row update_row);
use TravellersPalm::Database::Core::Validation qw(
    validate_string 
    validate_integer
    validate_order
);
use Email::Valid;
use MIME::Base32;
use Email::MIME;
use Encode;
use Digest::SHA qw(hmac_sha1);
use URI::Escape;
use POSIX qw(floor);

#--------------------------------------------------
# Send password placeholder (stub)
#--------------------------------------------------
sub send_password {
    my ($email, $c) = @_;
    
    # Validate email
    eval {
        $email = validate_string($email, 1, 255);  # Required, max 255 chars
        die "Invalid email format\n" unless Email::Valid->address($email);
    };
    if ($@) {
        warn "Input validation failed in send_password(): $@";
        return { error => "Invalid email format" };
    }

    # Check if user exists
    my $user = user_exist($email, $c);
    unless ($user && $user->{rowid}) {
        warn "User not found for email: $email";
        return { error => "User not found" };
    }

    # Generate new password
    my $new_password = generate_password(12, $c);
    
    # Update password in database
    my $update_result = update_password($user->{rowid}, $new_password, $c);
    unless ($update_result) {
        warn "Failed to update password for user: $email";
        return { error => "Failed to update password" };
    }

    # Send email with new password
    eval {
        my $from = $c->config->{email}{from} || 'noreply@travellerspalm.com';
        my $subject = 'Your new password for ' . ($c->config->{appname} || 'TravellersPalm');
        
        my $body = sprintf(
            "Hello,\n\nYour new password is: %s\n\n" .
            "Please log in and change this password as soon as possible.\n\n" .
            "Best regards,\n%s Team",
            $new_password,
            $c->config->{appname} || 'TravellersPalm'
        );
        
        my $encoded_body = encode('UTF-8', $body);
        
        my $email_obj = Email::MIME->create(
            header_str => [
                From    => $from,
                To      => $email,
                Subject => $subject,
            ],
            attributes => {
                content_type => 'text/plain',
                charset      => 'UTF-8',
                encoding     => 'quoted-printable',
            },
            body => $encoded_body,
        );
        
        # Use the transport from our Mailer
        my $transport = $c->app->email_transport;
        $transport->send_email($email_obj, {
            from => $from,
            to   => [$email],
        });
        
        $c->log->info("Password reset email sent to: $email");
        
    };
    if ($@) {
        warn "Failed to send password email to $email: $@";
        return { error => "Failed to send email" };
    }

    return { success => 1 };
}

#--------------------------------------------------
# Generate a random password
#--------------------------------------------------
sub generate_password {
    my ($length, $c) = @_;
    
    # Validate length
    eval {
        $length = validate_integer($length, 0, 8, 32);  # Optional (default 10), range 8-32
    };
    if ($@) {
        warn "Input validation failed in generate_password(): $@";
        $length = 10;  # Fall back to default on error
    }

    my @chars = ('A'..'Z', 'a'..'z', 0..9);
    return join '', map { $chars[rand @chars] } 1..$length;
}

#--------------------------------------------------
# Update password for a user (hashed)
#--------------------------------------------------
sub update_password {
    my ($userid, $newpass, $c) = @_;
    
    # Validate inputs
    eval {
        $userid = validate_integer($userid, 1, 1, 1000000);  # Required, range 1-1000000
        $newpass = validate_string($newpass, 1, 72);         # Required, max 72 chars (bcrypt limit)
        die "Password too weak (min 8 chars required)\n" if length($newpass) < 8;
        die "Password must contain letters and numbers\n" unless $newpass =~ /[A-Za-z]/ && $newpass =~ /[0-9]/;
    };
    if ($@) {
        warn "Input validation failed in update_password(): $@";
        return;
    }
    my $hash = password_hash($newpass);
    my $res = TravellersPalm::Database::Core::Connector::update_row(
      "UPDATE users SET password = ? WHERE rowid = ?", 
      [$hash, $userid], 'NAME', 'jadoo', $c
    );

    return $res;
}

#--------------------------------------------------
# Register an email (shortcut for new user insert)
#--------------------------------------------------
sub register_email {
    my ($email, $c) = @_;
    
    # Validate email
    eval {
        $email = validate_string($email, 1, 255);  # Required, max 255 chars
        die "Invalid email format\n" unless Email::Valid->address($email);
    };
    if ($@) {
        warn "Input validation failed in register_email(): $@";
        return;
    }
  register_user($c, $email);
    return 1;
}

#--------------------------------------------------
# Check if user exists
#--------------------------------------------------
sub user_exist {
    my ($username, $c) = @_;
    
    # Validate username/email
    eval {
        $username = validate_string($username, 1, 255);  # Required, max 255 chars
        die "Invalid email format\n" unless Email::Valid->address($username);
    };
    if ($@) {
        warn "Input validation failed in user_exist(): $@";
        return [];
    }

    my $sql = "SELECT rowid, username FROM users WHERE username LIKE ?";
    return TravellersPalm::Database::Core::Connector::fetch_row(
      $sql, [$username], 'NAME_lc', 'jadoo', $c
    );
}

#--------------------------------------------------
# Insert new user with email
#--------------------------------------------------
sub register_user {
    my ($email, $c) = @_;
    return [] unless defined $email;

    my $now = DateTime->now->datetime;
       $now =~ y/T/ /;   # Convert ISO format to space-separated datetime

    my $res = TravellersPalm::Database::Core::Connector::insert_row(
      "INSERT INTO users (username, active, registeredon) VALUES (?, ?, ?)", 
      [$email, 1, $now], 'NAME', 'jadoo', $c
    );

    return $res;
}

#--------------------------------------------------
# Validate user login
#--------------------------------------------------
sub user_ok {
    my ($username, $password, $c) = @_;
    
    # Validate inputs
    eval {
        $username = validate_string($username, 1, 255);  # Required, max 255 chars
        die "Invalid email format\n" unless Email::Valid->address($username);
        
        $password = validate_string($password, 1, 72);   # Required, max 72 chars
        die "Password too short\n" if length($password) < 8;
    };
    if ($@) {
        warn "Input validation failed in user_ok(): $@";
        return 0;
    }
  my $hash = password_hash($password);

    my $sql = q{
        SELECT rowid AS rowid
        FROM users
        WHERE username LIKE ?
          AND password LIKE ?
    };
    my $row = TravellersPalm::Database::Core::Connector::fetch_row(
      $sql, [$username, $hash], 'NAME_lc', 'jadoo', $c
    );

    return $row ? $row : 0;
}

#--------------------------------------------------
# Update user's password directly by rowid
#--------------------------------------------------
sub user_update {
    my ($userid, $password, $c) = @_;
    return 0 unless $userid && $password;
    my $hash = password_hash($password);
    my $res = TravellersPalm::Database::Core::Connector::update_row(
      "UPDATE users SET password = ? WHERE rowid = ?", 
      [$hash, $userid], 'NAME', 'jadoo', $c
    );

    return $res;
}

#--------------------------------------------------
# 2FA (Two-Factor Authentication) Functions
#--------------------------------------------------

# Generate 2FA secret for a user
sub generate_2fa_secret {
    my ($user_id, $c) = @_;
    
    # Generate a random 20-byte secret (160 bits - recommended for TOTP)
    my $secret = '';
    for (1..20) {
        $secret .= chr(int(rand(256)));
    }
    
    # Convert to Base32 for compatibility with authenticator apps
    my $secret_base32 = MIME::Base32::encode($secret);
    $secret_base32 =~ s/=//g; # Remove padding
    
    # Store in database
    my $sql = "UPDATE users SET totp_secret = ? WHERE rowid = ?";
    update_row($sql, [$secret_base32, $user_id], 'users', $c);
    
    return $secret_base32;
}

# Simple TOTP implementation
sub generate_totp_code {
    my ($secret_base32, $time_step) = @_;
    
    # Default time step is current 30-second window
    $time_step //= floor(time() / 30);
    
    # Decode Base32 secret
    my $secret = MIME::Base32::decode_base32($secret_base32);
    
    # Convert time step to 8-byte big-endian
    my $time_bytes = pack('N2', 0, $time_step);
    
    # Generate HMAC-SHA1
    my $hmac = hmac_sha1($time_bytes, $secret);
    
    # Dynamic truncation
    my $offset = ord(substr($hmac, -1)) & 0xF;
    my $code = unpack('N', substr($hmac, $offset, 4)) & 0x7FFFFFFF;
    
    # Return 6-digit code
    return sprintf('%06d', $code % 1000000);
}

# Generate QR code data for 2FA setup
sub generate_2fa_qr_data {
    my ($user_email, $secret, $c) = @_;
    
    # Create TOTP URL for authenticator apps
    my $app_name = "Travellers Palm";
    my $totp_url = sprintf(
        "otpauth://totp/%s:%s?secret=%s&issuer=%s",
        uri_escape($app_name),
        uri_escape($user_email),
        $secret,
        uri_escape($app_name)
    );
    
    return {
        secret => $secret,
        qr_url => $totp_url,
        manual_entry_key => $secret
    };
}

# Verify 2FA code
sub verify_2fa_code {
    my ($user_id, $code, $c) = @_;
    
    # Get user's TOTP secret from database
    my $sql = "SELECT totp_secret FROM users WHERE rowid = ?";
    my $row = fetch_row($sql, [$user_id], 'NAME_lc', 'users', $c);
    
    return 0 unless $row && $row->{totp_secret};
    
    my $secret = $row->{totp_secret};
    
    # Check current time window and adjacent windows (to allow for clock skew)
    my $current_time_step = floor(time() / 30);
    
    for my $time_step (($current_time_step - 1) .. ($current_time_step + 1)) {
        my $expected_code = generate_totp_code($secret, $time_step);
        if ($code eq $expected_code) {
            return 1;
        }
    }
    
    return 0;
}

# Enable 2FA for a user
sub enable_2fa {
    my ($user_id, $c) = @_;
    
    my $sql = "UPDATE users SET totp_enabled = 1 WHERE rowid = ?";
    return update_row($sql, [$user_id], 'users', $c);
}

# Disable 2FA for a user
sub disable_2fa {
    my ($user_id, $c) = @_;
    
    my $sql = "UPDATE users SET totp_enabled = 0, totp_secret = NULL WHERE rowid = ?";
    return update_row($sql, [$user_id], 'users', $c);
}

# Check if user has 2FA enabled
sub user_has_2fa {
    my ($user_id, $c) = @_;
    
    my $sql = "SELECT totp_enabled FROM users WHERE rowid = ?";
    my $row = fetch_row($sql, [$user_id], 'NAME_lc', 'users', $c);
    
    return $row && $row->{totp_enabled} ? 1 : 0;
}

# Enhanced login check with 2FA
sub user_ok_with_2fa {
    my ($username, $password, $totp_code, $c) = @_;
    
    # First check regular password
    my $user = user_ok($username, $password, $c);
    return 0 unless $user;
    
    my $user_id = $user->{rowid};
    
    # Check if 2FA is enabled for this user
    if (user_has_2fa($user_id, $c)) {
        # 2FA is enabled, verify TOTP code
        return 0 unless $totp_code;
        return verify_2fa_code($user_id, $totp_code, $c) ? $user : 0;
    }
    
    # 2FA not enabled, regular login is sufficient
    return $user;
}

1;

# Central password hashing wrapper.
# Currently this uses md5_hex to preserve existing behavior but centralises
# the hashing mechanism so it can be upgraded (bcrypt/scrypt/argon2) later
sub password_hash {
  my ($password) = @_;
  return md5_hex($password // '');
}
