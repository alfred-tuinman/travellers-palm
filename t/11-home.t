use strict;
use warnings;
use Plack::Test;
use HTTP::Request::Common;
use Test::More;

my $app = Plack::Util::load_psgi('app.psgi');

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET '/');
    is($res->code, 200, 'GET / returns 200');
    like($res->content, qr/Welcome/, 'Home page has welcome text');

    $res = $cb->(GET '/about');
    is($res->code, 200, 'GET /about returns 200');
    like($res->content, qr/About/, 'About page contains About');
};

done_testing();