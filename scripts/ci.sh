#!/usr/bin/env bash
set -euo pipefail

docker compose exec backend bin/rails test
docker compose exec frontend npm run build
