package TravellersPalm::Database::Connector;

use strict;
use warnings;
use DBI;
use Data::Dumper;
use Exporter 'import';
use POSIX qw(strftime);

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

# -----------------------------
# Internal SQL logging utility
# -----------------------------
sub _log_sql {
    my ($sql, $bind_ref, $caller_self) = @_;
    $bind_ref ||= [];

    # Get calling subroutine info
    my ($subroutine, $filename, $line) = _get_caller_info();

    # Attempt to get route info from controller if passed
    my $route_info = '';
    if ($caller_self && ref $caller_self && $caller_self->can('req')) {
        my $req = $caller_self->req;
        $route_info = sprintf(" | route: %s", $req->url->to_string) if $req;
    }

    # Format bind values
    my $binds = @$bind_ref ? join(", ", map { defined $_ ? $_ : 'NULL' } @$bind_ref) : '(none)';

    # Multi-line SQL formatting (indent lines)
    my $sql_formatted = $sql;
    $sql_formatted =~ s/^/    /mg;

    # Prepare log message
    my $msg = sprintf(
        "[SQL]\n%s\n | binds: %s | called from: %s at %s line %d%s",
        $sql_formatted,
        $binds,
        $subroutine,
        $filename,
        $line,
        $route_info
    );

    # Send to app log if available, else STDERR
    if ($app && $app->can('log')) {
        $app->log->debug($msg);
    } else {
        my $timestamp = scalar localtime;
        print STDERR "[$timestamp] [pid:$$] $msg\n";
    }
}

# -----------------------------
# Helper: Get caller info
# -----------------------------
sub _get_caller_info {
    my $skip_frames = 1;  # skip _log_sql itself
    while (my @caller = caller($skip_frames++)) {
        my ($package, $filename, $line, $subroutine) = @caller;

        # Skip internal frames: _log_sql, DBI, Mojo/Mojolicious
        next if $subroutine =~ /::_log_sql$/;
        next if $package =~ /^(Mojo|Mojolicious|DBI)/;
        next if $subroutine =~ /^(Mojo|Mojolicious|DBI)/;

        return ($subroutine, $filename, $line);
    }

    return ('unknown', 'unknown', 0);
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
