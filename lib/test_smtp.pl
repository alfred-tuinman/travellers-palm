#!/usr/bin/env perl

use strict;
use warnings;
use Net::SMTP;

print "Testing Gmail SMTP connection...\n";

my $smtp = Net::SMTP->new(
    'smtp.gmail.com',
    Port => 587,
    Timeout => 30,
    Debug => 1
);

if ($smtp) {
    print "✅ Successfully connected to smtp.gmail.com:587\n";
    
    # Test STARTTLS
    if ($smtp->starttls()) {
        print "✅ STARTTLS successful\n";
    } else {
        print "❌ STARTTLS failed\n";
    }
    
    $smtp->quit();
} else {
    print "❌ Failed to connect to smtp.gmail.com:587\n";
    print "Error: $!\n";
}