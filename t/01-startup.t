use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

# to test this run prove -lv t/01_startup.t

# 1. Check app.psgi can be loaded
my $app;
eval { $app = Plack::Util::load_psgi('app.psgi') };
ok(!$@, 'app.psgi loads without error');
ok($app,  'Got a PSGI app');

# 2. Optional: check for essential modules
use_ok('Template');
use_ok('DBI');
use_ok('Router::Simple');

# 3. Smoke test: can we hit the home page
test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET '/');
    is($res->code, 200, 'GET / returns 200');
    like($res->content, qr/Welcome|Travellers Palm/, 'Home page contains expected text');
};

done_testing();