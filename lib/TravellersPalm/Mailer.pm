package TravellersPalm::Mailer;

use strict;
use warnings;
use Email::Sender::Transport::SMTP;
use Email::Sender::Transport;
use TravellersPalm::Mailer::OAuth2;

sub setup {
    my ($self) = @_;

    # Check if OAuth2 is configured
    # Temporarily disable OAuth2 due to missing dependencies
    my $use_oauth2 = 0; # $ENV{EMAIL_CLIENT_ID} && $ENV{EMAIL_CLIENT_SECRET} && $ENV{EMAIL_REFRESH_TOKEN};
    
    my $transport;
    
    if ($use_oauth2) {
        # Use OAuth2 for Gmail with fallback
        $self->log->debug("Setting up OAuth2 email transport for Gmail");
        eval {
            my $oauth_mailer = TravellersPalm::Mailer::OAuth2->new();
            $transport = $oauth_mailer->get_transport();
            $self->log->debug("OAuth2 transport created successfully");
        };
        
        if ($@) {
            $self->log->warn("OAuth2 transport setup failed: $@");
            $self->log->debug("Falling back to basic SMTP authentication");
            $use_oauth2 = 0;  # Force fallback
        }
    }
    
    if (!$use_oauth2 || !$transport) {
        # Use a simple logging transport for development
        $self->log->debug("Setting up simple logging email transport");
        
        # Create a minimal transport that just logs emails
        $transport = TravellersPalm::Mailer::LogTransport->new($self->log);
    }

    $self->helper(email_transport => sub { $transport });
    $self->helper(oauth_mailer => sub { 
        return unless $use_oauth2;
        return TravellersPalm::Mailer::OAuth2->new();
    });

    my $auth_method = $use_oauth2 ? 'OAuth2' : 'Basic SMTP';
    $self->log->debug("Email transport initialized using $auth_method for host: " . ($ENV{EMAIL_HOST} || 'default'));
}

# Simple logging transport for development
package TravellersPalm::Mailer::LogTransport;
use base 'Email::Sender::Transport';

sub new {
    my ($class, $logger) = @_;
    return bless { logger => $logger }, $class;
}

sub send_email {
    my ($self, $email, $env) = @_;
    
    # Extract email details safely
    my $from = $env->{from} || 'unknown';
    if (ref($from) eq 'ARRAY') {
        $from = $from->[0] || 'unknown';
    }
    
    my $to_list = $env->{to} || ['unknown'];
    my $to = ref($to_list) eq 'ARRAY' ? join(', ', @$to_list) : $to_list;
    
    my $subject = 'no subject';
    eval {
        my $subj_header = $email->get_header('Subject');
        if (ref($subj_header) eq 'ARRAY') {
            $subject = $subj_header->[0] || 'no subject';
        } elsif ($subj_header) {
            $subject = $subj_header;
        }
    };
    
    # Get body content
    my $body = '';
    eval {
        if ($email->can('body_str')) {
            $body = $email->body_str();
        } elsif ($email->can('body')) {
            $body = $email->body();
        } else {
            $body = "Email body not accessible";
        }
    };
    $body = substr($body, 0, 200) . '...' if length($body) > 200;
    
    # Log the email
    $self->{logger}->info("📧 EMAIL LOGGED (not sent):");
    $self->{logger}->info("From: $from");
    $self->{logger}->info("To: $to");
    $self->{logger}->info("Subject: $subject");
    $self->{logger}->info("Body preview: $body");
    
    # Return success object expected by Email::Sender
    require Email::Sender::Success;
    return Email::Sender::Success->new();
}

1;
