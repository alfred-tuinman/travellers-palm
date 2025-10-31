#!/usr/bin/env perl

# Test script for OAuth2 email functionality
# Usage: perl test_oauth2_email.pl recipient@example.com

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

use TravellersPalm::Mailer::OAuth2;
use Email::Stuffer;

my $recipient = $ARGV[0] || $ENV{EMAIL_USER};

unless ($recipient) {
    die "Usage: $0 recipient\@example.com\n";
}

print "Testing OAuth2 email to: $recipient\n";

# Test direct sending
eval {
    my $oauth_mailer = TravellersPalm::Mailer::OAuth2->new();
    
    print "Sending test email using direct method...\n";
    $oauth_mailer->send_email(
        to      => $recipient,
        subject => 'OAuth2 Test - Direct Method',
        body    => "This is a test email sent using OAuth2 authentication.\n\nSent at: " . localtime(),
        body_type => 'text',
    );
    print "✅ Direct method: SUCCESS\n";
};
if ($@) {
    print "❌ Direct method: FAILED - $@\n";
}

# Test Email::Stuffer integration
eval {
    my $oauth_mailer = TravellersPalm::Mailer::OAuth2->new();
    my $transport = $oauth_mailer->get_transport();
    
    print "Sending test email using Email::Stuffer...\n";
    Email::Stuffer->from($ENV{EMAIL_USER})
                  ->to($recipient)
                  ->subject('OAuth2 Test - Email::Stuffer')
                  ->text_body("This is a test email sent using OAuth2 authentication via Email::Stuffer.\n\nSent at: " . localtime())
                  ->transport($transport)
                  ->send;
    print "✅ Email::Stuffer method: SUCCESS\n";
};
if ($@) {
    print "❌ Email::Stuffer method: FAILED - $@\n";
}

print "\nTest completed!\n";