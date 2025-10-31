package TravellersPalm::Mailer;

use strict;
use warnings;
use Email::Sender::Transport::SMTP;
use TravellersPalm::Mailer::OAuth2;

sub setup {
    my ($self) = @_;

    # Check if OAuth2 is configured
    my $use_oauth2 = $ENV{EMAIL_CLIENT_ID} && $ENV{EMAIL_CLIENT_SECRET} && $ENV{EMAIL_REFRESH_TOKEN};
    
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
        # Fall back to basic SMTP authentication
        $self->log->debug("Setting up basic SMTP email transport");
        my $smtp_cfg = $self->config->{email}{smtp} // {
            host          => $ENV{EMAIL_HOST},
            port          => $ENV{EMAIL_PORT},
            sasl_username => $ENV{EMAIL_USER},
            sasl_password => $ENV{EMAIL_PASS},
            ssl           => $ENV{EMAIL_SSL} ? 1 : 0,
            tls           => $ENV{EMAIL_TLS} ? 1 : 0,
        };
        $transport = Email::Sender::Transport::SMTP->new($smtp_cfg);
    }

    $self->helper(email_transport => sub { $transport });
    $self->helper(oauth_mailer => sub { 
        return unless $use_oauth2;
        return TravellersPalm::Mailer::OAuth2->new();
    });

    my $auth_method = $use_oauth2 ? 'OAuth2' : 'Basic SMTP';
    $self->log->debug("Email transport initialized using $auth_method for host: " . ($ENV{EMAIL_HOST} || 'default'));
}

1;
