#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

# Use your main app package
use TravellersPalm::App;

# -----------------------------
# Dancer2 Configuration
# -----------------------------
use Dancer2 appname => 'TravellersPalm';

# -----------------------------
# Make sure routes are loaded
# -----------------------------
# Your App.pm already loads them explicitly:
# TravellersPalm::Routes::home
# TravellersPalm::Routes::account
# TravellersPalm::Routes::destinations
# TravellersPalm::Routes::others

# -----------------------------
# Return the Dancer2 app
# -----------------------------
TravellersPalm::App->to_app;
