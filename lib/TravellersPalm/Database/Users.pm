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
        return;
    }

    # This can later integrate with TravellersPalm::Mail
    # or a similar mailer subsystem.
    warn "send_password() not yet implemented for $email\n";
    return;
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

1;

# Central password hashing wrapper.
# Currently this uses md5_hex to preserve existing behavior but centralises
# the hashing mechanism so it can be upgraded (bcrypt/scrypt/argon2) later
sub password_hash {
  my ($password) = @_;
  return md5_hex($password // '');
}
