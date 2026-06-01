# ADR 0001: Keep A Compact Monorepo Layout

## Status

Accepted

## Context

The proposed target structure uses `/apps`, `/services`, `/infra`, and `/docs`. MediTrack currently has one Rails API, one React frontend, one PostgreSQL database, and deployment scripts.

## Decision

Keep the current top-level `backend/` and `frontend/` directories and add `docs/` for architecture notes. Do not move files into `/apps` until there is more than one independently deployable app or service.

## Consequences

- Docker, Makefile, and GitHub Actions remain straightforward.
- The repository is still clearly separated by backend, frontend, and infrastructure files.
- A future move to `/apps/api` and `/apps/web` is low risk once the extra structure has a clear payoff.
