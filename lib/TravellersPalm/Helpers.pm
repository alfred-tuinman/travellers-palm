package TravellersPalm::Helpers;

use strict;
use warnings;
use Data::Dumper;

sub register {
    my ($self) = @_;

    # Session-based currency helper
    $self->helper(session_currency => sub {
        my ($c) = @_;
        my $cur = $c->session('currency') // 'USD';
        $c->stash(session_currency => $cur);
        return $cur;
    });

    # Debug footer helper
    $self->helper(debug_footer => sub {
        my ($c, $msg) = @_;
        push @{$c->stash->{debug_footer} ||= []}, $msg;
        $c->app->log->debug($msg);
    });

    # Simplified general debug logger
    $self->helper(dump_log => sub {
        my ($c, $msg, $var) = @_;
        my $full = $msg;
        $full .= "\n" . Dumper($var) if defined $var;

        # Log to console
        $c->app->log->debug($full);

        # Store for debug footer in development mode
        if ($c->app->mode eq 'development') {
            push @{$c->stash->{debug_footer} ||= []}, $full;
        }
    });

    $self->log->debug('Helpers registered');
}

1;
