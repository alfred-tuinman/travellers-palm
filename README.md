# Introduction
We walk you through setting up a containerized web stack using:

Plack / Starman (Perl web server and PSGI app runner)

Template Toolkit (view rendering)

Nginx (front-end reverse proxy / static assets)

SQLite3 (lightweight DB, with support for multiple DB files)

We’ll use Docker Compose so you can spin up the whole stack in a consistent, reproducible way.

## Dancer / Dancer2
Dancer is a Perl web application framework, similar in spirit to Flask (Python) or Express (Node.js). 

Key features: Routing (get, post, etc.), Templating, Sessions, cookies, Logging, Plugins (like database connectors)

## Plack
Plack is a Perl web server interface, like WSGI in Python or Rack in Ruby, and it provides a common interface between our web app (Dancer2) and any web server. Everything talks via PSGI (Perl Web Server Gateway Interface).

# Git

Our repo is called git@github.com:alfred-tuinman/travellers-palm.git

cd to your project.
```
git init
git config --global user.name "Alfred Tuinman"
git config --global user.email "admin@odyssey.co.in"
echo "logs/\napp/db/*.db\n*Zone.Identifier" > .gitignore
git add .
git commit -m "Initial commit"
git remote add origin git@github.com:alfred-tuinman/travellers-palm.git
```
## New project
git push -u origin main

## Existing project
git pull -u origin main


# Project Layout
## Docker Layer:
Dancer2 defines the web app (routes, database, templates).

Plack/Starman serves the app via PSGI interface.

Nginx sits in front, handles static files, logging, reverse proxy.

Docker wraps everything into isolated containers.

This is a good starting directory tree:

plack-app/
├── app/
│   ├── lib/
│   │   └── MyApp.pm
│   ├── views/
│   │   └── index.tt          # plus all other templates
│   ├── app.psgi
│   └── db/                   # persistent volume mount
│       ├── users.db
│       └── Jadoo_2006.db
├── config/
│   ├── config.staging.yml
│   └── config.production.yml
├── nginx/
│   └── default.conf
├── Dockerfile
├── docker-compose.yml
├── cpanfile
└── .env                      # holds secrets & environment flags


We’ll keep SQLite DB files in app/db/ so that they can be mounted as a volume for persistence.


## Step 1: cpanfile

List your Perl dependencies:

## Step 2: app.psgi

A minimal PSGI app using Template Toolkit and DBI/SQLite:

## Step 3: views/index.tt

A simple TT template. If you downloaded these from Windows then run this from your project root

```find . -name '*Zone.Identifier' -exec rm -f {} + ```


## Step 4: Dockerfile

A Perl + Starman container:

## Step 5: nginx/default.conf

Nginx as a reverse proxy

## Step 6: docker-compose.yml

Tie it together:

## Step 7: Build and Run
```docker compose build up -d```

For project-specific rebuilds use:

```docker compose down && docker compose up --build -d```

Visit: http://localhost:8080


# Multiple Databases
In your PSGI app you can open as many SQLite DB connections as you need, each with its own DSN pointing to a file in app/db/.

You may also want a small DB connection manager (e.g., DBIx::Connector) if you expect concurrent access.

I have split the huge Database.pm file into smaller parts.The benefits of this is that each file is < 200 lines instead of 1000+. You can load only what you need in routes and the database logic is modular and testable. 

One could put Routes/ directly under lib/, but the reason we nest it under TravellersPalm/ is namespace hygiene.

I removed this as I cannot find Odyssey2008 and mysql is difficult to set up for some reason

<pre>msqlserver:
        dsn: dbi:ODBC:Odyssey2008
        username: sa
        password: sa123@pwd
        dbi_params:
          RaiseError: 1
          AutoCommit: 1
          PrintError: 1
          LongReadLen: 102400 </pre>

# Logs
Logging depends on the development or production environment set in .env. The log configurations are set in the environments folder and the config.yml and nginx.conf  

```docker-compose logs -f app ```


# Running in Staging vs. Production

## To run staging

```APP_ENV=staging docker compose up -d```


## To run production

```APP_ENV=production STARMAN_WORKERS=8 docker compose up -d```


Nginx is fronting the application and the healthcheck ensures containers restart or wait until the app is ready.


# Production Notes

Persistent Volume: ./app/db holds the SQLite files outside the container.

Backup: regular off-container backups of .db files.

TLS: Terminate HTTPS either at Nginx in the container or use a fronting reverse proxy like Traefik/Caddy.

Security: never bake secrets into images; use .env or a secret manager.

Migrations: for schema changes, use versioned SQL migration tools (e.g., Sqitch).


# Let’s Encrypt - Nothing but trouble!
This will give you free TLS certificates so you can serve your app over HTTPS.
Since you’re already using Nginx as a reverse proxy, we’ll integrate Let’s Encrypt at the Nginx layer.

Below is a practical guide for your containerized setup.

## Approach
UNFORTUNATELY THERE WAS A PROBLEM WITH SOME DEPENDENCIES CAUSING THE DOCKER CONTAINER TO FAIL
We’ll use the popular Certbot client inside a separate container. Certbot will:

Prove you own the domain (via HTTP-01 challenge)

Obtain a certificate from Let’s Encrypt

Place the cert and key in a shared volume

Auto-renew the certificate periodically

Nginx will then use those certificates to serve HTTPS.

Once DNS resolves to your server, run:

docker run --rm \
  -v $(pwd)/nginx/default.conf:/etc/nginx/conf.d/default.conf \
  -v certs:/etc/letsencrypt \
  -v $(pwd)/var/www/certbot:/var/www/certbot \
  certbot/certbot certonly --webroot \
  --webroot-path /var/www/certbot \
  -d www.travellers-palm.com \
  --email admin@odyssey.co.in \
  --agree-tos --no-eff-email



  # Background



## Use a volume (runtime)

# Stop all running containers
```docker ps -q | xargs -r docker stop```

# Delete all stopped containers
```docker ps -aq | xargs -r docker rm```

# Run your container 

```docker run -p 8080:80 -v $(pwd)/data:/app/data -v $(pwd)/logs:/app/logs psgi-app```

This maps host port 8080 to the container port 80 and mounts data/ and logs/ from our project folder

# Restart your docker
```./restart-psgi.sh```

This stops the old container (if running) and removes it and then starts a fresh container with your mounts. It runs in detached mode (-d) so your terminal is free.

You can then also check the logs
```docker logs -f psgi-app-container```

# Access in the browser
```http://localhost:8080```

This should now connect directly to Nginx → Starman → PSGI app

# Install cpanm
```cpanm Template```

If you don’t have cpanm, you can install it first:
```curl -L https://cpanmin.us | perl - App::cpanminus```

then retry
```cpanm Template```

# .psgi
The entrypoint mentions a psgi file.

lib/app.psgi generates the welcome message to test that the site works in the browser.

lib/tt.psgi makes the link to the template toolkit files. All templates are in data/views/ (so index.tt, about.tt, contact.tt go there). The middleware serves static files from public/static/

# Dancer
Our app logic lives in lib/TravellersPalm.pm (the Dancer app module) and the routes are inside this file. This is the Dancer2 app entry point, and here we link all our routes. We use Module::Find which will scan for everything under TravellersPalm::Routes::*.

As a result we don’t need to manually use TravellersPalm::Routes::Home anymore. Adding a new file like TravellersPalm::Routes::Bookings.pm is enough — it gets auto-loaded on startup.

We specify
```use Dancer2 appname => 'TravellersPalm';```

This explicitly assigns a named app (TravellersPalm) to that package. The advantages are:

Clear separation: Multiple packages can define routes for the same app without ambiguity.

PSGI testing / embedding: You can reference the app explicitly:

# Database
