package TravellersPalm::Database::Users;

use strict;
use warnings;
use Exporter 'import';
use TravellersPalm::Database::Connector qw(fetch_all fetch_row execute);
use Digest::MD5 qw(md5_hex);
use DateTime;
use Data::Dumper;

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
    my ($c, $email) = @_;
    # This can later integrate with TravellersPalm::Mail
    # or a similar mailer subsystem.
    warn "send_password() not yet implemented for $email\n";
    return;
}

#--------------------------------------------------
# Generate a random password
#--------------------------------------------------
sub generate_password {
    my ($c, $length) = @_;
    $length ||= 10;

    my @chars = ('A'..'Z', 'a'..'z', 0..9);
    return join '', map { $chars[rand @chars] } 1..$length;
}

#--------------------------------------------------
# Update password for a user (hashed)
#--------------------------------------------------
sub update_password {
    my ($c, $userid, $newpass) = @_;
    return unless defined $userid && $newpass;

    my $hash = md5_hex($newpass);
    my $sql  = "UPDATE users SET password = ? WHERE rowid = ?";
    TravellersPalm::Database::Connector::execute($sql, [$hash, $userid], $c);

    return 1;
}

#--------------------------------------------------
# Register an email (shortcut for new user insert)
#--------------------------------------------------
sub register_email {
    my ($c, $email) = @_;
    return unless defined $email;

    register_user($c, $email);
    return 1;
}

#--------------------------------------------------
# Check if user exists
#--------------------------------------------------
sub user_exist {
    my ($c, $username) = @_;
    return [] unless defined $username;

    my $sql = "SELECT rowid, username FROM users WHERE username LIKE ?";
    return TravellersPalm::Database::Connector::fetch_row($sql, [$username], $c, 'NAME_lc');
}

#--------------------------------------------------
# Insert new user with email
#--------------------------------------------------
sub register_user {
    my ($c, $email) = @_;
    return [] unless defined $email;

    my $now = DateTime->now->datetime;
    $now =~ y/T/ /;   # Convert ISO format to space-separated datetime

    my $sql = "INSERT INTO users (username, active, registeredon) VALUES (?, ?, ?)";
    TravellersPalm::Database::Connector::execute($sql, [$email, 1, $now], $c);

    return 1;
}

#--------------------------------------------------
# Validate user login
#--------------------------------------------------
sub user_ok {
    my ($c, $username, $password) = @_;
    return 0 unless $username && $password;

    my $hash = md5_hex($password);

    my $sql = q{
        SELECT rowid AS rowid
        FROM users
        WHERE username LIKE ?
          AND password LIKE ?
    };
    my $row = TravellersPalm::Database::Connector::fetch_row($sql, [$username, $hash], $c, 'NAME_lc');

    return $row ? $row : 0;
}

#--------------------------------------------------
# Update user's password directly by rowid
#--------------------------------------------------
sub user_update {
    my ($c, $userid, $password) = @_;
    return 0 unless $userid && $password;

    my $hash = md5_hex($password);
    my $sql  = "UPDATE users SET password = ? WHERE rowid = ?";
    TravellersPalm::Database::Connector::execute($sql, [$hash, $userid], $c);

    return 1;
}

1;
