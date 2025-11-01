#!/usr/bin/env perl

# Database migration script to add 2FA support to users table
# This script adds totp_secret and totp_enabled columns to the users table

use strict;
use warnings;
use DBI;
use File::Spec;

# Database paths
my $source_db = File::Spec->catfile('localdb', 'users.db');
my $target_db = File::Spec->catfile('data', 'users.db');

print "=== 2FA Database Migration ===\n";

# Function to add 2FA columns to a database
sub add_2fa_columns {
    my ($db_path) = @_;
    
    print "Updating database: $db_path\n";
    
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_path", "", "", {
        RaiseError => 1,
        AutoCommit => 1,
        PrintError => 1,
    }) or die "Cannot connect to $db_path: $DBI::errstr";
    
    # Check if columns already exist
    my $sth = $dbh->prepare("PRAGMA table_info(users)");
    $sth->execute();
    
    my %existing_columns;
    while (my $row = $sth->fetchrow_hashref) {
        $existing_columns{$row->{name}} = 1;
    }
    
    # Add totp_secret column if it doesn't exist
    unless ($existing_columns{totp_secret}) {
        print "  Adding totp_secret column...\n";
        $dbh->do("ALTER TABLE users ADD COLUMN totp_secret TEXT");
    } else {
        print "  totp_secret column already exists\n";
    }
    
    # Add totp_enabled column if it doesn't exist
    unless ($existing_columns{totp_enabled}) {
        print "  Adding totp_enabled column...\n";
        $dbh->do("ALTER TABLE users ADD COLUMN totp_enabled INTEGER DEFAULT 0");
    } else {
        print "  totp_enabled column already exists\n";
    }
    
    $dbh->disconnect;
    print "  Database updated successfully!\n";
}

# Update source database (localdb)
if (-f $source_db) {
    add_2fa_columns($source_db);
} else {
    print "Source database not found: $source_db\n";
}

# Update runtime database (data) if it exists
if (-f $target_db) {
    add_2fa_columns($target_db);
} else {
    print "Runtime database not found: $target_db (will be created on next startup)\n";
}

print "\n=== Migration Complete ===\n";
print "2FA columns have been added to the users table.\n";
print "You can now enable 2FA for individual users.\n";