# MediTrack Architecture

MediTrack is currently a compact monorepo with three runtime services:

- `backend`: Ruby on Rails API
- `frontend`: React + TypeScript UI
- `db`: PostgreSQL

The repository keeps `backend/`, `frontend/`, deployment scripts, and Compose files at the top level. This is intentionally simpler than an `/apps`, `/services`, `/infra` split because the application has one API and one web client. A physical move to `/apps/api` and `/apps/web` would be reasonable when another app or independently deployed service is added.

## Backend

- REST API is versioned under `/api/v1`.
- Domain persistence is modeled with `HealthcareUnit`, `Medication`, `Order`, `OrderLine`, and `AuditLog`.
- Order lifecycle transition logic lives in `Orders::Advance`.
- Delivery inventory updates run inside a database transaction and use row locks for the order and affected medications.
- Audit logging records critical create/update/delete and order transition events.

## Frontend

- React + TypeScript provides the clinical dashboard.
- The current state layer uses local component state and explicit refreshes after mutations. This keeps the assignment small and predictable.
- The UI has loading and error states plus a top-level error boundary.

## Search

Medication search currently uses PostgreSQL `ILIKE` queries over name, ATC code, and form. Elasticsearch is not included because the sample dataset is small and introducing another required service would add operational cost without improving this assignment's behavior. The medication search logic is isolated enough to replace with an Elasticsearch-backed service when volume or ranking requirements justify it.

## Deployment

GitHub Actions runs CI, builds production Docker images, pushes to GitHub Container Registry, and deploys to a Docker host over SSH using `docker-compose.prod.yml` and `scripts/deploy.sh`.
