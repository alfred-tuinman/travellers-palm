package TravellersPalm::Database::Connector;

use strict;
use warnings;
use DBI;
use Data::Dumper;
use Exporter 'import';
use POSIX qw(strftime);
use Dotenv -load;
use Email::Sender::Transport::SMTP;
use Email::Stuffer;

our @EXPORT_OK = qw(fetch_row fetch_all insert_row update_row delete_row);

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
# Generic DB operations with email error
# -----------------------------------
sub fetch_row  { _execute_db('fetch_row', @_) }
sub fetch_all  { _execute_db('fetch_all', @_) }
sub insert_row { _execute_db('insert_row', @_) }
sub update_row { _execute_db('update_row', @_) }
sub delete_row { _execute_db('delete_row', @_) }

sub _execute_db {
    my ($op, $sql, $bind_ref, $key_style, $dbkey, $c) = @_;
    $bind_ref  //= [];
    $key_style //= 'NAME';
    my $dbh = dbh($dbkey);

    _log_sql($sql, $bind_ref, $c);

    my $sth;
    eval {
        $sth = $dbh->prepare($sql);
        $sth->execute(@$bind_ref);
    };
    if ($@) {
        _handle_db_error($@, $sql, $bind_ref, $op, $c);
    }

    return $op eq 'fetch_row' ? $sth->fetchrow_hashref($key_style)
         : $op eq 'fetch_all' ? do { my @rows; push @rows, $_ while my $r = $sth->fetchrow_hashref($key_style); \@rows }
         : 1;
}

# -----------------------------------
# DB error handler with email
# -----------------------------------
sub _handle_db_error {
    my ($error, $sql, $bind_ref, $op, $c) = @_;

    my $caller_info = join("\n", map { "\t$_" } _get_stack_trace());

    my $body = "<p>Database operation <b>$op</b> failed.</p>"
             . "<p>Error: $error</p>"
             . "<p>SQL: $sql</p>"
             . "<p>Binds: " . join(", ", @$bind_ref) . "</p>"
             . "<p>Stack trace:<br>$caller_info</p>";

    if ($c && $c->config->{email}) {
        require Email::Stuffer;
        my $from    = $self->config->{email}{error}{from}    // 'noreply@travellerspalm.com';
        my $subject = $self->config->{email}{error}{subject} // "[" . ($self->config->{appname} // 'TravellersPalm') . "] Error at $url";

        Email::Stuffer->from($from)
                      ->to($ENV{EMAIL_USER})
                      ->subject($subject)
                      ->html_body($body)
                      ->transport($c->app->email_transport)
                      ->send;
    }

    die "Database error: $error";  # propagate
}

sub _get_stack_trace {
    my @trace;
    my $i = 1;
    while (my @caller = caller($i++)) {
        my ($package, $filename, $line, $subroutine) = @caller;
        push @trace, "$subroutine at $filename line $line";
    }
    return @trace;
}

1;
