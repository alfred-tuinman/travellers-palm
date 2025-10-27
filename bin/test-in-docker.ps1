# Runs the Perl test suite inside the Docker app container
param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Tests
)

$ErrorActionPreference = "Stop"
$service = "travellers_palm_app"
if (-not $Tests -or $Tests.Count -eq 0) { $Tests = @("t/") }

# Invoke docker compose with passthrough args to prove
& docker compose run --rm $service carton exec -- prove -lv @Tests
