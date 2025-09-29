package TravellersPalm::Web;

use Dancer2;

our $VERSION 	= '2.0';
our $TAILOR   	= 'ready-tours', 
our $THEMES   	= 'explore-by-interest';
our $STATES   	= 'explore-by-state';
our $REGIONS  	= 'explore-by-region';
our $IDEAS    	= 'trip-ideas';
our $tokens;
our $session_currency ;
our $session_country  ;

prefix undef;

# ----- hooks -----
hook before => sub {
    var session_currency => session('currency') || 'EUR';
};

hook before_template_render => sub {
    my $tokens = shift;
    my ($sec,$min,$hour,$mday,$mon,$year) = localtime();
    $year += 1900;

    $tokens->{PHONE1}     = '+91 88051 22221';
    $tokens->{PHONE2}     = '+91 90111 55551';
    $tokens->{currencies} = currencies();
    $tokens->{COUNTRY}    = session('country');
    $tokens->{currency}   = var('session_currency');
    $tokens->{year}       = $year;
    $tokens->{domain}     = 'www.travellers-palm.com';
};

hook after_template_render => sub {
    # optional logging or headers
};

true;