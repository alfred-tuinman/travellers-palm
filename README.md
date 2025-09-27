# Introduction
We walk you through setting up a containerized web stack using:

Plack / Starman (Perl web server and PSGI app runner)

Template Toolkit (view rendering)

Nginx (front-end reverse proxy / static assets)

SQLite3 (lightweight DB, with support for multiple DB files)

We’ll use Docker Compose so you can spin up the whole stack in a consistent, reproducible way.


# Project Layout

A good starting directory tree:

plack-app/
├── app/
│   ├── lib/
│   │   └── MyApp.pm
│   ├── views/
│   │   └── index.tt
│   ├── app.psgi
│   └── db/                  # persistent volume mount
│       ├── users.db
│       └── Jadoo_2006.db
├── scripts/
│   ├── init-db.sh           # initializes SQLite DBs
│   └── healthcheck.sh       # checks if app responds
├── config/
│   ├── config.staging.yml
│   └── config.production.yml
├── nginx/
│   └── default.conf
├── Dockerfile
├── docker-compose.yml
├── cpanfile
└── .env                     # holds secrets & environment flags


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