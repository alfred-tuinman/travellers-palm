package TravellersPalm::Database::Connector;

use strict;
use warnings;
use DBI;
use Data::Dumper;
use Exporter 'import';

our @EXPORT_OK = qw(setup dbh fetch_row fetch_all insert_row update_row delete_row);

my ($app, %handles);

# -----------------------------------
# setup($app)
# -----------------------------------
sub setup {
    my ($class, $app_ref) = @_;
    die "No app reference provided to Connector" unless $app_ref;
    $app = $app_ref;
    $app->log->debug("Calling DB setup, app=$app") if $app->can('log');
    return 1;
}

# -----------------------------------
# Internal SQL logging utility
# -----------------------------------
sub _log_sql {
    my ($sql, $bind_ref, $c) = @_;
    my $timestamp = scalar localtime;
    my $binds = $bind_ref && @$bind_ref ? join(", ", map { defined $_ ? $_ : 'NULL' } @$bind_ref) : '(none)';

    # Get DB subroutine caller
    my ($package, $filename, $line, $subroutine) = caller(1);
    $subroutine //= 'unknown_db_sub';

    # Get route info if $c is provided
    my $route_info = '';
    if ($c && $c->match) {
        my $pattern = eval { $c->match->endpoint->pattern->uncompiled } // '';
        $route_info = $pattern ? " | route: $pattern" : '';
    }

    my $msg = sprintf("[SQL] %s | binds: %s | called from: %s at %s line %d%s",
                      $sql, $binds, $subroutine, $filename, $line, $route_info);

    if ($app && $app->can('log')) {
        $app->log->debug($msg);
    } else {
        print STDERR "[$timestamp] [pid:$$] $msg\n";
    }
}

# -----------------------------------
# Get DB handle safely
# -----------------------------------
sub dbh {
    my ($dbkey) = @_;
    die "Connector not setup" unless $app;

    my $databases = $app->config->{databases} || {};
    die "No databases in config" unless %$databases;

    $dbkey //= (keys %$databases)[0];
    die "No database config for '$dbkey'" unless exists $databases->{$dbkey};

    # Return cached handle if exists
    return $handles{$dbkey} if $handles{$dbkey};

    my $dbconf = $databases->{$dbkey};
    my $dsn    = $dbconf->{dsn}      // '';
    my $user   = $dbconf->{username} // '';
    my $pass   = $dbconf->{password} // '';
    my $params = $dbconf->{dbi_params} || {};
    $params->{sqlite_unicode} = 1 unless exists $params->{sqlite_unicode};

    my $dbh = DBI->connect($dsn, $user, $pass, $params)
        or die "DB connect failed for '$dbkey': $DBI::errstr";

    $handles{$dbkey} = $dbh;

    eval { $app->log->debug("Connected to DB [$dbkey] dsn=$dsn") };

    return $dbh;
}

# -----------------------------------
# Generic DB operations
# -----------------------------------
sub fetch_row {
    my ($sql, $bind_ref, $key_style, $dbkey, $c) = @_;
    $bind_ref  //= [];
    $key_style //= 'NAME';
    my $dbh = dbh($dbkey);

    _log_sql($sql, $bind_ref, $c);

    my $sth;
    eval { $sth = $dbh->prepare($sql); $sth->execute(@$bind_ref); };
    die "DB error: $@" if $@;
    return $sth->fetchrow_hashref($key_style);
}

sub fetch_all {
    my ($sql, $bind_ref, $key_style, $dbkey, $c) = @_;
    $bind_ref  //= [];
    $key_style //= 'NAME';
    my $dbh = dbh($dbkey);

    _log_sql($sql, $bind_ref, $c);

    my $sth;
    eval { $sth = $dbh->prepare($sql); $sth->execute(@$bind_ref); };
    die "DB error: $@" if $@;

    my @rows;
    while (my $r = $sth->fetchrow_hashref($key_style)) { push @rows, $r; }
    return \@rows;
}

sub insert_row {
    my ($sql, $bind_ref, $dbkey, $c) = @_;
    $bind_ref ||= [];
    my $dbh = dbh($dbkey);

    _log_sql($sql, $bind_ref, $c);

    my $sth;
    eval { $sth = $dbh->prepare($sql); $sth->execute(@$bind_ref); };
    die "DB error: $@" if $@;
    return 1;
}

sub update_row {
    my ($sql, $bind_ref, $dbkey, $c) = @_;
    $bind_ref ||= [];
    my $dbh = dbh($dbkey);

    _log_sql($sql, $bind_ref, $c);

    my $sth;
    eval { $sth = $dbh->prepare($sql); $sth->execute(@$bind_ref); };
    die "DB error: $@" if $@;
    return 1;
}

sub delete_row {
    my ($sql, $bind_ref, $dbkey, $c) = @_;
    $bind_ref ||= [];
    my $dbh = dbh($dbkey);

    _log_sql($sql, $bind_ref, $c);

    my $sth;
    eval { $sth = $dbh->prepare($sql); $sth->execute(@$bind_ref); };
    die "DB error: $@" if $@;
    return 1;
}

1;
