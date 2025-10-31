#!/usr/bin/env perl

# Direct test that mimics curl exactly
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

use HTTP::Tiny;
use JSON;
use URI::Escape qw(uri_escape);

print "=== Manual HTTP Request Test ===\n";

my $http = HTTP::Tiny->new(timeout => 30, verify_SSL => 0);

# Build form data exactly like curl
my $form_data = sprintf(
    "client_id=%s&client_secret=%s&refresh_token=%s&grant_type=refresh_token",
    uri_escape($ENV{EMAIL_CLIENT_ID}),
    uri_escape($ENV{EMAIL_CLIENT_SECRET}),
    uri_escape($ENV{EMAIL_REFRESH_TOKEN})
);

print "Form data: $form_data\n\n";

my $response = $http->post('https://oauth2.googleapis.com/token', {
    headers => { 'Content-Type' => 'application/x-www-form-urlencoded' },
    content => $form_data,
});

print "Status: $response->{status} $response->{reason}\n";
print "Headers: " . join(", ", map { "$_: $response->{headers}{$_}" } keys %{$response->{headers}}) . "\n";
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