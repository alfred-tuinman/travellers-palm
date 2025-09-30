package TravellersPalm;

use strict;
use warnings;

use Dancer2;

# --- Load all controllers so they register their routes ---
use TravellersPalm::Controller::Destinations;
use TravellersPalm::Controller::Home;
use TravellersPalm::Controller::Hotels;
use TravellersPalm::Controller::MyAccount;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
$year = $year+1900;

use constant VERSION => '2.5';

our $tokens;
our $session_currency ;
our $session_country  ;

prefix undef;

# --- You can put general hooks, plugins, or configuration here ---

# code that runs before each request
hook before => sub {
    # sessions need to be set to YAML in config for it to work
    $session_currency = session('currency') ? session('currency') : 'EUR';
};
 
hook after_template_render => sub {

};

hook before_template_render => sub {
    $tokens = shift;   
    $tokens->{PHONE1}     	= '+91 88051 22221';
    $tokens->{PHONE2}     	= '+91 90111 55551';
    $tokens->{currencies} 	= currencies();
    $tokens->{TAILOR}     	= $TAILOR,
    $tokens->{THEMES}     	= $THEMES,
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

true;   
