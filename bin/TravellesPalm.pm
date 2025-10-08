#!/usr/bin/env perl

# Use morbo bin/travellerspalm for development
# Use hypnotoad bin/travellerspalm for production

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use TravellersPalm;
use Mojolicious::Commands;

Mojolicious::Commands->start_app('TravellersPalm');
