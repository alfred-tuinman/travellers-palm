use strict;
use warnings;
use Plack::Request;
use Template;
use DBI;

# Template Toolkit
my $tt = Template->new({ INCLUDE_PATH => 'views' });

# Connect to SQLite databases
my $users_dbh = DBI->connect("dbi:SQLite:dbname=db/users.db","","",{ RaiseError => 1 });
my $jadoo_dbh = DBI->connect("dbi:SQLite:dbname=db/Jadoo_2006.db","","",{ RaiseError => 1 });

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);

    # Health endpoint
    return [200, ['Content-Type'=>'text/plain'], ['OK']] if $req->path_info eq '/health';

    # Read some sample data
    my ($user_count) = $users_dbh->selectrow_array('SELECT COUNT(*) FROM users');
    my ($jadoo_count) = $jadoo_dbh->selectrow_array('SELECT COUNT(*) FROM cities');

    my $output = '';
    $tt->process('index.tt',
        { users => $user_count, jadoo => $jadoo_count },
        \$output
    ) or return [500, ['Content-Type'=>'text/plain'], [$tt->error]];

    return [200, ['Content-Type'=>'text/html'], [$output]];
};

$app;
