#!/usr/bin/env perl

# Debug OAuth2 credentials
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

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
}

print "=== OAuth2 Debug Information ===\n";
print "CLIENT_ID: " . ($ENV{EMAIL_CLIENT_ID} || "NOT SET") . "\n";
print "CLIENT_SECRET: " . ($ENV{EMAIL_CLIENT_SECRET} || "NOT SET") . "\n";
print "REFRESH_TOKEN: " . ($ENV{EMAIL_REFRESH_TOKEN} || "NOT SET") . "\n";
print "EMAIL_USER: " . ($ENV{EMAIL_USER} || "NOT SET") . "\n";

use HTTP::Tiny;
use JSON;

print "\n=== Testing HTTP::Tiny post_form ===\n";

my $http = HTTP::Tiny->new(timeout => 30);

my $response = $http->post_form('https://oauth2.googleapis.com/token', {
    client_id     => $ENV{EMAIL_CLIENT_ID},
    client_secret => $ENV{EMAIL_CLIENT_SECRET},
    refresh_token => $ENV{EMAIL_REFRESH_TOKEN},
    grant_type    => 'refresh_token',
});

print "Status: $response->{status} $response->{reason}\n";
print "Content: $response->{content}\n";

if ($response->{success}) {
    my $data = eval { decode_json($response->{content}) };
    if ($data && $data->{access_token}) {
        print "✅ SUCCESS: Got access token (length: " . length($data->{access_token}) . ")\n";
    } else {
        print "❌ ERROR: Could not parse response\n";
    }
} else {
    print "❌ ERROR: HTTP request failed\n";
}