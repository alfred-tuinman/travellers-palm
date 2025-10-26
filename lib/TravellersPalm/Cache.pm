package TravellersPalm::Cache;

use strict;
use warnings;

use CHI;

sub setup {
    my ($self) = @_;

    my $cache = CHI->new(
        driver    => 'Memcached',
        servers   => ['127.0.0.1:11211'],
        global    => 1,
        namespace => 'TravellersPalm',
    );

    # Register cache helper
    $self->helper(cache => sub {
        my ($c) = @_;
        return $cache;
    });

    # Optional: test route
    $self->helper(cache_test_data => sub {
        my ($c) = @_;
        my $now = localtime;
        $c->cache->set('last_test_time', $now, '10 min');
        return $c->cache->get('last_test_time');
    });

    $self->log->debug('Cache system initialized');
}

1;
