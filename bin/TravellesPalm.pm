#!/usr/bin/env perl

# Use morbo bin/travellerspalm for development
# Use hypnotoad bin/travellerspalm for production

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Mojolicious::Commands;
use TravellersPalm;

Mojolicious::Commands->start_app('TravellersPalm');
