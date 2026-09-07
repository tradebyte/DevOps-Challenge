#!/usr/bin/env bash
set -euo pipefail

URL="${1:-http://tradebyte.local/}"
echo "Testing ${URL}"
curl --fail --silent --show-error "${URL}" >/dev/null
echo "Smoke test passed"
