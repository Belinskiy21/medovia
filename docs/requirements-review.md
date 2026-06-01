# Requirements Review

## Matches

- Rails API with REST endpoints and `/api/v1` versioning.
- PostgreSQL as the primary relational database.
- Order lifecycle: `draft -> sent -> confirmed -> delivered`.
- Audit logging for traceability.
- React + TypeScript frontend with responsive clinical dashboard.
- Search by medication name, ATC code, and pharmaceutical form.
- Threshold-based stock monitoring.
- Transactional, row-lock based inventory updates after delivery.
- Production Docker images, Compose runtime, and GitHub Actions deployment.

## Partially Matches

- Modular monorepo: separated as `backend/`, `frontend/`, `scripts/`, Compose files, and `docs/`, but not physically under `/apps` and `/infra`.
- Service objects: order advancement and medication categorization are service objects; more flows can be extracted as complexity grows.
- Background jobs: Rails job infrastructure exists, but there is no real asynchronous workflow yet.
- Immutable order history: no public API can edit orders; order lines also reject updates after the order leaves draft.
- Error resilience: explicit loading/error states and a top-level error boundary exist.

## Intentionally Deferred

- Elasticsearch: deferred until dataset size or search semantics justify the operational cost.
- React Query/Zustand/Redux Toolkit: deferred because current state needs are small and explicit refreshes are easier to evaluate for this assignment.
- Full `/apps`, `/services`, `/infra` restructure: deferred until additional independently deployed services exist.
