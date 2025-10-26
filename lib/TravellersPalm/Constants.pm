package TravellersPalm::Constants;

use strict;
use warnings;

use constant {
    TAILOR  => 'ready-tours',
    THEMES  => 'explore-by-interest',
    STATES  => 'explore-by-state',
    REGIONS => 'explore-by-region',
    IDEAS   => 'trip-ideas',
};

use Exporter 'import';

our @EXPORT_OK = qw(TAILOR THEMES STATES REGIONS IDEAS);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

1;
