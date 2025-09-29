package TravellersPalm::Router;
use strict;
use warnings;

use Router::Simple;
use Plack::Builder;

sub to_app {
    my $router = Router::Simple->new;

    # Define routes
    $router->connect('/', 
      { controller => 'Home', action => 'show' },
      { method => 'GET' }
    );
  
    $router->connect('/before-you-go', 
      { controller => 'Home', action => 'before_you_go' },
      { method => 'GET' }
    );
    
    $router->connect('/contact-us', 
      { controller => 'Home', action => 'contact_us'},
      { method => [ 'get', 'post'] }
    );

    $router->connect('/enquiry', 
      { controller => 'Home', action => 'get_enquiry' },
      { method => 'GET' }
    );
    
    $router->connect('/enquiry', 
      { controller => 'Home', action => 'post_enquiry' },
      { method => 'POST' }
    );
    
    $router->connect('/faq', 
      { controller => 'Home', action => 'faq' },
      { method => 'GET' }
    );

    $router->connect('/policies', 
      { controller => 'Home', action => 'policies' },
      { method => 'GET' }
    );

    $router->connect('/search-results', 
      { controller => 'Home', action => 'search_results' },
    );

    $router->connect('/site-map', 
      { controller => 'Home', action => 'site_map' },
      { method => 'GET' }
    );

    $router->connect('/state/:state', 
      { controller => 'Home', action => 'state' },
      { method => 'GET' }
    );

    $router->connect('/site-map', 
      { controller => 'Home', action => 'site_map' },
      { method => 'GET' }
    );

    $router->connect('/sustainable-tourism', 
      { controller => 'Home', action => 'sustainable_tourism' },
      { method => 'GET' }
    );

    $router->connect('/testimonials', 
      { controller => 'Home', action => 'testimonials' },
      { method => 'GET' }
    );

    $router->connect('/travel-ideas', 
      { controller => 'Home', action => 'travel_ideas' },
      { method => 'GET' }
    );

    $router->connect('/what-to-expect', 
      { controller => 'Home', action => 'what_to_expect' },
      { method => 'GET' }
    );

    $router->connect('/why-travel_with_us', 
      { controller => 'Home', action => 'why-travel_with_us' },
      { method => 'GET' }
    );


    $router->connect('/about',            { controller => 'About',    action => 'show' });
    $router->connect('/users/{id}',       { controller => 'Users',    action => 'profile' });
    $router->connect('/products',         { controller => 'Products', action => 'list' });
    $router->connect('/api/ping',         { controller => 'Api',      action => 'ping' });
    $router->connect('/api/user/{id}',    { controller => 'Api',      action => 'user_info' });
    $router->connect('/airports/{country}',{ controller => 'Cities',  action => 'airporto' });

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
