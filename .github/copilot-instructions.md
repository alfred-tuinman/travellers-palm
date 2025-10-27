## Travellers Palm — Copilot instructions

This file gives focused, actionable guidance for an AI coding agent to be productive in this repo.

### Big picture (what this app is)
- A Mojolicious-based Perl web app. Entry point: `script/travellers_palm` and `lib/TravellersPalm.pm`.
- Modules are under `lib/TravellersPalm/` (Logger, Mailer, Helpers, Hooks, Routes, Database). Templates use Template Toolkit (`*.tt`) in `templates/` and static assets under `public/`.
- Seed DBs live in `localdb/` (read-only inside image). Runtime DBs are copied to `data/` on startup.

### Key files to consult first
- `config.yml` — main runtime configuration (databases, template tokens, memcached, logging).
- `lib/TravellersPalm.pm` — app bootstrap (registers Database connector/initializer, Logger, Mailer, Cache, Helpers, Hooks, Routes).
- `lib/TravellersPalm/Database/Initializer.pm` — seed => runtime DB copy logic and `seed_version` string (bump here to force reseed).
- `Dockerfile` / `docker-compose.yml` — how images/volumes are built and what is mounted in development.
- `t/01-startup.t` — a minimal smoke test that shows how tests expect the app to be loaded.

### Short developer workflows (exact commands)
- Install dependencies locally (non-Docker):
  - `cpanm --notest Carton` (once)
  - `carton install --without=develop`
- Run the app locally (development, with hot reload):
  - `carton exec -- morbo -l http://*:3000 script/travellers_palm`
- Run tests (use Carton so installed modules are available):
  - `carton exec -- prove -lv t/`  (or `prove -lv t/` if environment already configured)
- Build & run with Docker Compose:
  - `docker-compose up --build` (volumes in `docker-compose.yml` mount `data/`, `log/`, `carton_cache/` so template changes do not require rebuild)

### Project-specific conventions and pitfalls
- DB seed/version: The initializer copies the first `databases:` DSN's file from `localdb/` to `data/` and writes `data/db_version.txt`. To force re-seeding after changing localdb content, update the `seed_version` string in `lib/TravellersPalm/Database/Initializer.pm`.
- Dependency caching: `cpanfile` and `cpanfile.snapshot` are used with Carton. Docker/CI will cache the layer if those files didn't change. Use `carton update` then commit `cpanfile.snapshot` when changing deps.
- Template Toolkit: `.tt` templates expect certain tokens injected by hooks (see `before_render` in `TravellersPalm::Hooks`). Editing templates typically doesn't need an app restart when using the mounted `templates/` volume in compose.
- Logs: runtime logs are placed in `log/` (e.g., `log/travellers_palm.log.*`). Look there for stack traces when debugging.

### How to change common things (examples)
- Add a dependency: edit `cpanfile`, run `carton install` (or `carton update`) and commit `cpanfile.snapshot`. In Docker builds the layer will update automatically.
- Force DB reseed after schema/data changes: update `seed_version` in `lib/TravellersPalm/Database/Initializer.pm`, then start the app so `data/<dbname>` will be overwritten from `localdb/`.
- Add a route: update `lib/TravellersPalm/Routes.pm` and corresponding controller/template; test via `prove` or manual HTTP requests.

### Tests and CI notes
- Tests are standard Perl `.t` tests under `t/`. Use `prove -lv t/` (preferably wrapped by `carton exec --`). `t/01-startup.t` is a useful smoke test that loads `app.psgi`.
- If tests fail due to missing modules, ensure `carton install` completed and that you run tests under `carton exec` or have `PERL5LIB` pointing to `carton` local lib path.

### Integration & external services
- Memcached is optional and configured in `config.yml` (default `127.0.0.1:11211`).
- Email settings are in `config.yml` under `email:`. Error email templates live in `templates/` (look for `mail/error_email.tt`).

### Where to look for further context
- For startup sequence, open `lib/TravellersPalm.pm` (bootstrap) and the modules under `lib/TravellersPalm/`.
- For DB logic: `lib/TravellersPalm/Database/*`.
- For UI and static assets: `templates/` and `public/`.

If anything here is unclear or you'd like the instructions expanded (CI examples, common PR checklist, or adding small helper scripts), tell me which area to expand and I will iterate.
