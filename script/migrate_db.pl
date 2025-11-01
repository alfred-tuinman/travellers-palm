#!/usr/bin/env perl
use strict;
use warnings;
use DBI;

my $dbh = DBI->connect('dbi:SQLite:dbname=data/users.db','','', {RaiseError => 1});

# Check if columns already exist
my $sth = $dbh->prepare("PRAGMA table_info(users)");
$sth->execute();

my %columns;
while (my $row = $sth->fetchrow_hashref()) {
    $columns{$row->{name}} = 1;
}

# Add totp_secret column if it doesn't exist
unless ($columns{totp_secret}) {
    $dbh->do("ALTER TABLE users ADD COLUMN totp_secret VARCHAR(32)");
    print "Added totp_secret column\n";
}

# Add totp_enabled column if it doesn't exist
unless ($columns{totp_enabled}) {
    $dbh->do("ALTER TABLE users ADD COLUMN totp_enabled INTEGER DEFAULT 0");
    print "Added totp_enabled column\n";
}

print "Database migration completed successfully\n";