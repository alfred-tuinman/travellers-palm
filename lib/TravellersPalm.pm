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
use TravellersPalm::Constants qw(:all);
use TravellersPalm::Database::Currencies;

my $session_currency;  # declare at file scope if needed elsewhere
my $session_country; 
my $tokens;
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
    $tokens->{currencies} 	= TravellersPalm::Database::Currencies::currencies();
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
    get '/destinations/:destination' => \&show_destination;

    any [ 'get', 'post' ] => "/destinations/*/$TAILOR/**" => \&show_tailor;

    get "/destinations/*/$REGIONS" => \&show_region_list;
    get "/destinations/*/$REGIONS/**" => \&show_region_detail;

    get "/destinations/*/$STATES" => \&show_state_list;
    get "/destinations/*/$STATES/**" => \&show_state_detail;

    get "/destinations/*/$THEMES" => \&show_theme_list;
    get "/destinations/*/$THEMES/**" => \&show_theme_detail;

    any [ 'get', 'post' ] => '/plan-your-trip' => \&plan_your_trip;

# Home
    get '/'                     => \&index;
    get '/before-you-go'        => \&before_you_go;
    any '/contact-us'           => \&contact_us;
    get '/enquiry'              => \&get_enquiry;
    post '/enquiry'             => \&post_enquiry;
    get '/faq'                  => \&faq;
    get '/policies'             => \&policies;
    get '/search-results'       => \&search_results;
    get '/site-map'             => \&site_map;
    get '/state/:state'         => \&state;
    get '/sustainable-tourism'  => \&sustainable_tourism;
    get '/testimonials'         => \&testimonials;
    get '/travel-ideas'         => \&travel_ideas;
    get '/what-to-expect'       => \&what_to_expect;
    get '/why-travel_with_us'   => \&why_travel_with_us;

    get '/currency/:currency' => sub {
        session currency => currency( params->{currency} );
        redirect request->referer;
    };

    # Catch-all 404
    any qr{.*} => sub {
        template '404' => { page => request->path };
    };

# Hotels
    get '/hotel-categories'    => \&show_hotel_categories;
    get '/hand-picked-hotels'  => \&show_hand_picked_hotels;


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
    get  '/my-account'               => \&login;
    post '/my-account/register'      => \&register;
    post '/my-account/mail-password' => \&mail_password;

true;   
