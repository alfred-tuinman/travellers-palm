#!/usr/bin/env bash
# Runs the Perl test suite inside the Docker app container
set -euo pipefail

service="travellers_palm_app"
if [ $# -eq 0 ]; then
  set -- t/
fi

exec docker compose run --rm "$service" carton exec -- prove -lv "$@"
