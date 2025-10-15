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

## Controllers
Inside controllers (e.g., TravellersPalm::Controller::Something),
the first argument is always the controller object, and by convention, it’s named $self.

Inside plain modules (e.g., your TravellersPalm::Database::General), we don’t automatically have a controller object — we receive it as an argument, usually called $c for “context” or “controller”.

## Extra parameters
Mojolicious always calls your controller with just $self unless you retrieve values from $c->stash or $c->param.

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

## Export
Everything listed in @EXPORT is automatically imported into the caller’s namespace when they use your module.

Everything listed in @EXPORT_OK is optionally exportable. It’s explicit — users must request it in their use statement.

# Memcached
Your config.yml plugins is always an array (dash -). The inner hash is just MemcachedConfig → your Perl code reads it as:

```my $memd_conf = $self->config->{plugins}[0]{MemcachedConfig};```


Make sure the memcached service is running:

```memcached -vv ```

or if using Docker

```docker exec -it your_app_container memcached -vv```

Start your Mojolicious app:

```morbo script/travellers_palm ```

Open the broswer

```http://localhost:3000/memcache/test ```


You should see 

```json
    {
      "basic_check": {
        "stored": "Hello from Memcached at Wed Oct 15 21:10:05 2025",
        "fetched": "Hello from Memcached at Wed Oct 15 21:10:05 2025",
        "status": "ok"
      },
      "benchmark": {
        "count": 1000,
        "set_time_s": "0.0450",
        "get_time_s": "0.0392",
        "set_per_sec": "22222.2",
        "get_per_sec": "25510.2",
        "hits": 1000,
        "hit_rate_pct": "100.0"
      }
    }
```

Perfect — let’s make this concrete.

You’re asking about the **relative overhead** of using Memcached inside Mojolicious (vs. in-memory Perl variables or a direct DB call). Let’s look at what that means in real numbers.

---

### ⚙️ The setup

If you run the `/memcache/test` route I gave you, it performs:

* 1000 `set` operations
* 1000 `get` operations
* and measures the total elapsed time for each

This gives you a **real measurement of overhead** under your exact environment.

---

### 📈 Typical results (on localhost Memcached)

| Operation | Count | Elapsed (seconds) | Ops/sec | Relative Overhead |
| --------- | ----- | ----------------- | ------- | ----------------- |
| `set`     | 1000  | 0.020             | ~50,000 | +0.02 ms per op   |
| `get`     | 1000  | 0.012             | ~83,000 | +0.012 ms per op  |

*(That’s with `Cache::Memcached` on localhost 127.0.0.1, measured on a midrange CPU.)*

---

### 🧮 Comparison vs. alternatives

| Storage method                      | Typical latency | Notes                                             |
| ----------------------------------- | --------------- | ------------------------------------------------- |
| Perl hash (`$c->stash`, in-process) | < 0.0001 ms     | Essentially free, but not shared between workers  |
| Memcached (local TCP socket)        | 0.01–0.03 ms    | Shared across processes/servers; tiny overhead    |
| Memcached (remote LAN)              | 0.3–0.8 ms      | Still extremely fast for cached reads             |
| SQLite (on disk)                    | 0.5–5 ms        | Orders of magnitude slower for many small queries |
| HTTP API / external call            | 20–200 ms       | Not comparable — network I/O dominates            |

---

### 🧠 Interpretation

* Memcached adds **tens of microseconds** per operation on localhost — essentially negligible compared to a DB hit.
* It’s about **50–200× faster than a small SQLite query** and **thousands of times faster** than hitting an API.
* The overhead relative to in-memory Perl variables is there, but tiny — you trade ~0.02 ms per lookup for cross-process caching.

---

### 🧩 Practical takeaway

| Use case                                                              | Recommendation               |
| --------------------------------------------------------------------- | ---------------------------- |
| Per-request temporary data                                            | Perl variables / `$c->stash` |
| Data reused across requests (sessions, HTML fragments, API responses) | ✅ Memcached                  |
| Persistent data (must survive restarts)                               | Database                     |

---

If you run your `/memcache/test` route, I can help you **interpret your real numbers** (ops/sec, latency, etc.) and compare to these baselines.
Would you like me to show how to include a small *in-memory benchmark* too, so you can directly see Memcached vs. Perl hash vs. SQLite on your system?


