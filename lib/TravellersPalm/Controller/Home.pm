package TravellersPalm::Controller::Home;
use strict;
use warnings;
use Template;

use Dancer2;

use Data::FormValidator;
use Date::Manip::Date;
use Data::Dumper;

use TravellersPalm::Functions;
use TravellersPalm::Database;

# use TravellersPalm::Model::Web;       # if you have such a module
# use TravellersPalm::Model::Themes;    # as appropriate

use DateTime::Format::Strptime;
use Digest::MD5 qw{md5_hex};
use MIME::Lite;
use URI::http;
use JSON qw//;

our $VERSION 	  = '2.0';
our $TAILOR   	= 'ready-tours', 
our $THEMES   	= 'explore-by-interest';
our $STATES   	= 'explore-by-state';
our $REGIONS  	= 'explore-by-region';
our $IDEAS    	= 'trip-ideas';
our $tokens;
our $session_currency ;
our $session_country  ;

prefix undef;

sub index {
    my ($class, $env, $match) = @_;

    my $tt = Template->new({ INCLUDE_PATH => 'views' });
    my $output = '';
    $tt->process('home.tt', { title => 'Home Page' }, \$output)
        or return [500, ['Content-Type'=>'text/plain'], ["Template error: " . $tt->error]];

    return [200, ['Content-Type'=>'text/html'], [$output]];
}


sub show {
    my $c = shift;   # in Dancer2::Plugin::RouterSimple this may be $c

    my $slidetext = web(163);
    my @slides    = $slidetext->{data}->{writeup} =~ /\G(?=.)([^\n]*)\n?/sg;
    unshift @slides, 'dummy item';

    return $c->render( template => 'home', vars => {
        metatags             => webpages(6),
        themes               => themes('LIMIT'),
        tripideas            => themes('TRIPIDEAS'),
        country              => 'india',
        slides               => \@slides,
        the_travel_experts1  => webtext(119),
        the_travel_experts2  => webtext(120),
        the_travel_experts3  => webtext(121),
        tailor_made_tours    => webtext(187),
        mini_itineraries     => webtext(188),
        best_places_to_visit => webtext(189),
        about                => webtext(60),
        home                 => 1
    });
}

1;
