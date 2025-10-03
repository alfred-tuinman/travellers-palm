package TravellersPalm::Database::Connector;

use strict;
use warnings;
use Carp qw(croak);
use Dancer2::Plugin::Database ();

#--------------------------------------------
# Connection helpers
#--------------------------------------------
sub dbh {
    my ($name) = @_;
    $name //= 'sqlserver';

    # Use overridden DB handle inside txn if present
    if ($ENV{DB_CONN_OVERRIDE}) {
        return $ENV{DB_CONN_OVERRIDE};
    }

    my $dbh = Dancer2::Plugin::Database::database($name)
      or croak "Cannot get DB handle for connection '$name'";

    return $dbh;
}

sub database  { return dbh(@_) }
sub main_dbh  { return dbh('sqlserver') }
sub users_dbh { return dbh('users') }

#--------------------------------------------
# Fetch helpers (transaction-safe)
#--------------------------------------------
sub fetch_all {
    my ($sql, $bind, $conn) = @_;
    $conn //= 'sqlserver';
    $bind //= [];

    my $dbh = dbh($conn);
    return $dbh->selectall_arrayref($sql, { Slice => {} }, @$bind);
}

sub fetch_row {
    my ($sql, $bind, $conn, $key_case) = @_;
    $conn     //= 'sqlserver';
    $bind     //= [];
    $key_case //= 'NAME';

    my $dbh = dbh($conn);
    my $row = $dbh->selectrow_hashref($sql, undef, @$bind);

    if ($key_case eq 'NAME_lc' && $row) {
        my %lc = map { lc($_) => $row->{$_} } keys %$row;
        return \%lc;
    }
    return $row;
}

#--------------------------------------------
# Execute SQL (transaction-safe)
#--------------------------------------------
sub do_sql {
    my ($sql, $bind, $conn) = @_;
    $conn //= 'sqlserver';
    $bind //= [];

    my $dbh = dbh($conn);
    return $dbh->do($sql, undef, @$bind);
}

#--------------------------------------------
# Transaction wrapper
#--------------------------------------------
sub txn {
    my ($code, $conn) = @_;
    $conn //= 'sqlserver';
    my $dbh = dbh($conn);

    my $ok = eval {
        local $ENV{DB_CONN_OVERRIDE} = $dbh;  # override dbh() inside transaction
        $dbh->begin_work;
        $code->($dbh);  # inside here, fetch_all/fetch_row/do_sql use the same $dbh
        $dbh->commit;
        1;
    };

    if (!$ok) {
        my $err = $@ || 'Unknown error';
        eval { $dbh->rollback };
        die "Transaction failed: $err";
    }

    return 1;
}

#--------------------------------------------
# DML helpers using do_sql (transaction-safe)
#--------------------------------------------
sub insert {
    my ($table, $data, $conn) = @_;
    $conn //= 'sqlserver';
    croak "insert() requires a table name" unless $table;
    croak "insert() requires a hashref of data" unless ref $data eq 'HASH';

    my @cols  = keys %$data;
    my @place = map {'?'} @cols;
    my @bind  = @{$data}{@cols};

    my $sql = sprintf(
        "INSERT INTO %s (%s) VALUES (%s)",
        $table,
        join(', ', @cols),
        join(', ', @place)
    );

    return do_sql($sql, \@bind, $conn);
}

sub update {
    my ($table, $data, $where, $conn) = @_;
    $conn //= 'sqlserver';
    croak "update() requires a table name" unless $table;
    croak "update() requires a hashref of data" unless ref $data eq 'HASH';
    croak "update() requires a where condition" unless ref $where eq 'HASH';

    my @set_cols  = keys %$data;
    my @set_bind  = @{$data}{@set_cols};
    my @set_parts = map { "$_ = ?" } @set_cols;

    my @where_cols  = keys %$where;
    my @where_bind  = @{$where}{@where_cols};
    my @where_parts = map { "$_ = ?" } @where_cols;

    my $sql = sprintf(
        "UPDATE %s SET %s WHERE %s",
        $table,
        join(', ', @set_parts),
        join(' AND ', @where_parts)
    );

    return do_sql($sql, [ @set_bind, @where_bind ], $conn);
}

sub delete {
    my ($table, $where, $conn) = @_;
    $conn //= 'sqlserver';
    croak "delete() requires a table name" unless $table;
    croak "delete() requires a where condition" unless ref $where eq 'HASH';

    my @where_cols  = keys %$where;
    my @where_bind  = @{$where}{@where_cols};
    my @where_parts = map { "$_ = ?" } @where_cols;

    my $sql = sprintf(
        "DELETE FROM %s WHERE %s",
        $table,
        join(' AND ', @where_parts)
    );

    return do_sql($sql, \@where_bind, $conn);
}

1;
