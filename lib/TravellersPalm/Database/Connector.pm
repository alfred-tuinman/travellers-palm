package TravellersPalm::Database::Connector;
use Mojo::Base -base;
use DBI;
use Try::Tiny;
use Exporter 'import';

our @EXPORT_OK = qw(
                  execute 
                  fetch_all
                  fetch_row
                  setup
                  );

my ($dbh, $config, $log);

# Called from startup()
sub setup {
    my ($class, $app) = @_;
    $config = $app->config->{database};
    $log    = $app->log;
}

# Internal DB handle manager
sub _dbh {
    unless ($dbh && $dbh->ping) {
        try {
            $dbh = DBI->connect(
                $config->{dsn},
                $config->{username},
                $config->{password},
                {
                    RaiseError => 1,
                    PrintError => 0,
                    AutoCommit => 1,
                    mysql_enable_utf8 => 1,
                }
            );
        }
        catch {
            $log->error("DB connect error: $_") if $log;
            die "Database connection failed: $_";
        };
    }
    return $dbh;
}

# SELECT queries
sub fetch_all {
    my ($class, $sql, @bind) = @_;
    my $dbh = eval { $class->_dbh };
    return { error => $@ } if $@;

    my $result = {};
    try {
        my $sth = $dbh->prepare($sql);
        $sth->execute(@bind);
        $result->{rows} = $sth->fetchall_arrayref({});
    }
    catch {
        $log->error("SQL error: $_ ($sql)") if $log;
        $result->{error} = $_;
    };

    return $result;
}

# INSERT/UPDATE/DELETE
sub execute {
    my ($class, $sql, @bind) = @_;
    my $dbh = eval { $class->_dbh };
    return { error => $@ } if $@;

    my $result = {};
    try {
        my $sth = $dbh->prepare($sql);
        $sth->execute(@bind);
        $result->{rows_affected} = $sth->rows;
    }
    catch {
        $log->error("SQL exec error: $_ ($sql)") if $log;
        $result->{error} = $_;
    };

    return $result;
}

# Optional helper: return only one row
sub fetch_row {
    my ($class, $sql, @bind) = @_;
    my $res = $class->fetch_all($sql, @bind);
    return $res if $res->{error};

    $res->{row} = $res->{rows}->[0] if $res->{rows} && @{$res->{rows}};
    return $res;
}

1;
