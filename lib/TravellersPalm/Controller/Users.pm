package TravellersPalm::Controller::Users;
use strict;
use warnings;
use DBI;
use Template;

sub profile {
    my ($class, $env, $match) = @_;
    my $id = $match->{id};

    my $dbh = DBI->connect("dbi:SQLite:dbname=db/users.db","","",{ RaiseError => 1 });
    my $user = $dbh->selectrow_hashref("SELECT * FROM users WHERE id = ?", undef, $id);

    my $tt = Template->new({ INCLUDE_PATH => 'views' });
    my $output = '';
    $tt->process('user.tt', { user => $user }, \$output)
        or return [500, ['Content-Type'=>'text/plain'], ["Template error: " . $tt->error]];

    return [200, ['Content-Type'=>'text/html'], [$output]];
}

1;
