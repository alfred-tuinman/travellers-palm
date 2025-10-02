package TravellersPalm::Database::Connector;

use strict;
use warnings;

use Carp qw(croak); 
use Dancer2::Plugin::Database; 

sub dbh {
    my ($name) = @_;
    $name //= 'sqlserver';

    my $dbh = database($name);   # NOT Dancer2::Plugin::Database::database($name)
    croak "Cannot get DB handle for connection '$name'" unless $dbh;

    return $dbh;
}


sub main_dbh  { return dbh('sqlserver') }
sub users_dbh { return dbh('users') }

# Fetch all rows
sub fetch_all {
    my ($sql, $bind, $conn) = @_;
    $conn //= 'sqlserver';
    $bind //= [];

    my $dbh = dbh($conn);
    return $dbh->selectall_arrayref($sql, { Slice => {} }, @$bind);
}

# Fetch first row
sub fetch_row {
    my ($sql, $bind, $conn, $key_case) = @_;
    $conn     //= 'sqlserver';
    $bind     //= [];
    $key_case //= 'NAME';

    my $dbh = dbh($conn);

    # Proper DBI call
    my $row = $dbh->selectrow_hashref($sql, @$bind);

    # If you need lowercase keys
    if ($key_case eq 'NAME_lc' && $row) {
        my %lc = map { lc($_) => $row->{$_} } keys %$row;
        return \%lc;
    }
    return $row;
}

# Execute DML
sub do_sql {
    my ($sql, $bind, $conn) = @_;
    $conn //= 'sqlserver';
    $bind //= [];

    my $dbh = dbh($conn);
    return $dbh->do($sql, undef, @$bind);
}

# Run transaction
sub txn {
    my ($code, $conn) = @_;
    $conn //= 'sqlserver';
    my $dbh = dbh($conn);

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

1;