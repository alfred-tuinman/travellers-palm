package TravellersPalm::Database::Users;

use strict;
use warnings;

use Exporter 'import';
use TravellersPalm::Database::Connector qw(fetch_all fetch_row insert update);
use Data::Dumper;
use Digest::MD5 qw(md5_hex);
use DateTime;

our @EXPORT_OK = qw( 
    user_exist
    user_ok
    user_update
    update_password
    generate_password
    register_email
    register_user 
    send_password
);


sub send_pasword {
    my ($c, $length) = @_;
    return;
}

#--------------------------------------------------
# Generate a random password
#--------------------------------------------------
sub generate_password {
    my ($c, $length) = @_;
    $length = 10 unless defined $length;
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
    TravellersPalm::Database::Connector::update($sql, [$hash, $userid],$c);

    return 1;
}

#--------------------------------------------------
# Register an email (creates a new user)
#--------------------------------------------------
sub register_email {
    my ($c, $email) = @_;
    return unless defined $email;

    user_insert($email);
    return 1;
}

#--------------------------------------------------
# Check if user exists
#--------------------------------------------------
sub user_exist {
    my ($c, $user) = @_;
    return [] unless defined $user;
    my $sql = "SELECT rowid, username FROM users WHERE username LIKE ?";
    return TravellersPalm::Database::Connector::fetch_row($sql, [$user], $c);
}

#--------------------------------------------------
# Insert new user with email
#--------------------------------------------------
sub register_user {
     my ($c, $emailid) = @_;
    return [] unless defined $emailid;

    my $now = DateTime->now->datetime;
    $now =~ y/T/ /;   # Convert ISO format to space-separated datetime

    my $sql = "INSERT INTO users (username, active, registeredon) VALUES (?, ?, ?)";

    print STDERR Dumper([$emailid, 1, $now]);

    TravellersPalm::Database::Connector::insert($sql, [$emailid, 1, $now], $c);
    return 1;
}

#--------------------------------------------------
# Validate user login
#--------------------------------------------------
sub user_ok {
    my ($c, $username, $password) = @_;
    return 0 unless $username && $password;

    my $hash = md5_hex($password);

    my $sql = "SELECT rowid AS rowid FROM users WHERE username LIKE ? AND password LIKE ?";
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
    TravellersPalm::Database::Connector::update($sql, [$hash, $userid], $c);

    return 1;
}

1;
