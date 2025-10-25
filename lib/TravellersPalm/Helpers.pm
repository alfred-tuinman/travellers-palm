package TravellersPalm::Helpers;

use strict;
use warnings;
use Data::Dumper;

sub register {
    my ($self) = @_;

    # Simple data dumper (for development)
    $self->helper(dd => sub ($c, $var) {
        local $Data::Dumper::Terse  = 1;
        local $Data::Dumper::Indent = 1;
        my $dump = Dumper($var);
        $c->app->log->debug($dump);
        $c->render(text => "<pre>$dump</pre>");
        $c->finish;
    });

    # Debug footer helper
    $self->helper(debug_footer => sub ($c, $msg) {
        push @{$c->stash->{debug_footer} ||= []}, $msg;
        $c->app->log->debug($msg);
    });

    # Session-based currency helper
    $self->helper(session_currency => sub ($c) {
        my $cur = $c->session('currency') // 'USD';
        $c->stash(session_currency => $cur);
        return $cur;
    });

    # General debug logger
    $self->helper(dump_log => sub ($c, $msg, $var = undef) {
        my $full = $msg;
        $full .= "\n" . Dumper($var) if $var;
        $c->app->log->debug($full);

        if ($c->app->mode eq 'development') {
            $c->stash->{_debug_dumps} //= [];
            push @{$c->stash->{_debug_dumps}}, $full;
        }
    });

    $self->log->debug('Helpers registered');
}

1;
