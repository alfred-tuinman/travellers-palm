use strict;
use warnings;
use Plack::Test;
use HTTP::Request::Common;
use JSON qw(decode_json);
use Test::More;

my $app = Plack::Util::load_psgi('app.psgi');

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET '/api/ping');
    is($res->code, 200, 'GET /api/ping returns 200');
    my $json = decode_json($res->content);
    is($json->{status}, 'ok', 'API ping response is ok');

    $res = $cb->(GET '/api/user/1');
    is($res->code, 200, 'GET /api/user/1 returns 200');
    my $user_json = decode_json($res->content);
    ok($user_json->{id}, 'User info contains id');
};

done_testing();