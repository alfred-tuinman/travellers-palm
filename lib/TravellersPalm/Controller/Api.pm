package TravellersPalm::Controller::Api;

use Mojo::Base 'Mojolicious::Controller';
use DBI;
use JSON ();

# GET /api/ping
sub ping {
    my $c = shift;
    $c->render( json => { status => 'ok' } );
}

# GET /api/user/:id
sub user_info {
    my $c  = shift;
    my $id = $c->param('id');

    # Example: using SQLite for demo
    my $dbh = DBI->connect(
        'dbi:SQLite:dbname=db/users.db', '', '',
        { RaiseError => 1, AutoCommit => 1 }
    );

    my $user = $dbh->selectrow_hashref(
        'SELECT * FROM users WHERE id = ?', undef, $id
    );

    $c->render(
        json => $user // { error => 'not found' }
    );
}

1;

__END__

=head1 AUTHOR

Travellers Palm Team

=head1 LICENSE

See the main project LICENSE file.

=cut
