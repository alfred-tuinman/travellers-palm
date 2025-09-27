#!/usr/bin/env perl

use strict;
use warnings;
use Plack::Request;

# PSGI application
my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);

    my $path = $req->path_info;

    my $res;
    if ($path eq "/") {
        $res = [200, ['Content-Type' => 'text/html'], ['<h1>Hello there, PSGI + Starman!</h1> You have reached me in /bin/app.psgi']];
    } elsif ($path eq "/hello") {
        $res = [200, ['Content-Type' => 'text/plain'], ["Hello, world!\n"]];
    } else {
        $res = [404, ['Content-Type' => 'text/plain'], ["Not found\n"]];
    }

    return $res;
};

# Return the PSGI app reference
$app;

