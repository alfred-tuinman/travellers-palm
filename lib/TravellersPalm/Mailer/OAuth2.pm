package TravellersPalm::Mailer::OAuth2;

use strict;
use warnings;
use Email::Sender::Transport::SMTP;
use HTTP::Tiny;
use JSON;
use MIME::Base64;
use Net::SMTP;
use IO::Socket::SSL;
use URI::Escape qw(uri_escape);
use TravellersPalm::Mailer::OAuth2::Transport;

sub new {
    my ($class, %args) = @_;
    my $self = {
        client_id     => $args{client_id}     || $ENV{EMAIL_CLIENT_ID},
        client_secret => $args{client_secret} || $ENV{EMAIL_CLIENT_SECRET},
        refresh_token => $args{refresh_token} || $ENV{EMAIL_REFRESH_TOKEN},
        email_user    => $args{email_user}    || $ENV{EMAIL_USER},
        host          => $args{host}          || $ENV{EMAIL_HOST} || 'smtp.gmail.com',
        port          => $args{port}          || $ENV{EMAIL_PORT} || 587,
        _access_token => undef,
        _token_expires_at => 0,
    };
    return bless $self, $class;
}

sub get_access_token {
    my ($self) = @_;
    
    # Return cached token if still valid (with 5 minute buffer)
    if ($self->{_access_token} && time() < ($self->{_token_expires_at} - 300)) {
        return $self->{_access_token};
    }
    
    # Refresh the access token using HTTP::Tiny with manual form encoding
    my $http = HTTP::Tiny->new(timeout => 30, verify_SSL => 0);
    
    # Build form data exactly like curl does
    my $form_data = sprintf(
        "client_id=%s&client_secret=%s&refresh_token=%s&grant_type=refresh_token",
        uri_escape($self->{client_id}),
        uri_escape($self->{client_secret}),
        uri_escape($self->{refresh_token})
    );
    
    my $response = $http->post('https://oauth2.googleapis.com/token', {
        headers => { 'Content-Type' => 'application/x-www-form-urlencoded' },
        content => $form_data,
    });
    
    if (!$response->{success}) {
        die "Failed to refresh OAuth2 token: $response->{status} $response->{reason}\n" . 
            ($response->{content} || '');
    }
    
    my $data = eval { decode_json($response->{content}) };
    if ($@ || !$data->{access_token}) {
        die "Failed to parse OAuth2 token response: " . ($@ || "No access_token in response");
    }
    
    # Cache the token
    $self->{_access_token} = $data->{access_token};
    $self->{_token_expires_at} = time() + ($data->{expires_in} || 3600);
    
    return $self->{_access_token};
}

sub create_xoauth2_string {
    my ($self) = @_;
    
    my $access_token = $self->get_access_token();
    my $auth_string = sprintf("user=%s\x01auth=Bearer %s\x01\x01", 
                              $self->{email_user}, 
                              $access_token);
    
    return encode_base64($auth_string, '');
}

sub send_email {
    my ($self, %args) = @_;
    
    my $from = $args{from} || $self->{email_user};
    my $to = $args{to} or die "No 'to' address specified";
    my $subject = $args{subject} || '';
    my $body = $args{body} || '';
    my $body_type = $args{body_type} || 'text'; # 'text' or 'html'
    
    # Get OAuth2 authentication
    my $xoauth2_string = $self->create_xoauth2_string();
    
    my $smtp;
    my $max_retries = 3;
    my $retry_delay = 2;
    
    # First, test basic connectivity
    eval {
        require IO::Socket::INET;
        my $test_socket = IO::Socket::INET->new(
            PeerAddr => $self->{host},
            PeerPort => $self->{port},
            Proto    => 'tcp',
            Timeout  => 10,
        );
        unless ($test_socket) {
            die "Cannot establish basic TCP connection to $self->{host}:$self->{port}: $!";
        }
        $test_socket->close();
    };
    if ($@) {
        die "Pre-connection test failed: $@";
    }
    
    # Retry connection with exponential backoff
    for my $attempt (1..$max_retries) {
        eval {
            # Connect to Gmail SMTP with STARTTLS
            $smtp = Net::SMTP->new(
                $self->{host},
                Port    => $self->{port},
                Timeout => 30,
                Debug   => 0,
                SSL     => 0,  # Start without SSL, use STARTTLS
                Hello   => 'travellerspalm.com',  # Provide proper HELO
            );
            
            unless ($smtp) {
                die "Cannot connect to $self->{host}:$self->{port}: $! (attempt $attempt/$max_retries)";
            }
            
            # Start TLS
            unless ($smtp->starttls()) {
                my $msg = $smtp->message || 'Unknown STARTTLS error';
                die "STARTTLS failed: $msg (attempt $attempt/$max_retries)";
            }
            
            # Authenticate with XOAUTH2
            unless ($smtp->auth($self->{email_user}, $xoauth2_string, 'XOAUTH2')) {
                my $msg = $smtp->message || 'Unknown authentication error';
                die "XOAUTH2 authentication failed: $msg (attempt $attempt/$max_retries)";
            }
            
            1; # Success
        };
        
        if ($@) {
            my $error = $@;
            # Clean up any partial connection
            eval { $smtp->quit() if $smtp; };
            $smtp = undef;
            
            if ($attempt < $max_retries) {
                # Wait before retrying (exponential backoff)
                my $delay = $retry_delay * $attempt;
                sleep($delay);
                next;
            } else {
                die "Failed to connect after $max_retries attempts: $error";
            }
        } else {
            last; # Success, exit retry loop
        }
    }
    
    # Send the email with proper error handling
    eval {
        $smtp->mail($from) or die "MAIL command failed: " . $smtp->message;
        $smtp->to($to) or die "RCPT command failed: " . $smtp->message;
        
        $smtp->data() or die "DATA command failed: " . $smtp->message;
        
        # Send headers
        $smtp->datasend("From: $from\n");
        $smtp->datasend("To: $to\n");
        $smtp->datasend("Subject: $subject\n");
        
        if ($body_type eq 'html') {
            $smtp->datasend("Content-Type: text/html; charset=UTF-8\n");
        } else {
            $smtp->datasend("Content-Type: text/plain; charset=UTF-8\n");
        }
        
        $smtp->datasend("Date: " . localtime() . "\n");
        $smtp->datasend("\n"); # End headers
        
        # Send body
        $smtp->datasend($body);
        
        $smtp->dataend() or die "Failed to send message: " . $smtp->message;
        
        1; # Success
    };
    
    if ($@) {
        my $error = $@;
        # Always attempt to clean up the connection
        eval { $smtp->quit() if $smtp; };
        die "Email sending failed: $error";
    }
    
    # Clean disconnect
    $smtp->quit();
    
    return 1;
}

# Create a compatible transport for Email::Stuffer
sub get_transport {
    my ($self) = @_;
    
    return TravellersPalm::Mailer::OAuth2::Transport->new($self);
}

1;

__END__

=head1 NAME

TravellersPalm::Mailer::OAuth2 - OAuth2 Gmail authentication for Email::Sender

=head1 SYNOPSIS

    use TravellersPalm::Mailer::OAuth2;
    
    my $mailer = TravellersPalm::Mailer::OAuth2->new(
        client_id     => $ENV{EMAIL_CLIENT_ID},
        client_secret => $ENV{EMAIL_CLIENT_SECRET}, 
        refresh_token => $ENV{EMAIL_REFRESH_TOKEN},
        email_user    => $ENV{EMAIL_USER},
    );
    
    $mailer->send_email(
        to      => 'user@example.com',
        subject => 'Subject',
        body    => 'Message body',
    );

=head1 DESCRIPTION

This module provides OAuth2 authentication for Gmail SMTP using refresh tokens.
It automatically handles token refresh and provides both direct email sending
and Email::Sender transport compatibility.

=cut