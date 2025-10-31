#!/usr/bin/env perl

# Simple OAuth2 email test
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

print "Loading environment...\n";

# Load environment variables
if (-f "$FindBin::Bin/../.env") {
    open my $fh, '<', "$FindBin::Bin/../.env" or die "Cannot open .env: $!";
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /^\s*#/ || $line =~ /^\s*$/;
        if ($line =~ /^([^=]+)=(.*)$/) {
            $ENV{$1} = $2;
        }
    }
    close $fh;
    print "Environment loaded successfully\n";
}

print "Required env vars:\n";
print "EMAIL_CLIENT_ID: " . ($ENV{EMAIL_CLIENT_ID} ? "SET" : "NOT SET") . "\n";
print "EMAIL_CLIENT_SECRET: " . ($ENV{EMAIL_CLIENT_SECRET} ? "SET" : "NOT SET") . "\n";
print "EMAIL_REFRESH_TOKEN: " . ($ENV{EMAIL_REFRESH_TOKEN} ? "SET" : "NOT SET") . "\n";
print "EMAIL_USER: " . ($ENV{EMAIL_USER} || "NOT SET") . "\n";

print "\nLoading OAuth2 module...\n";
eval {
    require TravellersPalm::Mailer::OAuth2;
    print "OAuth2 module loaded successfully\n";
};
if ($@) {
    print "Failed to load OAuth2 module: $@\n";
    exit 1;
}

print "\nCreating OAuth2 mailer...\n";
my $oauth_mailer = eval {
    TravellersPalm::Mailer::OAuth2->new();
};
if ($@) {
    print "Failed to create OAuth2 mailer: $@\n";
    exit 1;
}
print "OAuth2 mailer created successfully\n";

print "\nTesting access token retrieval...\n";
my $token = eval {
    $oauth_mailer->get_access_token();
};
if ($@) {
    print "Failed to get access token: $@\n";
    exit 1;
}
print "Access token retrieved successfully (length: " . length($token) . ")\n";

print "\n✅ All OAuth2 tests passed!\n";