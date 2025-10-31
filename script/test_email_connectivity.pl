#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";

# Simple connectivity test
print "=== Email Connectivity Test ===\n\n";

# Test basic network connectivity to Gmail
print "Testing basic connectivity to smtp.gmail.com:587...\n";
eval {
    require IO::Socket::INET;
    my $socket = IO::Socket::INET->new(
        PeerAddr => 'smtp.gmail.com',
        PeerPort => 587,
        Proto    => 'tcp',
        Timeout  => 10,
    );
    if ($socket) {
        print "✓ Basic TCP connection to Gmail SMTP successful\n";
        $socket->close();
    } else {
        print "✗ Cannot connect to Gmail SMTP: $!\n";
    }
};
if ($@) {
    print "✗ Network test failed: $@\n";
}

# Test DNS resolution
print "\nTesting DNS resolution for smtp.gmail.com...\n";
eval {
    require Socket;
    my $addr = Socket::inet_aton('smtp.gmail.com');
    if ($addr) {
        my $ip = Socket::inet_ntoa($addr);
        print "✓ DNS resolution successful: smtp.gmail.com -> $ip\n";
    } else {
        print "✗ DNS resolution failed\n";
    }
};
if ($@) {
    print "✗ DNS test failed: $@\n";
}

# Test SSL/TLS capabilities
print "\nTesting SSL/TLS support...\n";
eval {
    require IO::Socket::SSL;
    print "✓ IO::Socket::SSL is available\n";
    
    require Net::SMTP;
    print "✓ Net::SMTP is available\n";
    
    # Try to create an SMTP connection (without authentication)
    my $smtp = Net::SMTP->new(
        'smtp.gmail.com',
        Port    => 587,
        Timeout => 10,
        Debug   => 0,
        SSL     => 0,
    );
    
    if ($smtp) {
        print "✓ Initial SMTP connection successful\n";
        
        # Test STARTTLS
        if ($smtp->starttls()) {
            print "✓ STARTTLS successful\n";
        } else {
            print "✗ STARTTLS failed: " . ($smtp->message || 'Unknown error') . "\n";
        }
        
        $smtp->quit();
    } else {
        print "✗ SMTP connection failed: $!\n";
    }
};
if ($@) {
    print "✗ SSL/TLS test failed: $@\n";
}

print "\n=== Test Complete ===\n";