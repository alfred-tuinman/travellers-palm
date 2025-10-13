package TravellersPalm::Database::Connector;
use Mojo::Base -base;
use DBI;
use Try::Tiny;
use Exporter 'import';

our @EXPORT_OK = qw(fetch_all fetch_row execute);

my (%DBH, $config, $log);

# Called from startup()
sub setup {
    my ($class, $app) = @_;
    $config = $app->config->{databases};
    $log    = $app->log;
}

# Get DB handle
sub dbh {
    my ($class, $dbkey) = @_;
    $dbkey //= 'jadoo';  # default DB

    return $DBH{$dbkey} if $DBH{$dbkey} && $DBH{$dbkey}->ping;

    my $cfg = $config->{$dbkey} or die "No configuration for database '$dbkey'";
    try {
        $DBH{$dbkey} = DBI->connect(
            $cfg->{dsn},
            $cfg->{username},
            $cfg->{password},
            {
                RaiseError => $cfg->{dbi_params}->{RaiseError} // 1,
                AutoCommit => $cfg->{dbi_params}->{AutoCommit} // 1,
                PrintError => $cfg->{dbi_params}->{PrintError} // 0,
                sqlite_unicode => 1,  # for SQLite
            }
        );
    }
    catch {
        $log->error("DB connect error for $dbkey: $_") if $log;
        die "Database connection failed for $dbkey: $_";
    };

    return $DBH{$dbkey};
}

# fetch_all / fetch_row / execute stay the same
