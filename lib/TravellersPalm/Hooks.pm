package TravellersPalm::Hooks;

use strict;
use warnings;
use POSIX qw(strftime);
use Sys::Hostname 'hostname';
use Email::Stuffer;

sub register {
    my ($self) = @_;

    # --- Session defaults ---
    $self->hook(before => sub ($c) {
        $c->session(currency => $c->session('currency') // 'EUR');
        $c->session(country  => $c->session('country')  // 'IN');
        $c->stash(session_currency => $c->session('currency'));
    });

    # --- Before dispatch ---
    $self->hook(before_dispatch => sub ($c) {
        my $date = strftime('%Y-%m-%d', localtime);

        # Rotate daily log
        my $log_path = $self->config->{log}{path};
        my $log_dir  = Mojo::File->new($log_path)->dirname;
        my $current_log = $log_dir->child("travellers_palm.log.$date");
        rename $log_path, $current_log if -f $log_path && !-f $current_log;

        my $country = lc($c->stash('country') || $c->session('country') || 'india');
        $c->session(country => $country);
        $c->stash(country => $country);
    });

    # --- After dispatch (errors + notifications) ---
    $self->hook(after_dispatch => sub ($c) {
        my $status = $c->res->code // 200;
        return unless $status == 500;

        my $exception  = $c->stash('exception') || '(unknown error)';
        my $req        = $c->req;
        my $url        = $req->url->to_abs;
        my $method     = $req->method;
        my $ip         = $c->tx->remote_address;
        my $agent      = $req->headers->user_agent // '(no UA)';
        my $time       = scalar localtime;
        my $hostname   = hostname();

        my $body = $c->render_to_string(
            template => 'mail/error_email',
            format   => 'html',
            handler  => 'tt',
            vars     => {
                url       => $url,
                method    => $method,
                ip        => $ip,
                agent     => $agent,
                time      => $time,
                host      => $hostname,
                exception => $exception,
                body      => $c->res->body,
            },
        );

        my $from    = $self->config->{email}{error}{from}    // 'noreply@travellerspalm.com';
        my $subject = $self->config->{email}{error}{subject} // "[" . ($self->config->{appname} // 'TravellersPalm') . "] Error at $url";

        Email::Stuffer
            ->from($from)
            ->to($ENV{EMAIL_USER})
            ->subject($subject)
            ->html_body($body)
            ->transport($self->app->email_transport)
            ->send;

        $self->log->error("500 error email sent for $url");
    });

    # --- Around dispatch for 404/500 handling ---
    $self->hook(around_dispatch => sub ($next, $c) {
        eval { $next->(); 1 } or do {
            my $error = $@ || 'Unknown error';
            $c->app->log->error("Dispatch error: $error");

            if ($error =~ /Route without action/) {
                return $c->render(template => '4042', status => 404, message => 'Page not found');
            }
            return $c->render(template => '500', status => 500, message => 'Internal server error');
        };
    });

    # --- Before render ---
    $self->hook(before_render => sub ($c, $args) {
        my ($sec,$min,$hour,$mday,$mon,$year) = localtime();
        $year += 1900;
        my $tokens = $c->app->config->{template_tokens} // {};
        my %stash_tokens = map { uc($_) => $tokens->{$_} } keys %$tokens;
        $stash_tokens{COUNTRY}  = $c->session('country');
        $stash_tokens{CURRENCY} = $c->session('currency');
        $stash_tokens{YEAR}     = $year;
        $c->stash(%stash_tokens);
    });

    $self->log->debug('Hooks registered');
}

1;
