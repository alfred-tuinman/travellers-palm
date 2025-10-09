# Our project
We opted here to now move to Mojolicious, modern, non-blocking web framework for Perl, inspired by Ruby.

Strengths:

Built-in support for WebSockets and asynchronous processing.

Comes with a powerful command-line tool (mojo) for scaffolding and testing.

Suitable for real-time applications and APIs.

With this setup:

All controllers (Home, Hotels, Destinations, MyAccount, Images) are Mojolicious-native

Routes in TravellersPalm.pm are fully configured

Session and template tokens work via hooks

Templates and public assets are cleanly separated

Catch-all 404 page handles missing pages

# Project structure
TravellersPalm/
├─ bin/
│   └─ travellerspalm  # Mojolicious app runner (morbo/hypnotoad)
├─ lib/
│   └─ TravellersPalm/
│       ├─ Controller/
│       │   ├─ Home.pm
│       │   ├─ Destinations.pm
│       │   ├─ Hotels.pm
│       │   └─ MyAccount.pm
│       ├─ Constants.pm
│       ├─ Functions.pm
│       └─ Database/
│           ├─ Connector.pm
│           ├─ General.pm
│           ├─ States.pm
│           └─ Themes.pm
├─ localdb/
│   └─ Jadoo_2006.db
├─ public/
│   ├─ css/
│   ├─ js/
│   └─ images/
├─ templates/
│   ├─ layouts/
│   │   └─ default.html.tt
│   ├─ home/
│   │   ├─ index.html.tt
│   │   ├─ about.html.tt
│   │   └─ contact.html.tt
│   ├─ destinations/
│   │   ├─ destination.html.tt
│   │   ├─ regions.html.tt
│   │   ├─ state.html.tt
│   │   ├─ theme.html.tt
│   │   └─ plan_your_trip.html.tt
│   ├─ hotels/
│   │   ├─ hotel_categories.html.tt
│   │   └─ hand_picked_hotels.html.tt
│   └─ my_account/
│       ├─ login.html.tt
│       └─ register.html.tt
├─ travelllerspalm.conf
└─ TravellersPalm.pm
├─ config.yml
├─ cpanfile
├─ docker-compose.yml
├─ Dockerfile
├─ nginx.conf
├─ README.md
├─ restart.sh

# cpanfile
Put all Perl module dependencies in cpanfile. That way, Docker rebuilds dependencies only when they change.

You can also generate a cpanfile.snapshot by running:

``` carton install ```

on your development machine. This locks module versions, ensuring consistent builds.

🔥 Result:
You now have a single file (cpanfile) controlling all your CPAN dependencies.
Your Docker builds become reproducible and faster, and you avoid forgetting a module.

# Problem solving with code colour display
Quick commands you can run in the project folder to help find problems:
# show lines that start POD tags
```grep -nE '^=(head|pod|begin|cut)' lib/TravellersPalm/Functions.pm```

# show unmatched quotes roughly (not perfect):
```perl -nle 'print "$.: $_" if /"/' lib/TravellersPalm/Functions.pm | wc -l ```

## Database
Best practice: pass $c explicitly. That way Generate.pm doesn’t rely on any hidden global and can even be used outside a request if you mock a $c with a DB handle.

use Mojo::Base 'Mojolicious::Controller'; is only needed in modules or classes that you want to behave like a Mojolicious object or controller subclass. It does a few things:

Provides has for attributes.

Sets up object-oriented inheritance.

Adds strict/warnings automatically (so you don’t need use strict; use warnings;).