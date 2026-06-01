# MediTrack Architecture

MediTrack is currently a compact monorepo with three runtime services:

- `backend`: Ruby on Rails API
- `frontend`: React + TypeScript UI
- `db`: PostgreSQL

The repository keeps `backend/`, `frontend/`, deployment scripts, and Compose files at the top level. This is intentionally simpler than an `/apps`, `/services`, `/infra` split because the application has one API and one web client. A physical move to `/apps/api` and `/apps/web` would be reasonable when another app or independently deployed service is added.

## Backend

- REST API is versioned under `/api/v1`.
- Human users authenticate through `POST /api/v1/session` and use bearer tokens.
- Human permissions are scoped through `Membership`, which connects a user to a healthcare unit and role. A user can be a pharmacist in one unit and a nurse in another.
- Service callers authenticate with hashed service account bearer tokens.
- Domain persistence is modeled with `HealthcareUnit`, `Medication`, `Membership`, `Order`, `OrderLine`, and `AuditLog`.
- Order lifecycle transition logic lives in `Orders::Advance`.
- Delivery inventory updates run inside a database transaction and use row locks for the order and affected medications.
- Audit logging records critical create/update/delete and order transition events. Audit list filtering supports action, actor, record type, healthcare unit, and date range.

## Frontend

- React + TypeScript provides the clinical dashboard.
- The current state layer uses local component state and explicit refreshes after mutations. This keeps the assignment small and predictable.
- The UI has loading and error states plus a top-level error boundary.
- Nurses see ordering and low-stock workflows. Medication registry management actions are shown only to pharmacist/admin roles, and admin-only delete/audit actions are hidden from other roles.

## Search

Medication search currently uses PostgreSQL `ILIKE` queries over name, ATC code, and form. Medication registry, low-stock, and order history responses are paginated. Elasticsearch is not included because the sample dataset is small and introducing another required service would add operational cost without improving this assignment's behavior. The medication search logic is isolated enough to replace with an Elasticsearch-backed service when volume or ranking requirements justify it.

## Deployment

GitHub Actions runs CI, builds production Docker images, pushes to GitHub Container Registry, and deploys to a Docker host over SSH using `docker-compose.prod.yml` and `scripts/deploy.sh`.
