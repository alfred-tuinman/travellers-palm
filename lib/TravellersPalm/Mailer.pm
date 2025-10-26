package TravellersPalm::Mailer;

use strict;
use warnings;
use Email::Sender::Transport::SMTP;

sub setup {
    my ($self) = @_;

    my $smtp_cfg = $self->config->{email}{smtp} // {
        host          => $ENV{EMAIL_HOST},
        port          => $ENV{EMAIL_PORT},
        sasl_username => $ENV{EMAIL_USER},
        sasl_password => $ENV{EMAIL_PASS},
        ssl           => $ENV{EMAIL_TLS} ? 1 : 0,
    };

    my $transport = Email::Sender::Transport::SMTP->new($smtp_cfg);
    $self->helper(email_transport => sub { $transport });

    $self->log->debug("Email transport initialized for host: $smtp_cfg->{host}");
}

1;
