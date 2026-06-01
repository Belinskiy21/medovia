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
- Role-based API checks using bearer-authenticated users and service accounts.
- Audit log for critical mutations.
- CSV export for order history.

## Run Locally

No `.env` file is required for local development. Docker Compose, Rails, and Vite all have development defaults:

- PostgreSQL runs from `docker-compose.yml`.
- Rails seeds demo users, sample healthcare units, medications, orders, and a service account.
- The frontend uses `http://localhost:3001/api/v1` unless `VITE_API_BASE_URL` is set.
- The service account token defaults to `svc_meditrack_inventory_demo_token` unless `MEDITRACK_SERVICE_TOKEN` is set.

Normal development flow:

```bash
make setup
make dev
```

For a clean rebuild:

```bash
make dev-build
```

Then open:

- Frontend: http://localhost:5173
- Backend health check: http://localhost:3001/up

The backend seeds two healthcare units, sample medication/order data, and demo users when the container starts.

Useful commands:

```bash
make help
make dev
make setup
make prod-build
make test
make logs
make stop
```

## Deployment

The repository includes root-level GitHub Actions workflows:

- `.github/workflows/ci.yml` runs Rails tests, the React production build, and production Docker image builds.
- `.github/workflows/deploy.yml` builds/pushes backend and frontend images to GitHub Container Registry, uploads deployment files to a server over SSH, and runs `scripts/deploy.sh`.

Required GitHub repository secrets for deployment:

- `DEPLOY_HOST`: server hostname or IP
- `DEPLOY_USER`: SSH user with Docker access
- `DEPLOY_SSH_KEY`: private key for the deploy user
- `DEPLOY_PATH`: target directory on the server, for example `/opt/meditrack`

Recommended GitHub variable:

- `VITE_API_BASE_URL`: public backend API URL used when building the frontend, for example `https://api.example.com/api/v1`

On the server, create an `.env` file in `DEPLOY_PATH` using `.env.production.example` as a template. At minimum set strong values for `POSTGRES_PASSWORD`, `SECRET_KEY_BASE`, `FRONTEND_ORIGIN`, and public ports. The production runtime uses `docker-compose.prod.yml`.

Architecture notes and requirement tradeoffs are documented in `docs/architecture.md`, `docs/requirements-review.md`, and the ADRs under `docs/adr/`.

## Authentication

The frontend signs in through `POST /api/v1/session` and sends the returned token on API requests:

```http
Authorization: Bearer <token>
```

Human user tokens are Rails-signed tokens with a 12 hour lifetime. Human roles are assigned through healthcare-unit memberships, so the same user can have different roles in different units. Audit logs use the authenticated user email and the role for the affected healthcare unit.

Seeded demo credentials:

| User | Email | Password | Seeded memberships |
| --- | --- | --- | --- |
| Nurse | `nurse@medovia.test` | `NursePass123!` | Nurse in both seeded units |
| Pharmacist | `pharmacist@medovia.test` | `PharmacistPass123!` | Pharmacist in Karolinska Cardiology, nurse in Sahlgrenska Emergency |
| Admin | `admin@medovia.test` | `AdminPass123!` | Admin in both seeded units |

The demo users are persisted with secure password digests. Their roles live in `memberships`, not directly on `users`.

Service-to-service callers use the same bearer header with a service token. The seeded development service account is:

| Service | Identifier | Role | Token |
| --- | --- | --- | --- |
| Inventory Sync Service | `inventory-sync@services.medovia.test` | `pharmacist` | `svc_meditrack_inventory_demo_token` |

Override this seeded token with `MEDITRACK_SERVICE_TOKEN` when seeding non-local environments. Service account tokens are stored as bcrypt digests. CORS still limits browser origins, but API security is enforced by bearer authentication rather than CORS.

Example service request:

```bash
curl -H "Authorization: Bearer svc_meditrack_inventory_demo_token" \
  http://localhost:3001/api/v1/healthcare_units/1/medications
```

## Testing API Calls With Curl

For quick local API checks, use the seeded service account token:

```bash
curl -H "Authorization: Bearer svc_meditrack_inventory_demo_token" \
  http://localhost:3001/api/v1/healthcare_units/1/medications
```

To test as a human user, first request a session token:

```bash
curl -X POST http://localhost:3001/api/v1/session \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@medovia.test","password":"AdminPass123!"}'
```

Then pass the returned `token` value on later requests:

```bash
curl -H "Authorization: Bearer <token>" \
  http://localhost:3001/api/v1/healthcare_units
```

## Tests

Run backend tests:

```bash
docker compose exec backend bin/rails test
```

The included integration test covers medication search/low-stock output and the full order delivery flow with inventory update.

## Known Limitations

- Authentication is implemented with demo users and service bearer tokens, but production would still need token rotation, revocation, and rate limiting.
- The AI categorization feature is deterministic rule-based categorization from ATC/name, not an external model call.
- Inventory is incremented on delivery but does not yet model reservations, supplier partial deliveries, batch numbers, expiry dates, or controlled-substance handling.
- The UI optimistically keeps workflows simple and refreshes server state after each mutation instead of using a dedicated server-state library.

## Improvements With More Time

- Add finer-grained permissions, token revocation, and service token rotation workflows.
- Add supplier entities, partial deliveries, batches, expiry dates, and stock adjustment reasons.
- Add notification delivery for low inventory and order status changes.
- Add more tests around authorization, validation failures, audit logging, and CSV export.
- Add OpenAPI documentation and CI checks.
