package TravellersPalm;

use strict;
use warnings;

use Dancer2;

# --- Load all controllers ---
use TravellersPalm::Controller::Destinations;
use TravellersPalm::Controller::Home;
use TravellersPalm::Controller::Hotels;
use TravellersPalm::Controller::Images;
use TravellersPalm::Controller::MyAccount;

use TravellersPalm::Constants;

our $VERSION 	= '2.0';
our $TAILOR   	= 'ready-tours', 
our $THEMES   	= 'explore-by-interest';
our $STATES   	= 'explore-by-state';
our $REGIONS  	= 'explore-by-region';
our $IDEAS    	= 'trip-ideas';
our $tokens;
our $session_currency ;
our $session_country  ;

# Set the time
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
$year = $year+1900;

# --- You can put general hooks, plugins, or configuration here ---
# code that runs before each request
# sessions need to be set to YAML in config for it to work
hook before => sub {
    $session_currency = session('currency') // 'EUR';
    session currency => $session_currency; # ensure it's saved in the session
};

# hook after_template_render => sub { };

hook before_template_render => sub {
    $tokens = shift;   
    $tokens->{PHONE1}     	= '+91 88051 22221';
    $tokens->{PHONE2}     	= '+91 90111 55551';
    # $tokens->{currencies} 	= TravellersPalm::Database::Currencies::currencies();
    $tokens->{TAILOR}     	= $TAILOR;
    $tokens->{THEMES}     	= $THEMES;
    $tokens->{STATES}     	= $STATES;
    $tokens->{REGIONS}    	= $REGIONS;
    $tokens->{IDEAS}      	= 'trip-ideas';
    $tokens->{LEARNMORE}  	= 'Learn More';
    $tokens->{COUNTRY}    	= $session_country;
    $tokens->{currency}    	= $session_currency;
    $tokens->{IMAGE}      	= 'http://images.travellers-palm.com';
    $tokens->{year}         = $year;
    $tokens->{domain}       = "www.travellers-palm.com";
};

# destinations
get '/destinations/:destination' => \&TravellersPalm::Controller::Destinations::show_destination;

any [ 'get', 'post' ] => "/destinations/*/$TAILOR/**" => \&TravellersPalm::Controller::Destinations::show_tailor;

get "/destinations/*/$REGIONS" => \&TravellersPalm::Controller::Destinations::show_region_list;
get "/destinations/*/$REGIONS/**" => \&TravellersPalm::Controller::Destinations::show_region_detail;

get "/destinations/*/$STATES" => \&TravellersPalm::Controller::Destinations::show_state_list;
get "/destinations/*/$STATES/**" => \&TravellersPalm::Controller::Destinations::show_state_detail;

get "/destinations/*/$THEMES" => \&TravellersPalm::Controller::Destinations::show_theme_list;
get "/destinations/*/$THEMES/**" => \&TravellersPalm::Controller::Destinations::show_theme_detail;

any [ 'get', 'post' ] => '/plan-your-trip' => \&plan_your_trip;

# Home
get '/'                     => \&TravellersPalm::Controller::Home::index;
get '/before-you-go'        => \&TravellersPalm::Controller::Home::before_you_go;
any '/contact-us'           => \&TravellersPalm::Controller::Home::contact_us;
get '/enquiry'              => \&TravellersPalm::Controller::Home::get_enquiry;
post '/enquiry'             => \&TravellersPalm::Controller::Home::post_enquiry;
get '/faq'                  => \&TravellersPalm::Controller::Home::faq;
get '/policies'             => \&TravellersPalm::Controller::Home::policies;
get '/search-results'       => \&TravellersPalm::Controller::Home::search_results;
get '/site-map'             => \&TravellersPalm::Controller::Home::site_map;
get '/state/:state'         => \&TravellersPalm::Controller::Home::state;
get '/sustainable-tourism'  => \&TravellersPalm::Controller::Home::sustainable_tourism;
get '/testimonials'         => \&TravellersPalm::Controller::Home::testimonials;
get '/travel-ideas'         => \&TravellersPalm::Controller::Home::travel_ideas;
get '/what-to-expect'       => \&TravellersPalm::Controller::Home::what_to_expect;
get '/why-travel_with_us'   => \&TravellersPalm::Controller::Home::why_travel_with_us;

get '/currency/:currency' => sub {
    session currency => currency( params->{currency} );
    redirect request->referer;
};

# Hotels
get '/hotel-categories'    => \&TravellersPalm::Controller::Hotels::show_hotel_categories;
get '/hand-picked-hotels'  => \&TravellersPalm::Controller::Hotels::show_hand_picked_hotels;

# Images - Catch all image requests under / (like /home/sucheta.jpg)
get qr{^/([^/]+/.+)} => sub {
    my $path = $1;  # e.g., home/sucheta.jpg
    my $file = File::Spec->catfile(config->{public_dir}, 'images', $path);

    if (-f $file) {
        return send_file $file;
    }
    status 'not_found';
    return "File not found";
};

# MyAccount
get  '/my-account'               => \&TravellersPalm::Controller::MyAccount::login;
post '/my-account/register'      => \&TravellersPalm::Controller::MyAccount::register;
post '/my-account/mail-password' => \&TravellersPalm::Controller::MyAccount::mail_password;

# Catch-all 404
any qr{.*} => sub {
    template('404') => { page => request->path };
};

true;   
