package TravellersPalm::Database::Core::Connector;

use strict;
use warnings;
use DBI;
use Data::Dumper;
use Exporter 'import';
use POSIX qw(strftime);
use Email::Sender::Transport::SMTP;
use Email::Stuffer;

our @EXPORT_OK = qw(fetch_row fetch_all insert_row update_row delete_row);

my ($app, %handles);

sub setup {
    my ($class, $app_ref) = @_;
    die "No app reference provided to Connector" unless $app_ref;
    $app = $app_ref;
    $app->log->debug("Calling DB setup, app=$app") if $app->can('log');
    return 1;
}

sub _log_sql {
    my ($sql, $bind_ref, $caller_self) = @_;
    $bind_ref ||= [];

    # Mask or truncate potentially large/sensitive bind values before logging
    my @binds_escaped = map {
        if (!defined $_) { 'NULL' }
        elsif ($_ =~ /^\d+(\.\d+)?$/) { $_ }
        else {
            my $v = "'" . $_ . "'";
            # Mask common-looking emails to avoid full leakage
            if ($v =~ /'([^@]{1,})@(.+)'/) {
                $v = "'***@" . $2 . "'";
            }
            # Truncate overly long values
            if (length($v) > 120) {
                $v = "'<' . 'LONG_DATA_' . length($v) . '>' . "'";
            }
            $v
        }
    } @$bind_ref;
    my $binds_str = @binds_escaped ? join(", ", @binds_escaped) : '(none)';

    my ($subroutine, $filename, $line) = _get_caller_info();

    my $route_info = '';
    if ($caller_self && ref $caller_self && $caller_self->can('req')) {
        my $req = $caller_self->req;
        $route_info = sprintf(" | route: %s", $req->url->to_string) if $req;
    }

    my $sql_formatted = $sql;
    $sql_formatted =~ s/^\s+|\s+$//g;
    $sql_formatted =~ s/\s+/ /g;
    $sql_formatted = "    $sql_formatted";

    my $msg = sprintf(
        "[SQL]\n%s\n | binds: %s | called from: %s at %s line %d%s",
        $sql_formatted,
        $binds_str,
        $subroutine,
        $filename,
        $line,
        $route_info
    );

    if ($app && $app->can('log')) {
        $app->log->debug($msg);
    } else {
        my $timestamp = scalar localtime;
        print STDERR "[$timestamp] [pid:$$] $msg\n";
    }
}

sub _get_caller_info {
    my $skip_frames = 1;
    while (my @caller = caller($skip_frames++)) {
        my ($package, $filename, $line, $subroutine) = @caller;
        next if $subroutine =~ /::_log_sql$/;
        next if $package =~ /^(Mojo|Mojolicious|DBI)/;
        next if $subroutine =~ /^(Mojo|Mojolicious|DBI)/;
        return ($subroutine, $filename, $line);
    }
    return ('unknown', 'unknown', 0);
}

sub dbh {
    my ($dbkey) = @_;
    die "Connector not setup" unless $app;

    my $config    = $app->config;
    my $databases = $config->{databases} || {};
    die "No databases in config" unless %$databases;

    # Determine which DB to use
    $dbkey //= $config->{main_database};
    $dbkey //= (keys %$databases)[0];  # fallback: first in config.yml
    die "No database config for '$dbkey'" unless exists $databases->{$dbkey};

    # Return cached handle if exists
    return $handles{$dbkey} if $handles{$dbkey};

    my $dbconf = $databases->{$dbkey};
    my $dsn    = $dbconf->{dsn}      // '';
    my $user   = $dbconf->{username} // '';
    my $pass   = $dbconf->{password} // '';
    my $params = $dbconf->{dbi_params} || {};

    # Default SQLite settings
    if ($dsn =~ /^dbi:SQLite/i) {
        $params->{sqlite_unicode} = 1 unless exists $params->{sqlite_unicode};
        $params->{RaiseError}     = 1 unless exists $params->{RaiseError};
        $params->{PrintError}     = 0 unless exists $params->{PrintError};
    }

    my $dbh = DBI->connect($dsn, $user, $pass, $params)
        or die "DB connect failed for '$dbkey': $DBI::errstr";

    $handles{$dbkey} = $dbh;

    eval { $app->log->debug("Connected to DB [$dbkey] dsn=$dsn") };

    return $dbh;
}

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

sub _handle_db_error {
    my ($error, $sql, $bind_ref, $op, $c) = @_;

    # Log full error details to app log (debug level) but send a minimal email to operators
    my $caller_info = join("\n", map { "\t$_" } _get_stack_trace());
    if ($app && $app->can('log')) {
        $app->log->error("DB error: $error");
        $app->log->debug("SQL: $sql");
        $app->log->debug("Binds: " . join(', ', map { defined $_ ? $_ : 'NULL' } @$bind_ref));
        $app->log->debug("Stack: $caller_info");
    }

    if ($c && $c->config->{email}) {
        my $url     = $c->req->url->path->to_string;
        my $from    = $c->config->{email}{error}{from}    // 'noreply@travellerspalm.com';
        my $subject = $c->config->{email}{error}{subject}
            // ( $c->config->{appname} // 'TravellersPalm') . " Error at $url";

        my $body = sprintf("Database operation %s failed. Error message: %s\nRoute: %s\nTime: %s",
            $op, $error, $url, scalar localtime );

        eval {
            Email::Stuffer->from($from)
                          ->to($ENV{EMAIL_USER})
                          ->subject($subject)
                          ->text_body($body)
                          ->transport($c->app->email_transport)
                          ->send;
        };
    }

    die "Database error: $error";
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
