package TravellersPalm::Hooks;

use strict;
use warnings;

use Email::MIME;
use Mojo::File;
use POSIX qw(strftime);
use Sys::Hostname 'hostname';
use DateTime;
use DateTime::TimeZone;
use Encode qw(encode decode);

# Function to sanitize sensitive information from error messages
sub sanitize_sensitive_data {
    my ($text) = @_;
    return '' unless defined $text;
    
    # Remove OAuth2 client secrets, tokens, and IDs
    $text =~ s/client_secret[=:]\s*[^\s&\n]+/client_secret=[REDACTED]/gi;
    $text =~ s/client_id[=:]\s*[^\s&\n]+/client_id=[REDACTED]/gi;
    $text =~ s/refresh_token[=:]\s*[^\s&\n]+/refresh_token=[REDACTED]/gi;
    $text =~ s/access_token[=:]\s*[^\s&\n]+/access_token=[REDACTED]/gi;
    $text =~ s/bearer\s+[^\s&\n]+/bearer [REDACTED]/gi;
    
    # Remove email passwords and app passwords
    $text =~ s/password[=:]\s*[^\s&\n]+/password=[REDACTED]/gi;
    $text =~ s/pass[=:]\s*[^\s&\n]+/pass=[REDACTED]/gi;
    
    # Remove API keys and secrets
    $text =~ s/api_key[=:]\s*[^\s&\n]+/api_key=[REDACTED]/gi;
    $text =~ s/secret[=:]\s*[^\s&\n]+/secret=[REDACTED]/gi;
    
    # Remove long encoded strings that might be tokens (base64-like)
    # More specific pattern: must have at least one + or / and be long enough to be a token
    $text =~ s/[A-Za-z0-9]*[+\/][A-Za-z0-9+\/]{30,}={0,2}/[ENCODED_TOKEN_REDACTED]/g;
    
    # Remove GOCSPX- Google OAuth2 client secrets
    $text =~ s/GOCSPX-[A-Za-z0-9_-]+/GOCSPX-[REDACTED]/g;
    
    # Remove Google OAuth2 client IDs (format: numbers-string.apps.googleusercontent.com)
    $text =~ s/\d{10,}-[a-z0-9]+\.apps\.googleusercontent\.com/[GOOGLE_CLIENT_ID_REDACTED]/g;
    
    # Remove environment variable values that might contain secrets
    $text =~ s/EMAIL_[A-Z_]*[=:]\s*[^\s&\n]+/EMAIL_[REDACTED]=[REDACTED]/gi;
    
    # Remove app-specific patterns that might be leaked
    $text =~ s/tirp\s+ansy\s+vkxl\s+ackl/[EMAIL_APP_PASSWORD_REDACTED]/gi;
    $text =~ s/admin\@odyssey\.co\.in/admin\@[REDACTED]/gi;
    
    # Remove Gmail SMTP testing messages that might contain passwords
    $text =~ s/Testing\s+Gmail\s+SMTP\s+with\s+App\s+Password:\s*[^\n\r]+/Testing Gmail SMTP with App Password: [REDACTED]/gi;
    $text =~ s/Gmail\s+SMTP\s+.*?Password:\s*[^\n\r]+/Gmail SMTP Password: [REDACTED]/gi;
    $text =~ s/SMTP\s+.*?password:\s*[^\n\r]+/SMTP password: [REDACTED]/gi;
    
    # Remove any instance of the specific app password in different contexts
    $text =~ s/\btirp\b[^\n\r]*\backl\b/[EMAIL_APP_PASSWORD_REDACTED]/gi;
    
    # Remove any remaining suspicious token-like patterns
    $text =~ s/1\/\/[A-Za-z0-9_-]{20,}/1\/\/[OAUTH_REFRESH_TOKEN_REDACTED]/g;
    $text =~ s/4\/[A-Za-z0-9_-]{20,}/4\/[OAUTH_AUTH_CODE_REDACTED]/g;
    
    return $text;
}

sub register {
    my ($self) = @_;

    # Sanitization method for this package
    $self->{sanitize} = \&sanitize_sensitive_data;

    # --- Session defaults ---
    $self->hook(before => sub {
        my ($c) = @_;
        $c->session(currency => $c->session('currency') // 'EUR');
        $c->session(country  => $c->session('country')  // 'IN');
        $c->stash(session_currency => $c->session('currency'));
    });

    # --- Before dispatch ---
    $self->hook(before_dispatch => sub {
        my ($c) = @_;

        # Get current date in configured timezone for log rotation
        my $timezone = $self->config->{log}{timezone} // 'UTC';
        my $dt = DateTime->now(time_zone => $timezone);
        my $date = $dt->strftime('%Y-%m-%d');

        # Rotate daily log
        eval {
            my $log_path = $self->config->{log}{path};
            my $log_file = Mojo::File->new($log_path);
            my $log_dir  = $log_file->dirname;
            my $log_basename = $log_file->basename;
            my $current_log = $log_dir->child("$log_basename.$date");
            rename $log_path, $current_log if -f $log_path && !-f $current_log;
            1;
        } or do {
            $self->log->error("Failed to rotate log: $@");
        };

        my $country = lc($c->stash('country') || $c->session('country') || 'india');
        $c->session(country => $country);
        $c->stash(country => $country);
    });

    # --- After dispatch (errors + notifications) ---
    $self->hook(after_dispatch => sub {
        my ($c) = @_;

        my $status = $c->res->code // 200;
        return unless $status == 500;

        # Try multiple ways to get exception information
        my $exception = $c->stash('exception') 
                     || $c->stash('error') 
                     || $c->stash('mojo.exception')
                     || eval { $c->app->log->history->[-1] // '' }
                     || 'No exception details available';
        
        # Get request details for error reporting
        my $url = $c->req->url->to_abs;
        my $method = $c->req->method;
        my $time = localtime();
        my $agent = $c->req->headers->user_agent || 'Unknown';
        my $ip = $c->tx->remote_address || 'Unknown';
        
        # Try to get more error context - for 500 errors, the response body may be compressed/encoded
        # Let's try to decode it and extract meaningful information
        my $raw_body = $c->res->body || '';
        my $error_body = '';
        
        # Always create our own readable error summary
        $error_body = "500 Internal Server Error occurred at $url\n";
        $error_body .= "Method: $method\n";
        my $sanitized_exception = sanitize_sensitive_data($exception);
        $error_body .= "Exception: $sanitized_exception\n";
        $error_body .= "Time: $time\n";
        $error_body .= "User Agent: $agent\n";
        $error_body .= "IP Address: $ip\n";
        
        # Debug log to verify sanitization is working
        $self->log->info("SANITIZATION TEST: Original exception length: " . length($exception) . ", Sanitized length: " . length($sanitized_exception));
        
        if ($raw_body) {
            # Try to extract useful information from the response body
            my $body_info = '';
            
            # Check if it's gzip compressed
            if ($raw_body =~ /^\x1f\x8b/) {
                eval {
                    require IO::Uncompress::Gunzip;
                    my $uncompressed;
                    IO::Uncompress::Gunzip::gunzip(\$raw_body => \$uncompressed);
                    if ($uncompressed) {
                        # Extract useful info from uncompressed HTML
                        if ($uncompressed =~ /<title[^>]*>([^<]+)<\/title>/i) {
                            $body_info .= "Page Title: $1\n";
                        }
                        if ($uncompressed =~ /<h1[^>]*>([^<]+)<\/h1>/i) {
                            $body_info .= "Main Heading: $1\n";
                        }
                        # Look for error messages in the HTML
                        if ($uncompressed =~ /error[^<]*:?\s*([^<>\n]{10,100})/i) {
                            $body_info .= "Error Text: $1\n";
                        }
                        # Get a clean text preview
                        my $text_content = $uncompressed;
                        $text_content =~ s/<script[^>]*>.*?<\/script>//gsi;
                        $text_content =~ s/<style[^>]*>.*?<\/style>//gsi;
                        $text_content =~ s/<[^>]+>//g;
                        $text_content =~ s/\s+/ /g;
                        $text_content = substr($text_content, 0, 300) . "..." if length($text_content) > 300;
                        $body_info .= "Content Preview: $text_content\n" if $text_content =~ /\S/;
                    }
                };
                if ($@) {
                    $body_info = "Gzip compressed content (" . length($raw_body) . " bytes) - decompression failed: $@\n";
                }
            }
            # Check if it looks like HTML even if not compressed
            elsif ($raw_body =~ /<html|<head|<body|<!DOCTYPE/i) {
                # Extract useful info from HTML
                if ($raw_body =~ /<title[^>]*>([^<]+)<\/title>/i) {
                    $body_info .= "Page Title: $1\n";
                }
                if ($raw_body =~ /<h1[^>]*>([^<]+)<\/h1>/i) {
                    $body_info .= "Main Heading: $1\n";
                }
                # Look for error messages
                if ($raw_body =~ /error[^<]*:?\s*([^<>\n]{10,100})/i) {
                    $body_info .= "Error Text: $1\n";
                }
                # Get readable preview
                my $preview = substr($raw_body, 0, 500);
                $preview =~ s/<script[^>]*>.*?<\/script>//gsi;
                $preview =~ s/<[^>]+>//g;
                $preview =~ s/\s+/ /g;
                $body_info .= "Content Preview: $preview...\n" if $preview =~ /\S/;
            }
            # Check for other binary/encoded content
            else {
                my $non_printable_count = () = $raw_body =~ /[^\x20-\x7E\x09\x0A\x0D]/g;
                my $total_length = length($raw_body);
                if ($total_length > 0 && ($non_printable_count / $total_length) > 0.3) {
                    $body_info = "Binary/Encoded content (" . length($raw_body) . " bytes)\n";
                    # Try to identify content type from headers
                    my $content_type = $c->res->headers->content_type || 'unknown';
                    my $content_encoding = $c->res->headers->content_encoding || 'none';
                    $body_info .= "Content-Type: $content_type\n";
                    $body_info .= "Content-Encoding: $content_encoding\n";
                } else {
                    # Treat as text and truncate if needed
                    my $body_preview = length($raw_body) > 1000 ? substr($raw_body, 0, 1000) . "...\n[Content truncated]" : $raw_body;
                    $body_info = "Response Body:\n" . $body_preview . "\n";
                }
            }
            
            # Sanitize sensitive information from response body content
            $body_info = sanitize_sensitive_data($body_info);
            $error_body .= $body_info;
        } else {
            $error_body .= "Response Body: [Empty]\n";
        }
        
        # Add stack trace if available
        if ($exception && $exception =~ /at\s+(.+?)\s+line\s+(\d+)/) {
            $error_body .= "File: $1\n";
            $error_body .= "Line: $2\n";
        }
        
        # Debug: Log what exception data we have (sanitized)
        $self->log->info("DEBUG: after_dispatch triggered with status $status");
        $self->log->info("DEBUG: Exception data: " . sanitize_sensitive_data($exception));
        $self->log->info("DEBUG: Response body: " . sanitize_sensitive_data($error_body || '(empty)'));
        $self->log->info("DEBUG: Response code: " . ($c->res->code // '(none)'));
        $self->log->info("DEBUG: Stash keys available: " . join(', ', keys %{$c->stash}));
        
        # Get timezone from config, default to Asia/Kolkata
        my $timezone = $self->config->{log}{timezone} // 'Asia/Kolkata';
        eval {
            require DateTime;
            my $dt = DateTime->now(time_zone => $timezone);
            $time = $dt->strftime('%Y-%m-%d %H:%M:%S %Z');
        } or do {
            # Fallback to system localtime if DateTime fails
            $time = scalar localtime;
        };
        
        my $hostname  = hostname();

        # Sanitize all data before passing to template
        my $sanitized_exception_template = sanitize_sensitive_data($exception);
        my $sanitized_error_body = sanitize_sensitive_data($error_body);
        my $sanitized_url = sanitize_sensitive_data($url);
        my $sanitized_agent = sanitize_sensitive_data($agent);

        my $body;
        eval {
            $body = $c->render_to_string(
                template => 'mail/error_email',
                format   => 'html',
                handler  => 'tt',
                url       => $sanitized_url,
                method    => $method,
                ip        => $ip,
                agent     => $sanitized_agent,
                time      => $time,
                host      => $hostname,
                exception => $sanitized_exception_template,
                body      => $sanitized_error_body,
            );
            
            # Debug: Check what was rendered
            $self->log->debug("Template rendered successfully, length: " . length($body));
            $self->log->debug("Template preview: " . substr($body, 0, 100));
            1;
        } or do {
            $body = "<p>Could not render error_email template: $@</p>";
            $self->log->error("Failed to render error_email template: $@");
        };

        my $from    = $self->config->{email}{error}{from}    // $self->config->{email}{from} // 'system@travellerspalm.com';
        my $error_to = $self->config->{email}{error}{to} || $self->config->{email}{admin} || $ENV{EMAIL_USER};
        my $subject = $self->config->{email}{error}{subject} // "[TravellersPalm] Error at $url";

        # Debug: Log the email configuration being used
        $self->log->debug("Email From address from config: " . ($self->config->{email}{error}{from} // 'NOT SET'));
        $self->log->debug("Using From address: $from");

        eval {
            $self->log->info("Attempting to send error email:");
            $self->log->info("From: $from");
            $self->log->info("To: $error_to");
            $self->log->info("Subject: $subject");
            
            # Get the transport object
            my $transport = $self->app->email_transport;
            
            # Properly encode the body to avoid wide character issues
            my $encoded_body = encode('UTF-8', $body);
            
            my $email = Email::MIME->create(
                header_str => [
                    From    => $from,
                    To      => $error_to,
                    Subject => $subject,
                ],
                attributes => {
                    content_type => 'text/html',
                    charset      => 'UTF-8',
                    encoding     => 'quoted-printable',  # Changed from '8bit' to avoid garbled text
                },
                body => $encoded_body,
            );
            
            # Use our transport directly
            $transport->send_email($email, {
                from => $from,
                to   => [$error_to]
            });
                
            $self->log->info("=== Error email sent successfully ===");
            1;
        } or do {
            my $error = $@;
            $self->log->error("Failed to send 500 error email: $error");
            
            # Log additional debugging information
            $self->log->error("Email configuration debug:");
            $self->log->error("  OAuth2 configured: " . (($ENV{EMAIL_CLIENT_ID} && $ENV{EMAIL_CLIENT_SECRET} && $ENV{EMAIL_REFRESH_TOKEN}) ? "YES" : "NO"));
            $self->log->error("  Email host: " . ($ENV{EMAIL_HOST} || "NOT SET"));
            $self->log->error("  Email port: " . ($ENV{EMAIL_PORT} || "NOT SET"));
            $self->log->error("  Email user: " . ($error_to || "NOT SET"));
        };

        $self->log->error("500 error email processed for $url");
    });

    # --- Around dispatch for 404/500 handling ---
    $self->hook(around_dispatch => sub {
        my ($next, $c) = @_;
        eval { $next->(); 1 } or do {
            my $error = $@ || 'Unknown error';
            $c->app->log->error("Dispatch error: $error");
            
            # Store the exception in stash for later email processing
            $c->stash(exception => $error);

            if ($error =~ /Route without action/) {
                eval {
                    $c->render(template => '4042', status => 404, message => 'Page not found');
                    1;
                } or do {
                    $c->app->log->error("Failed to render 4042 template: $@");
                    $c->res->code(404);
                    $c->res->body('Page not found');
                };
            }
            else {
                eval {
                    $c->render(template => '500', status => 500, message => 'Internal server error');
                    1;
                } or do {
                    $c->app->log->error("Failed to render 500 template: $@");
                    $c->res->code(500);
                    $c->res->body('Internal server error');
                };
            }
        };
    });

    # --- Before render ---
    $self->hook(before_render => sub {
        my ($c, $args) = @_;
        my ($sec,$min,$hour,$mday,$mon,$year) = localtime();
        $year += 1900;

        my $tokens = $c->app->config->{template_tokens} // {};
        my %stash_tokens = map { uc($_) => $tokens->{$_} } keys %$tokens;

        $stash_tokens{COUNTRY}  = $c->session('country') // 'IN';
        $stash_tokens{CURRENCY} = $c->session('currency') // 'EUR';
        $stash_tokens{YEAR}     = $year;

        $c->stash(%stash_tokens);
    });

    $self->log->debug('Hooks registered safely');
}

1;
