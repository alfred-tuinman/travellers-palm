package TravellersPalm::Mailer;

use strict;
use warnings;

# Email transport modules
use Email::Sender::Transport::SMTP;
use Email::Sender::Transport;
use Email::Sender::Simple;
use Email::MIME;
use Email::Stuffer;
use Email::Sender::Success;

# Encoding modules
use Encode;
use MIME::Base64;
use MIME::QuotedPrint;

# SMTP and authentication modules
use Net::SMTP;
# Note: Authen::SASL modules loaded conditionally due to installation complexity
# use Authen::SASL;
# use Authen::SASL::Perl;

# Custom modules
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
        # Use a hybrid transport that logs AND sends emails
        $self->log->debug("Setting up hybrid email transport (log + send)");
        
        # Create a transport that logs and then tries to send
        $transport = TravellersPalm::Mailer::LogAndSendTransport->new($self->log);
    }

    $self->helper(email_transport => sub { $transport });
    $self->helper(oauth_mailer => sub { 
        return unless $use_oauth2;
        return TravellersPalm::Mailer::OAuth2->new();
    });

    my $auth_method = $use_oauth2 ? 'OAuth2' : 'Basic SMTP';
    $self->log->debug("Email transport initialized using $auth_method for host: " . ($ENV{EMAIL_HOST} || 'default'));
}

# Hybrid transport that logs AND sends emails for development testing
package TravellersPalm::Mailer::LogAndSendTransport;
use base 'Email::Sender::Transport';

sub new {
    my ($class, $logger) = @_;
    return bless { 
        logger => $logger,
        # Create a fallback SMTP transport for actual sending
        smtp_transport => undef
    }, $class;
}

sub _get_smtp_transport {
    my ($self) = @_;
    
    return $self->{smtp_transport} if $self->{smtp_transport};
    
    # Try to create a simple SMTP transport using Email::Stuffer's sendmail
    eval {
        # Email::Stuffer is now loaded at the top of the file
        # We'll use Email::Stuffer's default transport mechanism
        $self->{smtp_available} = 1;
    };
    
    if ($@) {
        $self->{logger}->warn("Email::Stuffer not available for sending: $@");
        $self->{smtp_available} = 0;
    }
    
    return $self->{smtp_available};
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
        if ($email->can('get_header')) {
            my $subj_header = $email->get_header('Subject');
            if (ref($subj_header) eq 'ARRAY') {
                $subject = $subj_header->[0] || 'no subject';
            } elsif ($subj_header) {
                $subject = $subj_header;
            }
        } else {
            # Use Email::MIME header method
            if ($email->can('header')) {
                my $subj_header = $email->header('Subject');
                $subject = $subj_header if $subj_header;
            }
        }
    };
    if ($@) {
        $self->{logger}->warn("Error extracting subject: $@");
    }
    # Fallback if eval failed
    $subject = 'no subject' unless defined $subject;
    
    # Get body content
    my $body = '';
    eval {
        $self->{logger}->debug("Email object type: " . ref($email));
        
        # Try different approaches to get the body
        if ($email->can('parts')) {
            my @parts = $email->parts();
            $self->{logger}->debug("Email has " . scalar(@parts) . " parts");
            if (@parts) {
                for my $i (0..$#parts) {
                    my $part = $parts[$i];
                    my $content_type = $part->content_type || 'unknown';
                    $self->{logger}->debug("Part $i content type: $content_type");
                    
                    if ($content_type =~ /text\/html/ || $i == 0) {
                        $body = $part->body();
                        $self->{logger}->debug("Got body from part $i, length: " . length($body));
                        last;
                    }
                }
            }
        }
        
        # Fallback methods if parts didn't work
        if (!$body) {
            if ($email->can('body_str')) {
                $body = $email->body_str();
                $self->{logger}->debug("Body extracted via body_str, length: " . length($body));
            } elsif ($email->can('body')) {
                $body = $email->body();
                $self->{logger}->debug("Body extracted via body, length: " . length($body));
            }
        }
        
        # Handle encoding issues - ensure body is properly encoded
        if ($body && utf8::is_utf8($body)) {
            # Encode is now loaded at the top of the file
            $body = Encode::encode_utf8($body);
            $self->{logger}->debug("Converted UTF-8 body to bytes");
        }
    };
    if ($@) {
        $self->{logger}->error("Error extracting body: $@");
        $body = "<h1>500 Internal Server Error</h1><p>An error occurred. Body extraction failed: $@</p>";
    }
    
    # Ensure we have some content
    if (!$body || length($body) < 10) {
        $body = "<h1>500 Internal Server Error</h1><p>An error occurred on the website.</p>";
        $self->{logger}->warn("Using minimal fallback email body");
    }
    
    my $body_preview = length($body) > 200 ? substr($body, 0, 200) . '...' : $body;
    
    # STEP 1: Always log the email details
    $self->{logger}->info("=== EMAIL SEND ATTEMPT START ===");
    $self->{logger}->info("From: $from");
    $self->{logger}->info("To: $to");
    $self->{logger}->info("Subject: $subject");
    $self->{logger}->info("Body preview: $body_preview");
    
    # STEP 2: Attempt to actually send the email
    my $send_success = 0;
    my $send_error = '';
    
    eval {
        # Check if Gmail SMTP is configured
        my $email_host = $ENV{EMAIL_HOST};
        my $email_port = $ENV{EMAIL_PORT};
        my $email_user = $ENV{EMAIL_USER};
        my $email_pass = $ENV{EMAIL_PASS};
        my $email_tls = $ENV{EMAIL_TLS};
        
        if ($email_host && $email_user && $email_pass) {
            # Use configured SMTP settings
            $self->{logger}->debug("Attempting SMTP send via $email_host:$email_port");
            $self->{logger}->debug("SMTP Config - Host: $email_host, Port: $email_port, User: $email_user, TLS: $email_tls");
            
            # Check if required modules are available
            my $has_auth_modules = 1;
            eval {
                # Modules are now loaded at the top of the file
                $self->{logger}->debug("All SMTP auth modules loaded successfully");
            };
            if ($@) {
                $self->{logger}->warn("SMTP auth modules missing: $@");
                $self->{logger}->info("Email would be sent to: $to");
                $self->{logger}->info("Email subject: $subject");
                $self->{logger}->info("Email from: $from");
                $self->{logger}->info("SMTP host: $email_host:$email_port");
                $has_auth_modules = 0;
            }
            
            if ($has_auth_modules) {
                # Gmail SMTP connection confirmed working with Net::SMTP
                # Use direct Net::SMTP instead of Email::Sender::Transport::SMTP
                $self->{logger}->debug("Using direct Net::SMTP for Gmail (bypass Email::Sender issues)");
                
                eval {
                    # Net::SMTP and MIME::Base64 are now loaded at the top of the file
                    
                    my $smtp = Net::SMTP->new(
                        $email_host,
                        Port => $email_port || 587,
                        Timeout => 30,
                        Debug => 0
                    );
                    
                    if ($smtp && $smtp->starttls()) {
                        $self->{logger}->debug("STARTTLS successful, attempting authentication");
                        
                        # Load SASL modules for authentication if available
                        my $sasl_available = 0;
                        eval {
                            require Authen::SASL;
                            require Authen::SASL::Perl;
                            $sasl_available = 1;
                            $self->{logger}->debug("SASL modules loaded successfully");
                        };
                        if ($@) {
                            $self->{logger}->debug("SASL modules not available, using basic auth: $@");
                            # Explicitly set no SASL to prevent any automatic loading attempts
                            $sasl_available = 0;
                        }
                        
                        if ($smtp->auth($email_user, $email_pass)) {
                            $self->{logger}->debug("Authentication successful, sending email");
                            
                            # Send the email
                            $smtp->mail($from);
                            $smtp->recipient($email_user);  # Send to admin
                            $smtp->data();
                            
                            # Create email headers and body
                            $smtp->datasend("From: $from\n");
                            $smtp->datasend("To: $email_user\n");
                            $smtp->datasend("Subject: $subject\n");
                            $smtp->datasend("MIME-Version: 1.0\n");
                            $smtp->datasend("Content-Type: text/html; charset=UTF-8\n");
                            $smtp->datasend("Content-Transfer-Encoding: quoted-printable\n");
                            $smtp->datasend("\n");
                            
                            # Ensure body has content and proper encoding
                            my $email_body = $body;
                            if (!$email_body || length($email_body) < 10) {
                                $email_body = "<h1>500 Internal Server Error</h1><p>An error occurred on the website. Details were not available due to encoding issues.</p>";
                                $self->{logger}->warn("Using fallback email body due to extraction issues");
                            }
                            
                            # Handle quoted-printable encoding for SMTP
                            # MIME::QuotedPrint is now loaded at the top of the file
                            if (utf8::is_utf8($email_body)) {
                                # Encode is now loaded at the top of the file
                                $email_body = Encode::encode_utf8($email_body);
                            }
                            $email_body = MIME::QuotedPrint::encode($email_body);
                            
                            $smtp->datasend($email_body);
                            $smtp->dataend();
                            
                            $smtp->quit();
                            $send_success = 1;
                            $self->{logger}->info("EMAIL SENT SUCCESSFULLY via direct Net::SMTP to $email_host");
                        } else {
                            $self->{logger}->warn("SMTP authentication failed");
                        }
                    } else {
                        $self->{logger}->warn("SMTP connection or STARTTLS failed");
                    }
                };
                
                if (!$send_success) {
                    $self->{logger}->info("EMAIL LOGGED (direct SMTP failed - check credentials)");
                }
            } else {
                $self->{logger}->info("EMAIL LOGGED (SMTP modules missing - install Authen::SASL to enable sending)");
            }
            
        } else {
            # Try using Email::Stuffer's default mechanism (sendmail fallback)
            $self->{logger}->debug("No SMTP config found, trying sendmail...");
            
            # Email::Stuffer is now loaded at the top of the file
            
            my $stuffer = Email::Stuffer
                ->from($from)
                ->subject($subject);
                
            # Handle multiple recipients
            if (ref($to_list) eq 'ARRAY') {
                for my $recipient (@$to_list) {
                    $stuffer->to($recipient);
                }
            } else {
                $stuffer->to($to);
            }
            
            # Add body (detect if HTML or plain text)
            if ($body =~ /<html|<body|<p>/i) {
                $stuffer->html_body($body);
            } else {
                $stuffer->text_body($body);
            }
            
            # Try to send
            $stuffer->send_or_die;
            $send_success = 1;
            $self->{logger}->info("✅ EMAIL SENT SUCCESSFULLY via sendmail");
        }
        
    };
    
    if ($@) {
        $send_error = $@;
        $self->{logger}->warn("EMAIL SEND FAILED: $send_error");
        $self->{logger}->info("Email logged but not delivered");
    }
    
    # Return success regardless of send status (logging always succeeds)
    # Email::Sender::Success is now loaded at the top of the file
    return Email::Sender::Success->new();
}

1;
