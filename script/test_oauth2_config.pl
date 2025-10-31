#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";

# Load environment variables from .env file
sub load_env_file {
    my $env_file = "$Bin/../.env";
    return unless -f $env_file;
    
    open my $fh, '<', $env_file or return;
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /^\s*#/ || $line =~ /^\s*$/;
        
        my ($key, $value) = split /=/, $line, 2;
        next unless defined $key && defined $value;
        
        $key =~ s/^\s+|\s+$//g;
        $value =~ s/^\s+|\s+$//g;
        $value =~ s/^["']|["']$//g;  # Remove quotes
        
        $ENV{$key} = $value;
    }
    close $fh;
}

# Load .env file
load_env_file();

print "=== OAuth2 Configuration Test ===\n\n";

# Check OAuth2 environment variables
print "OAuth2 Configuration:\n";
print "CLIENT_ID: " . ($ENV{EMAIL_CLIENT_ID} ? "✓ SET" : "✗ NOT SET") . "\n";
print "CLIENT_SECRET: " . ($ENV{EMAIL_CLIENT_SECRET} ? "✓ SET" : "✗ NOT SET") . "\n";
print "REFRESH_TOKEN: " . ($ENV{EMAIL_REFRESH_TOKEN} ? "✓ SET" : "✗ NOT SET") . "\n";
print "EMAIL_USER: " . ($ENV{EMAIL_USER} || "NOT SET") . "\n";
print "EMAIL_HOST: " . ($ENV{EMAIL_HOST} || "NOT SET") . "\n";
print "EMAIL_PORT: " . ($ENV{EMAIL_PORT} || "NOT SET") . "\n";

my $oauth_configured = $ENV{EMAIL_CLIENT_ID} && $ENV{EMAIL_CLIENT_SECRET} && $ENV{EMAIL_REFRESH_TOKEN};
print "\nOAuth2 Status: " . ($oauth_configured ? "✓ CONFIGURED" : "✗ NOT CONFIGURED") . "\n";

if ($oauth_configured) {
    print "\n=== Testing OAuth2 Connection ===\n";
    
    eval {
        require TravellersPalm::Mailer::OAuth2;
        
        my $oauth_mailer = TravellersPalm::Mailer::OAuth2->new();
        print "OAuth2 mailer created successfully\n";
        
        # Test getting access token
        my $access_token = $oauth_mailer->get_access_token();
        print "Access token obtained: " . substr($access_token, 0, 20) . "...\n" if $access_token;
        
        print "✓ OAuth2 configuration appears to be working!\n";
        
    } or do {
        print "✗ OAuth2 test failed: $@\n";
    };
} else {
    print "\n⚠ OAuth2 is not configured. Email will fall back to basic SMTP.\n";
    print "Please set EMAIL_CLIENT_ID, EMAIL_CLIENT_SECRET, and EMAIL_REFRESH_TOKEN in .env file.\n";
}

print "\n=== Test Complete ===\n";