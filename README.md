# MediTrack

MediTrack is a fullstack internal tool for healthcare units to manage medication inventory and ordering. It replaces manual list and email workflows with a searchable registry, explicit order status flow, automatic inventory updates on delivery, and visible low-stock warnings.

## Architecture

- Backend: Ruby on Rails API with PostgreSQL. Rails fits the assignment because it gives fast, explicit domain modeling, validations, migrations, integration tests, and RESTful controllers with little ceremony.
- Frontend: React with TypeScript and Vite. The UI is a compact operational dashboard for nurses and pharmacists, with local component state because the app is small and server state is refreshed after each mutation.
- Deployment/local runtime: one repository managed by Docker Compose, with separate `backend`, `frontend`, and `db` services.

Core entities are `HealthcareUnit`, `Medication`, `Order`, and `OrderLine`. `Order` supports the required flow: `draft -> sent -> confirmed -> delivered`. When an order reaches `delivered`, each order line increments the medication inventory balance in a database transaction.

## Implemented Features

- Medication registry with name, ATC code, form, strength, inventory balance, minimum threshold, and AI-style category suggestion.
- Add, edit, delete, search, and filter medications.
- Orders with one or more medications and quantities.
- Order history per healthcare unit.
- Automatic inventory update on delivery.
- Low inventory warnings.
- Role-based API checks using request headers for `nurse`, `pharmacist`, and `admin`.
- Audit log for critical mutations.
- CSV export for order history.

## Run Locally

```bash
make dev-build
```

Then open:

- Frontend: http://localhost:5173
- Backend health check: http://localhost:3001/up

The backend seeds two healthcare units and sample medication/order data when the container starts.

Useful commands:

```bash
make help
make dev
make prod-build
make test
make logs
make stop
```

## API Role Headers

The frontend exposes a role selector. The backend reads:

- `X-User-Role`: `nurse`, `pharmacist`, or `admin`
- `X-User-Email`: actor shown in audit logs and orders

This is intentionally lightweight for the assignment. A production version would use real authentication, signed tokens, and persistent users.

## Tests

Run backend tests:

```bash
docker compose exec backend bin/rails test
```

The included integration test covers medication search/low-stock output and the full order delivery flow with inventory update.

## Known Limitations

- Authentication is simulated through headers rather than a login flow.
- The AI categorization feature is deterministic rule-based categorization from ATC/name, not an external model call.
- Inventory is incremented on delivery but does not yet model reservations, supplier partial deliveries, batch numbers, expiry dates, or controlled-substance handling.
- The UI optimistically keeps workflows simple and refreshes server state after each mutation instead of using a dedicated server-state library.

## Improvements With More Time

- Add real authentication and finer-grained permissions.
- Add supplier entities, partial deliveries, batches, expiry dates, and stock adjustment reasons.
- Add notification delivery for low inventory and order status changes.
- Add more tests around authorization, validation failures, audit logging, and CSV export.
- Add OpenAPI documentation and CI checks.
