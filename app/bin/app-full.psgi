#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Plack::Builder;
use Dancer2;

use TravellersPalm::Database::Connector;

# Home page
get '/' => sub {
    template 'index', {
        title   => 'Welcome to Travelo',
        message => 'Hello from Dancer2 with layouts!',
    };
};

# Users page
get '/users' => sub {
    my $qry = "SELECT * FROM users LIMIT 10";
    my $rows = TravellersPalm::Database::ConnectorUsers::run_query('users',$qry);
    if (!@$rows && config->{environment} eq 'development') {
        # optionally show error page if empty in development
        return send_error("No users found or database query failed", 500);
    }
    template 'users', { users => $rows };
};

# About page
get '/about' => sub {
    template 'about', {
        title   => 'About Travelo',
        message => 'This is the about page, also wrapped in the main layout.',
    };
};

# Contact page
get '/contact' => sub {
    template 'contact', {
        title   => 'Contact Travelo',
        message => 'Get in touch with us at contact@travelo.example',
    };
};

# Return PSGI app
Dancer2->psgi_app;
