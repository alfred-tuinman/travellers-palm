package TravellersPalm::Database::Connector;
use strict;
use warnings;

use Dancer2 appname => 'TravellersPalm'; 

use Carp qw(croak);


# ------------------------------------------------------------
# Get a handle for a named connection (defaults to 'sqlserver')
# ------------------------------------------------------------
sub dbh {
    my ($name) = @_;
    $name //= 'sqlserver';

    my $dbh = eval { database($name) };
    croak "Cannot get DB handle for connection '$name': $@" if $@ || !$dbh;

    return $dbh;
}

# In case of multiple databases, just add the servername as the third optional argumnent
sub main_dbh  { return dbh('sqlserver') };
sub users_dbh { return dbh('users') };


# ------------------------------------------------------------
# Run a SELECT that returns all rows as arrayref of hashrefs
# ------------------------------------------------------------
sub fetch_all {
    my ($sql, $bind, $conn) = @_;
    $conn //= 'sqlserver';
    $bind //= [];

    my $dbh = dbh($conn);
    my $rows = $dbh->selectall_arrayref($sql, { Slice => {} }, @$bind);

    return $rows;
}

# ------------------------------------------------------------
# Run a SELECT that returns just the first row
# $sql → 1️⃣ first argument
# $bind → 2️⃣ second argument (arrayref of bind values)
# $conn → 3️⃣ third argument (connection name, optional)
# $key_case → 4️⃣ fourth argument (optional: 'NAME_lc', 'NAME_uc', etc.)
# ------------------------------------------------------------
sub fetch_row {
    my ($sql, $bind, $conn, $key_case) = @_;
    $conn     //= 'sqlserver';
    $bind     //= [];
    $key_case //= 'NAME';    # default (unchanged)

    my $dbh = dbh($conn);
    return $dbh->selectrow_hashref($sql, @$bind, $key_case);
}


# ------------------------------------------------------------
# Run an INSERT / UPDATE / DELETE
# ------------------------------------------------------------
sub do_sql {
    my ($sql, $bind, $conn) = @_;
    $conn //= 'sqlserver';
    $bind //= [];

    my $dbh = dbh($conn);
    my $rv = $dbh->do($sql, undef, @$bind);

    return $rv;
}

# ------------------------------------------------------------
# Run something inside a transaction
# Usage:
#   Connector::txn(sub {
#       my $dbh = shift;
#       $dbh->do(...);
#       $dbh->do(...);
#   });
# ------------------------------------------------------------
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
