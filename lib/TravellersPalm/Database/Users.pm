package TravellersPalm::Database::Users;

use strict;
use warnings;

use Data::Dumper;
use DateTime;
use Digest::MD5 qw(md5_hex);
use Exporter 'import';
use TravellersPalm::Database::Connector qw(fetch_all fetch_row insert_row update_row);

our @EXPORT_OK = qw(
    generate_password
    register_email
    register_user
    send_password
    update_password
    user_exist
    user_ok
    user_update
);

#--------------------------------------------------
# Send password placeholder (stub)
#--------------------------------------------------
sub send_password {
    my ($email, $c) = @_;
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
    $length ||= 10;

    my @chars = ('A'..'Z', 'a'..'z', 0..9);
    return join '', map { $chars[rand @chars] } 1..$length;
}

#--------------------------------------------------
# Update password for a user (hashed)
#--------------------------------------------------
sub update_password {
    my ($userid, $newpass, $c) = @_;
    return unless defined $userid && $newpass;

    my $hash = md5_hex($newpass);
    my $res = TravellersPalm::Database::Connector::update_row(
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
    return unless defined $email;

    register_user($c, $email);
    return 1;
}

#--------------------------------------------------
# Check if user exists
#--------------------------------------------------
sub user_exist {
    my ($username,$c) = @_;
    return [] unless defined $username;

    my $sql = "SELECT rowid, username FROM users WHERE username LIKE ?";
    return TravellersPalm::Database::Connector::fetch_row(
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

    my $res = TravellersPalm::Database::Connector::insert_row(
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
    return 0 unless $username && $password;

    my $hash = md5_hex($password);

    my $sql = q{
        SELECT rowid AS rowid
        FROM users
        WHERE username LIKE ?
          AND password LIKE ?
    };
    my $row = TravellersPalm::Database::Connector::fetch_row(
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

    my $hash = md5_hex($password);
    my $res = TravellersPalm::Database::Connector::update_row(
      "UPDATE users SET password = ? WHERE rowid = ?", 
      [$hash, $userid], 'NAME', 'jadoo', $c
    );

    return $res;
}

1;
