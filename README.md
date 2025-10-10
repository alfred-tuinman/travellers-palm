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

# Mojolicious
In Mojolicious:

Inside controllers (e.g., TravellersPalm::Controller::Something),
the first argument is always the controller object, and by convention, it’s named $self.

Inside plain modules (e.g., your TravellersPalm::Database::General),
we don’t automatically have a controller object — we receive it as an argument, usually called $c for “context” or “controller”.

# Cpanminus
For development you would like to test the app locally for which you need the cpan modules. 

Make sure cpan is installed 

```sudo apt install cpanminus```

Update and install essential build tools
```bash
sudo apt update
sudo apt install -y build-essential curl wget git
sudo apt install -y perl perl-modules perl-base
sudo apt install -y libperl-dev 
```

DateTime and other XS modules often need system libraries:
```bash
sudo apt install -y \
    libssl-dev libexpat1-dev libncurses5-dev libreadline-dev \
    libsqlite3-dev zlib1g-dev libbz2-dev libffi-dev
```
These cover common modules like DateTime, DBI, DBD::SQLite, JSON::XS, etc.

If you want a local install without sudo:
```bash
curl -L https://cpanmin.us | perl - --local-lib=~/perl5
echo 'export PERL5LIB=~/perl5/lib/perl5:$PERL5LIB' >> ~/.bashrc
echo 'export PATH=~/perl5/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```
Install modules from your CPANfile and to install the CPAN modules locally, if you haven't got a local perl folder

```cpanm --installdeps --local-lib=~/perl5 . ```

or else run

```cpanm --installdeps . ```

This may take some time, especially the first time, depending on the modules in your cpanfile. 


Recreate your local Perl directory
```mkdir -p ~/perl5/lib/perl5```

Configure environment variables
```bash
export PERL_LOCAL_LIB_ROOT=~/perl5
export PERL_MB_OPT="--install_base ~/perl5"
export PERL_MM_OPT="INSTALL_BASE=~/perl5"
export PATH=~/perl5/bin:$PATH
export PERL5LIB=~/perl5/lib/perl5
```
Then reload the shell
```source ~/.bashrc```

Test that local::lib works
```perl -Mlocal::lib```

Optional: To avoid repeating the --local-lib option every time, set it globally for cpanm:
```echo 'local::lib ~/perl5' >> ~/.cpanm/config ```

## Dumper helper function
TravellersPalm.pm has a helperfile called dump_log allowing a message with a variable to be called like $self->dump_log('Help me here with ',$var)