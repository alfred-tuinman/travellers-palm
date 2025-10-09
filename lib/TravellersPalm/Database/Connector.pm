package TravellersPalm::Database::Connector;
use strict;
use warnings;
use Carp qw(croak);
use DBI;
use Mojo::Base -base;

our @EXPORT_OK = qw{
                  dbh 
                  database 
                  main_dbh 
                  fetch_all 
                  fetch_row 
                  do_sql 
                  txn 
                  insert 
                  update 
                  delete
                  };

#--------------------------------------------
# DB handle cache
#--------------------------------------------
my $DBH;

#--------------------------------------------
# Get DB handle from Mojolicious config
#--------------------------------------------
sub dbh {
    my ($class, $c) = @_;   # $c = Mojolicious controller or app
    croak "Mojolicious object required" unless $c;

    return $DBH if $DBH;

    my $db_config = $c->app->config->{db} // croak "DB config missing in config.conf";
    my $dsn      = $db_config->{dsn}      // croak "dsn missing in db config";
    my $username = $db_config->{username} // '';
    my $password = $db_config->{password} // '';

    $DBH = DBI->connect(
        $dsn, $username, $password,
        { RaiseError => 1, PrintError => 1, AutoCommit => 1, sqlite_unicode => 1 }
    ) or croak "Cannot connect to database: $DBI::errstr";

    return $DBH;
}

#--------------------------------------------
# Convenience aliases
#--------------------------------------------
sub database  { shift->dbh(@_) }
sub main_dbh  { shift->dbh(@_) }

#--------------------------------------------
# Fetch helpers
#--------------------------------------------
sub fetch_all {
    my ($class, $sql, $bind, $c) = @_;
    $bind //= [];
    return $class->dbh($c)->selectall_arrayref($sql, { Slice => {} }, @$bind);
}

sub fetch_row {
    my ($class, $sql, $bind, $c, $key_case) = @_;
    $bind     //= [];
    $key_case //= 'NAME';

    my $row = $class->dbh($c)->selectrow_hashref($sql, undef, @$bind);

    if ($key_case eq 'NAME_lc' && $row) {
        my %lc = map { lc($_) => $row->{$_} } keys %$row;
        return \%lc;
    }
    return $row;
}

sub do_sql {
    my ($class, $sql, $bind, $c) = @_;
    $bind //= [];
    return $class->dbh($c)->do($sql, undef, @$bind);
}

#--------------------------------------------
# Transaction wrapper
#--------------------------------------------
sub txn {
    my ($class, $c, $code) = @_;
    my $dbh = $class->dbh($c);

    my $ok = eval {
        $dbh->begin_work;
        $code->($dbh);
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
# DML helpers
#--------------------------------------------
sub insert {
    my ($class, $table, $data, $c) = @_;
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

    return $class->do_sql($sql, \@bind, $c);
}

sub update {
    my ($class, $table, $data, $where, $c) = @_;
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

    return $class->do_sql($sql, [ @set_bind, @where_bind ], $c);
}

sub delete {
    my ($class, $table, $where, $c) = @_;
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

    return $class->do_sql($sql, \@where_bind, $c);
}

1;
