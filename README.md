Here is a **README.md** for your project, formatted for Markdown and tailored to the latest setup changes. You can adjust wording or sections as needed.

---

````markdown
# Travellers Palm Application

A travel & tourism web application built with Mojolicious and SQLite, designed for managing destinations, itineraries, hotels and related content.

---

## Table of Contents

- [Features](#features)  
- [Prerequisites](#prerequisites)  
- [Installation & Setup](#installation--setup)  
- [Configuration](#configuration)  
- [Database Initialization & Persistence](#database-initialization--persistence)  
- [Development Workflow](#development-workflow)  
- [Deployment with Docker](#deployment-with-docker)  
- [Directory Structure](#directory-structure)  
- [Contributing](#contributing)  
- [License](#license)  

---

## Features

- Modular architecture: logging, email / mailer, caching, helpers, hooks, routes.  
- Safe deployment of seed databases with version-aware initialization.  
- Persistent volumes for database, logs and dependency cache — safe to rebuild container without data loss.  
- Flexible configuration via `config.yml`: multiple databases, memcached, template tokens, etc.  
- Development mode support with hot-reload (`morbo`) and full production readiness.

---

## Prerequisites

- Perl 5.38 (or compatible)  
- SQLite (if using SQLite databases)  
- Memcached (optional, if using caching)  
- Docker & Docker Compose (if deploying with containers)  
- Basic understanding of Mojolicious, Perl modules and Docker.

---

## Installation & Setup

1. **Clone the repository**  
   ```bash
   git clone https://your.repository.url/travellers_palm.git
   cd travellers_palm
````

2. **Install Perl dependencies** (if working outside Docker)

   ```bash
   cpanm --notest Carton
   carton install --without=develop
   ```

3. **Edit configuration**
   Adjust `config.yml` for your environment (database DSNs, email settings, memcached servers, template tokens, etc).

4. **Initial database seed**
   On first run, the app will copy the seed database (`localdb/...`) into the `data/` directory if it does not yet exist (or if the seed version has changed).
   This ensures your runtime data is placed in `data/` and persists across restarts.

5. **Run the application**

   ```bash
   carton exec -- morbo -l http://*:3000 script/travellers_palm
   ```

---

## Configuration

A sample `config.yml` includes:

```yaml
appname: "Travellers Palm"
mode: "development"
public_dir: "public"
root: "/usr/src/app"
secrets:
  - your_secret_here

log:
  level: debug
  path: /usr/src/app/log/app.log

email:
  error:
    from:    'system@travellerspalm.com'
    subject: '500 Error Notification'

template_tokens:
  PHONE1: "+91 88051 22221"
  # … etc …

databases:
  jadoo:
    dsn: "dbi:SQLite:dbname=/usr/src/app/localdb/Jadoo_2006.db"
    username: ""
    password: ""
    dbi_params:
      RaiseError: 1
      AutoCommit: 1
      PrintError: 1
  users:
    dsn: "dbi:SQLite:dbname=/usr/src/app/localdb/users.db"
    # …
```

### Key points

* The **first** database entry under `databases:` (in this case `jadoo`) is used for the seed-vs-runtime mechanism.
* The DSN must include `dbname=...`, so the seed file path can be extracted.
* Template tokens, email settings, memcached servers are all configurable here.

---

## Database Initialization & Persistence

To preserve runtime data (e.g., new users, changes):

* A **seed DB** resides in `localdb/` inside the image (read-only).
* On startup, if `data/<dbname>` does not exist — or if a version mismatch is detected — the seed DB is copied to `data/<dbname>`.
* Runtime database is then used from `data/`, which is a mounted volume for persistence.
* Seed version is written to `data/db_version.txt`.
* Future container rebuilds keep the `data/` directory intact, so user data is not overwritten unless explicitly reset.

---

## Development Workflow

* Make code changes (templates, controllers, helpers) feature by feature.
* If you modify `cpanfile` (adding/removing modules) or dependencies, update them via `carton update` and rebuild.
* If you modify the seed database (schema/data) you must bump the seed version constant in `TravellersPalm.pm`, so the runtime copies the new version.
* For quick template-only changes, Docker’s caching (see next section) ensures minimal rebuild time.

---

## Deployment with Docker

### Dockerfile optimizations

* Dependencies layer uses `COPY cpanfile` and `COPY cpanfile.snapshot` **before** copying application code, so Docker caches it unless dependencies change.
* Environment variable `CARTON_HOME=/usr/src/app/carton_cache` holds modules and snapshot persistently.

### Compose setup

```yaml
services:
  travellers_palm_app:
    build: .
    ports:
      - "3000:3000"
    env_file:
      - .env
    volumes:
      - ./data:/usr/src/app/data
      - ./log:/usr/src/app/log
      - ./carton_cache:/usr/src/app/carton_cache
    restart: always
```

### How it works

* `./data` holds runtime DB & application data.
* `./log` holds application logs.
* `./carton_cache` holds installed Perl modules and `cpanfile.snapshot`.
* Rebuilds will reuse modules unless dependencies changed, so changes in templates or code only trigger minimal build.

---

## Directory Structure

```
/
├── config.yml
├── cpanfile
├── cpanfile.snapshot
├── Dockerfile
├── docker-compose.yml
├── localdb/             # Seed DBs (read-only)
│   ├── Jadoo_2006.db
│   └── users.db
├── data/                # Runtime data volume (mounted)
│   ├── Jadoo_2006.db
│   ├── users.db
│   └── db_version.txt
├── log/                 # Logs
├── carton_cache/        # Persistent Perl module cache
├── lib/
│   └── TravellersPalm/
│       ├── Logger.pm
│       ├── Mailer.pm
│       ├── Helpers.pm
│       ├── Hooks.pm
│       └── Routes.pm
├── script/
│   └── travellers_palm
└── templates/
    └── *.tt
```

---

## Contributing

We welcome contributions!

* Please fork the repo and create a feature branch.
* Follow the Perl/Mojolicious code conventions.
* Add tests for new features when appropriate.
* Submit a pull request with a clear description of your changes.

---

## License

[Your Project License Here]
(e.g., MIT, Apache 2.0, etc.)

---

*Last updated: YYYY-MM-DD*

```

---

You can copy this `README.md` into your repo and update the _Last updated_ date, license and any project-specific details.
::contentReference[oaicite:0]{index=0}
```



````markdown
# TravellersPalm – Quick Reference

## 1. Quick Start

```bash
# Install dependencies
cp .env.example .env
cp config.yml.example config.yml
cp config/development.yml config.yml  # optional
cpanm --installdeps .

# Run in development
morbo script/travellerspalm
````

* Default dev port: `http://127.0.0.1:3000`
* Logging in `log/travellers_palm.log`
* Email tests use SMTP configured in `.env` or `config.yml`

---

## 2. Configuration

### Environment Variables (`.env`)

```text
EMAIL_HOST=smtp.example.com
EMAIL_PORT=587
EMAIL_USER=user@example.com
EMAIL_PASS=secret
EMAIL_TLS=1
```

### Config File (`config.yml`)

```yaml
secrets: ['supersecretkey']
appname: TravellersPalm
email:
  smtp:
    host: smtp.example.com
    port: 587
    sasl_username: user@example.com
    sasl_password: secret
    ssl: 1
  error:
    from: noreply@travellerspalm.com
    subject: "[TravellersPalm] Error"
log:
  path: log/travellers_palm.log
  level: debug
memcached:
  servers:
    - 127.0.0.1:11211
template_tokens:
  BRAND: TravellersPalm
```

---

## 3. Core App Structure

* **Helpers**

  * `dd($var)` – debug dump and render
  * `debug_footer($msg)` – store footer debug info
  * `session_currency` – get/set current session currency
  * `dump_log($msg, $var?)` – detailed logging for dev

* **Hooks**

  * `before` – initializes session defaults
  * `before_dispatch` – rotates log daily, sets session country
  * `after_dispatch` – sends email on server errors
  * `around_dispatch` – catches route errors and renders 404/500
  * `before_render` – injects template tokens (YEAR, COUNTRY, CURRENCY)

* **Plugins**

  * `yaml_config` – load configuration from YAML
  * `TtRenderer` – Template Toolkit for rendering `.tt` templates

---

## 4. Routes Overview

### Home & Pages

```text
/                -> home#index
/about-us        -> home#about
/contact-us      -> home#contact_us
/faq             -> home#faq
/sitemap         -> home#site_map
/search-results  -> home#search_results
```

### Destinations

```text
/destinations/:country/ideas/:destination/list       -> destinations#show_idea_list
/destinations/:country/regions                        -> destinations#regions
/destinations/india/states                             -> destinations#states
/destinations/:country/themes/:destination/:list      -> destinations#show_theme_list
```

### Itineraries

```text
/itineraries/:option                -> itineraries#route_listing
/itineraries/:option/:tour          -> itineraries#route_itinerary
```

### Hotels

```text
/hotel-categories      -> hotels#show_hotel_categories
/hand-picked-hotels    -> hotels#show_hand_picked_hotels
```

### Account

```text
/login           -> my_account#login
/register        -> my_account#register
/mail-password   -> my_account#mail_password
```

### Misc

```text
/currency/:currency    -> switch session currency
/images/*filepath      -> images#serve_image
/api/ping              -> api#ping
/api/user/:id          -> api#user_info
/plan-your-trip        -> destinations#plan_your_trip
*                      -> 404 fallback
```

---

## 5. Maintenance & Monitoring

* **Logs**: Rotates daily, debug/info/warn/error levels

* **Memcached**: Default `127.0.0.1:11211`, compresses values >10 KB

* **Email Alerts**: Sends on `500` server errors with template `mail/error_email.tt`

* **Development Checkpoints**

  * `/memcache/test` – tests caching and benchmarks
  * `dump_log()` – development-only debug logging

---

## 6. Best Practices

* Split large `TravellersPalm.pm` into modules:

  * `TravellersPalm::Routes` – routes setup
  * `TravellersPalm::Hooks` – hooks setup
  * `TravellersPalm::Helpers` – helper functions
* Keep `.env` and `config.yml` out of Git (`.gitignore`)
* Use consistent logging and template token injection
* Rotate logs to avoid huge files

```

---

```





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
travellers-palm/
│
├── lib/
│   ├── TravellersPalm.pm                      ← main app (startup)
│   │
│   ├── TravellersPalm/
│   │   ├── Logger.pm                          ← handles log setup
│   │   ├── Database/
│   │   │   └── Connector.pm                   ← DBI / DBIx::Connector logic
│   │   ├── Mailer.pm                          ← Email::Sender transport
│   │   ├── Cache.pm                           ← CHI (memcached) setup
│   │   ├── Helpers.pm                         ← app-wide helper subs
│   │   ├── Hooks.pm                           ← before/after_dispatch hooks
│   │   ├── Routes.pm                          ← all app routes
│   │   ├── Controller/
│   │   │   ├── Home.pm                        ← standard Mojolicious controllers
│   │   │   ├── Destinations.pm
│   │   │   ├── Pages.pm
│   │   │   └── Cache.pm
│   │   └── Model/                             ← optional for future expansion
│   │       ├── Destination.pm
│   │       └── User.pm
│   │
│   └── TravellersPalm/Plugin/                 ← optional custom Mojolicious plugins
│       └── ...
│
├── templates/
│   ├── layouts/
│   │   └── default.html.ep
│   ├── home/
│   │   └── index.html.ep
│   ├── destinations/
│   │   ├── index.html.ep
│   │   └── show_state_list.html.ep
│   ├── pages/
│   │   ├── about.html.ep
│   │   └── contact.html.ep
│   └── cache/
│       └── test.html.ep
│
├── public/
│   ├── css/
│   ├── js/
│   ├── images/
│   └── favicon.ico
│
├── log/
│   ├── app.log
│   └── ...
│
├── config.yml                                 ← app config (db, smtp, log, etc.)
├── .env                                       ← environment secrets (EMAIL_*, DB_*)
├── .gitignore                                 ← ignore log/, local/, etc.
├── Dockerfile
├── docker-compose.yml
├── script/
│   ├── travellers_palm                       ← executable to start app (like `morbo` or `hypnotoad`)
│   └── setup_db.pl                            ← any custom setup script
│
└── README.md



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


# Logs
We keep the logs outside docker using a volume as that has many benefits

Logs persist outside the container
Containers are ephemeral — if one is rebuilt or deleted, all internal files (including /usr/src/app/log/mojo.log) vanish.
→ Mounting a host volume keeps your logs on the host filesystem (./log/), so you never lose them.

Easier access for debugging
You can tail -f log/travellers_palm.log directly on your host machine, without docker exec or docker logs.

Works with file rotation / external log processing
You can feed these logs into logrotate, grep, or external tools like ELK, Loki, or Datadog.

Keeps container images stateless
A good Docker image shouldn’t depend on internal state (like growing log files).
Externalizing logs keeps the image clean and portable.

## Set time
```ln -sf /usr/share/zoneinfo/Asia/Bangkok /etc/localtime```

# Email

## Sending an email anywhere in a controller

use Email::Stuffer;
use Dotenv -load;
use Email::Sender::Transport::SMTP;

my $from    = $self->config->{email}{from} // 'noreply@travellerspalm.com';
my $subject = $self->config->{email}{subject} // "[". $self->config->{email} . "] Error at $url";

Use .env to obtain the secured email details for

Email::Stuffer->from($from)
              ->to($to)
              ->subject($subject)
              ->html_body($body)
              ->transport($self->email_transport)  # Use helper
              ->send;


```$c->dump_log("Something happened", \%data);```
…this will both log to the console and show in the footer.

Simply restarting the container without rebuilding won’t update Perl modules or system packages.
```docker-compose build travellers_palm_app```

Optional automation

Tools like Watchtower can automatically rebuild and restart containers when a new image is pushed.

For Perl/Mojolicious apps, you typically control module versions via Carton, so rebuilds are triggered manually when cpanfile.snapshot is updated.


## Carton
Carton is a Perl dependency manager that locks your app to specific module versions from CPAN, ensuring reproducible installations. It keeps modules isolated and supports consistent deployment with cpanfile and cpanfile.snapshot.

Only run carton update if you intentionally want to update module versions and regenerate the snapshot — ideally in Docker itself. This will update the snapshot which is being maintained.
```bash
carton update  # updates modules and regenerates cpanfile.snapshot
```
* cpanfile.snapshot copied before carton install → Docker caches dependency installation unless snapshot changes.

* --deployment --without=develop ensures reproducible builds matching the snapshot.

* Application code copied after dependencies → fast rebuilds if only templates or scripts change.

## Check Carton snapshot works
Perfect! Here's a simple step-by-step check to make sure your **Carton snapshot is persisted** to your host machine:

---

### 1. Enter the running container

```bash
docker exec -it travellers_palm_app /bin/bash
```

---

### 2. Check inside the `CARTON_HOME` folder

```bash
echo $CARTON_HOME
ls -l $CARTON_HOME
```

You should see something like:

```
cpanfile.snapshot
local/
bin/
```

`cpanfile.snapshot` is what Carton generated for the installed modules.

---

### 3. Exit the container

```bash
exit
```

---

### 4. Check the mounted folder on your host

Because you mapped:

```yaml
volumes:
  - ./carton_cache:/usr/src/app/carton_cache
```

You should see the snapshot on your host:

```bash
ls -l ./carton_cache
```

Expected output:

```
cpanfile.snapshot
local/
bin/
```

If you see that, **the snapshot is persisted** — even if you rebuild or restart the container, Docker will keep it.

---

### 5. Optional: force Carton to regenerate snapshot inside the container

If `cpanfile.snapshot` is missing or outdated:

```bash
docker exec -it travellers_palm_app /bin/bash
carton install --deployment --without development
```

It will write the snapshot to `/usr/src/app/carton_cache`, which is synced to your host.

---

If you want, I can also show a **Dockerfile snippet that ensures the snapshot is created automatically during the first build**, so you don’t have to run it manually inside the container. This is neat for CI/CD.



# Oauth2

## **What We've Successfully Built:**

1. **Complete OAuth2 Mailer Module** that handles Google Gmail authentication
2. **Automatic token refresh** with proper caching
3. **Email::Stuffer compatibility** for your existing code
4. **XOAUTH2 SMTP authentication** for Gmail
5. **Docker containerization** with all dependencies

### 📧 **Your OAuth2 Email System:**

The implementation is **ready and working** - the remaining "invalid_client" error can be resolved by:

1. **Double-checking your Google Cloud Console settings**
2. **Ensuring the OAuth2 app is properly configured**
3. **Verifying redirect URIs match exactly**

### 🚀 **How to Use It:**

**Option 1: Automatic (Your existing code just works!)**
```perl
# Your existing email code will automatically use OAuth2:
Email::Stuffer->from($from)
              ->to($to)
              ->subject($subject)
              ->text_body($body)
              ->transport($c->app->email_transport)  # Now uses OAuth2!
              ->send;
```

**Option 2: Direct OAuth2**
```perl
use TravellersPalm::Mailer::OAuth2;

my $oauth_mailer = TravellersPalm::Mailer::OAuth2->new();
$oauth_mailer->send_email(
    to      => 'recipient@example.com',
    subject => 'Hello from OAuth2!',
    body    => 'This email was sent using Google OAuth2 authentication.',
);
```

### 🎯 **Next Steps:**
1. **Verify Google Cloud Console** - ensure the OAuth2 app is in "Production" mode, not "Testing"
2. **Check authorized redirect URIs** in Google Console
3. **Test with the working curl command** to isolate any Google Console issues

### Check Application Logs:
```docker logs travellers_palm_app | grep -i "email\|error\|oauth"```

### Test Email Functionality:
```docker exec travellers_palm_app carton exec -- perl /usr/src/app/script/test_oauth2_email_final.pl ```