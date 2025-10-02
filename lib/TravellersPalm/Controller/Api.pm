package TravellersPalm::Controller::Api;

use strict;
use warnings;

use DBI;
use JSON;

use Dancer2::Plugin::Database; 

sub ping {
    return [200, ['Content-Type'=>'application/json'], [ encode_json({ status => 'ok' }) ]];
}

sub user_info {
    my ($class, $env, $match) = @_;
    my $id = $match->{id};

    my $dbh = DBI->connect("dbi:SQLite:dbname=db/users.db","","",{ RaiseError => 1 });
    my $user = $dbh->selectrow_hashref("SELECT * FROM users WHERE id = ?", undef, $id);

    return [200, ['Content-Type'=>'application/json'], [ encode_json($user || { error => 'not found' }) ]];
}

1;
