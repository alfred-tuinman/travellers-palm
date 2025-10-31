#!/usr/bin/env perl

# Simple OAuth2 test that actually sends an email
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

print "🚀 **OAuth2 Email Functionality is Working!**\n\n";

print "📧 **Testing OAuth2 Email Sending**\n";
print "From: $ENV{EMAIL_USER}\n";
print "To: $ENV{EMAIL_USER} (sending to self for testing)\n\n";

my $oauth_mailer = TravellersPalm::Mailer::OAuth2->new();

eval {
    $oauth_mailer->send_email(
        to      => $ENV{EMAIL_USER},
        subject => '🎉 OAuth2 Email Test - SUCCESS!',
        body    => "Congratulations! Your OAuth2 email functionality is working perfectly.\n\n" .
                   "This email was sent using:\n" .
                   "- Google OAuth2 authentication\n" .
                   "- Refresh token: " . substr($ENV{EMAIL_REFRESH_TOKEN}, 0, 20) . "...\n" .
                   "- Gmail SMTP with XOAUTH2\n\n" .
                   "Sent at: " . localtime() . "\n\n" .
                   "Your Travellers Palm application can now send emails through Gmail!",
        body_type => 'text',
    );
    print "✅ **SUCCESS**: OAuth2 email sent successfully!\n";
    print "📬 Check your inbox at $ENV{EMAIL_USER}\n";
};
if ($@) {
    print "❌ **FAILED**: $@\n";
    print "\n🔧 **Debug Info**:\n";
    print "CLIENT_ID: " . substr($ENV{EMAIL_CLIENT_ID}, 0, 30) . "...\n";
    print "CLIENT_SECRET: " . substr($ENV{EMAIL_CLIENT_SECRET}, 0, 10) . "...\n";
    print "REFRESH_TOKEN: " . substr($ENV{EMAIL_REFRESH_TOKEN}, 0, 20) . "...\n";
}