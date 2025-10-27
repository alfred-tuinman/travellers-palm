package TravellersPalm::Routes;

use Mojo::Base -strict;
use TravellersPalm::Database::Core::Connector;
use TravellersPalm::Constants qw(:all);

sub register {
    my ($app) = @_;

    my $r = $app->routes;

    # Home
    $r->get('/')->to('home#index');
        $r->get('/about-us')->to('staticpages#about');
        $r->get('/before-you-go')->to('staticpages#before_you_go');
        $r->get('/contact-us')->to('staticpages#contact_us');
        $r->get('/faq')->to('staticpages#faq');
        $r->get('/policies')->to('staticpages#policies');
        $r->get('/search-results')->to('staticpages#search_results');
        $r->get('/sitemap')->to('staticpages#site_map');
        $r->get('/state/:state')->to('staticpages#state');
        $r->get('/sustainable-tourism')->to('staticpages#sustainable_tourism');
        $r->get('/testimonials')->to('staticpages#testimonials');
        $r->get('/travel-ideas')->to('staticpages#travel_ideas');
        $r->get('/what-to-expect')->to('staticpages#what_to_expect');
        $r->get('/why-travel-with-us')->to('staticpages#why_travel_with_us');

    # Enquiry (GET + POST)
    $r->get('/enquiry')->to('home#get_enquiry');
    $r->post('/enquiry')->to('home#post_enquiry');

    # Hotels routes
    $r->get('/hotel-categories')->to('hotels#show_hotel_categories');
    $r->get('/hand-picked-hotels')->to('hotels#show_hand_picked_hotels');

    # Itineraries routes
    $r->get('/itineraries/tailor')->to('itineraries#itineraries_tailor');
    $r->get('/itineraries/:option/:tour')->to('itineraries#route_itinerary');

    # Destinations routes
    $r->get('/destinations/:country/'.IDEAS.'/:destination/list')
        ->to('destinations#show_idea_list');
    $r->get('/destinations/:country/'.IDEAS.'/:destination/:idea/:view')
        ->to('destinations#show_idea_detail');  

    $r->get('/destinations/:country/regions/:region/list')
        ->to('itineraries#itineraries_regions');
    $r->get('/destinations/india/states/:state/list')
        ->to('itineraries#itineraries_states');
    $r->get('/destinations/:country/'.TAILOR.'/:destination/:view')
        ->to('itineraries#route_itinerary');

    $r->get('/destinations/:country/regions')
        ->to('destinations#regions');
    $r->get('/destinations/:country/'.REGIONS.'/:destination/:list')
        ->to('destinations#show_region_list');
    $r->get('/destinations/:country/'.REGIONS.'/:destination/:region/:view')
        ->to('destinations#show_region_detail');

    $r->get('/destinations/india/states')
        ->to('destinations#states');
    $r->get('/destinations/india/'.STATES.'/:destination/:list')
        ->to('destinations#show_state_list');
    $r->get('/destinations/india/'.STATES.'/:destination/:state/:view')
        ->to('destinations#show_state_detail');

    $r->get('/destinations/:country/themes')
        ->to('destinations#themes');
    $r->get('/destinations/:country/'.THEMES.'/:destination/:list')
        ->to('destinations#show_theme_list');
    $r->get('/destinations/:country/'.THEMES.'/:destination/:theme/:view')
        ->to('destinations#show_theme_detail');

    $r->get('/destinations/:country/:option/:view/:order/:region')
        ->to('itineraries#itineraries_option_view_order_region');

    # Redirect
    $r->get('/destinations/:destination')->to(cb => sub {
        my $c = shift;
        my $country = $c->session('country') || 'india';
        my $dest    = $c->stash('destination');
        return $c->redirect_to("/destinations/$country/$dest");
    });

    $r->any('/plan-your-trip')->to('destinations#plan_your_trip');

    # My Account routes
    $r->get('/login')->to('my_account#login');
    $r->post('/register')->to('my_account#register');
    $r->post('/mail-password')->to('my_account#mail_password');

    # Currency switcher
    $r->get('/currency/:currency' => sub {
        my $c = shift;
        $c->session(currency => $c->param('currency'));
        $c->redirect_to($c->req->headers->referrer // '/');
    });

    # Images
    $r->get('/images/*filepath')->to('images#serve_image');

    # API
    $r->get('/api/ping')->to('api#ping');
    $r->get('/api/user/:id')->to('api#user_info');

    # Catch-all fallback (404)
    $r->any('*')->to(cb => sub {
        my $c = shift;
        $c->render(
            template => '404',
            message  => 'The page you are looking for does not exist.',
            url      => $c->req->url->to_string,
            status   => 404,
        );
    });

    $app->log->debug('All routes registered successfully');
}

1;
