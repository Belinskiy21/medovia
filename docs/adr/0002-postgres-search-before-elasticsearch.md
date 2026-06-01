# ADR 0002: Use PostgreSQL Search Before Elasticsearch

## Status

Accepted

## Context

The target architecture proposes Elasticsearch for medication indexing and fast filtering. The current product needs exact and partial filtering by medication name, ATC code, and form.

## Decision

Use PostgreSQL search for the current scope. Do not add Elasticsearch until search volume, fuzzy ranking, semantic matching, or cross-entity indexing requires it.

## Consequences

- Local development and CI stay lighter.
- The search feature remains reliable and easy to operate.
- Elasticsearch can be introduced behind a dedicated medication search service later without changing the public API.
