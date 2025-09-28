package TravellersPalm::Router;
use strict;
use warnings;

use Router::Simple;
use Plack::Builder;

sub to_app {
    my $router = Router::Simple->new;

    # Define routes
    $router->connect('/',                 { controller => 'Home',     action => 'index' });
    $router->connect('/about',            { controller => 'About',    action => 'show' });
    $router->connect('/users/{id}',       { controller => 'Users',    action => 'profile' });
    $router->connect('/products',         { controller => 'Products', action => 'list' });
    $router->connect('/api/ping',         { controller => 'Api',      action => 'ping' });
    $router->connect('/api/user/{id}',    { controller => 'Api',      action => 'user_info' });

    my $app = sub {
        my $env = shift;
        my $match = $router->match($env);

        if ($match) {
            my $controller = $match->{controller};
            my $action     = $match->{action};
            my $class      = "TravellersPalm::Controller::$controller";

            eval "require $class" or return [500, ['Content-Type'=>'text/plain'], ["Failed to load $class: $@"]];

            return $class->$action($env, $match);
        } else {
            return [404, ['Content-Type'=>'text/plain'], ['Not Found']];
        }
    };

    return builder {
        enable "Plack::Middleware::ContentLength";
        $app;
    };
}

1;
