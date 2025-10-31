package TravellersPalm::Hooks;

use strict;
use warnings;

use Email::Stuffer;
use Mojo::File;
use POSIX qw(strftime);
use Sys::Hostname 'hostname';

sub register {
    my ($self) = @_;

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

        my $date = strftime('%Y-%m-%d', localtime);

        # Rotate daily log
        eval {
            my $log_path = $self->config->{log}{path};
            my $log_dir  = Mojo::File->new($log_path)->dirname;
            my $current_log = $log_dir->child("travellers_palm.log.$date");
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

        my $exception = $c->stash('exception') // '(unknown error)';
        my $req       = $c->req;
        my $url       = $req->url->to_abs;
        my $method    = $req->method;
        my $ip        = eval { $c->tx->remote_address } // '(unknown)';
        my $agent     = $req->headers->user_agent // '(no UA)';
        my $time      = scalar localtime;
        my $hostname  = hostname();

        my $body;
        eval {
            $body = $c->render_to_string(
                template => 'mail/error_email',
                format   => 'html',
                handler  => 'tt',
                vars => {
                    url       => $url,
                    method    => $method,
                    ip        => $ip,
                    agent     => $agent,
                    time      => $time,
                    host      => $hostname,
                    exception => $exception,
                    body      => $c->res->body // '',
                },
            );
            1;
        } or do {
            $body = "<p>Could not render error_email template: $@</p>";
            $self->log->error("Failed to render error_email template: $@");
        };

        my $from    = $self->config->{email}{error}{from}    // 'noreply@travellerspalm.com';
        my $subject = $self->config->{email}{error}{subject} // "[TravellersPalm] Error at $url";

        eval {
            $self->log->info("Attempting to send error email:");
            $self->log->info("From: $from");
            $self->log->info("To: $ENV{EMAIL_USER}");
            $self->log->info("Subject: $subject");
            
            Email::Stuffer
                ->from($from)
                ->to($ENV{EMAIL_USER})
                ->subject($subject)
                ->html_body($body)
                ->transport($self->app->email_transport)
                ->send;
                
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
            $self->log->error("  Email user: " . ($ENV{EMAIL_USER} || "NOT SET"));
        };

        $self->log->error("500 error email processed for $url");
    });

    # --- Around dispatch for 404/500 handling ---
    $self->hook(around_dispatch => sub {
        my ($next, $c) = @_;
        eval { $next->(); 1 } or do {
            my $error = $@ || 'Unknown error';
            $c->app->log->error("Dispatch error: $error");

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
