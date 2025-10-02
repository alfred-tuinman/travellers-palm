package TravellersPalm::Constants;

use strict;
use warnings;

use Exporter 'import';

# List of symbols to export by default
our @EXPORT_OK = qw(
VERSION 
$TAILOR 
$THEMES 
$STATES 
$REGIONS 
$IDEAS 
$tokens 
$session_currency 
$session_country);

# Define tags (groups)
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,   # now :all means "export everything above"
);

# Define your constants
use constant VERSION => '2.5';

our $TAILOR  = 'ready-tours';
our $THEMES  = 'explore-by-interest';
our $STATES  = 'explore-by-state';
our $REGIONS = 'explore-by-region';
our $IDEAS   = 'trip-ideas';

our $tokens;
our $session_currency ;
our $session_country  ;

1;  
