#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/meditrack}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.prod.yml}"

cd "$APP_DIR"

if [[ -n "${GHCR_USERNAME:-}" && -n "${GHCR_TOKEN:-}" ]]; then
  echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USERNAME" --password-stdin
fi

if [[ "${SKIP_PULL:-0}" != "1" ]]; then
  docker compose -f "$COMPOSE_FILE" pull
fi

docker compose -f "$COMPOSE_FILE" up -d --remove-orphans
docker compose -f "$COMPOSE_FILE" exec -T backend ./bin/rails db:prepare
if [[ "${RUN_SEEDS:-1}" == "1" ]]; then
  docker compose -f "$COMPOSE_FILE" exec -T backend ./bin/rails db:seed
fi
docker compose -f "$COMPOSE_FILE" ps
