# Database Test Protocol

## Test classes

### `invariants.sql`
Read-only reconciliation queries. A healthy database returns zero rows for every violation query.

### `adversarial.sql`
Intentional corruption attempts. Each forbidden operation must raise and be caught as an expected database exception.

## Required execution order

1. Create disposable PostgreSQL 16+ database.
2. Apply `db/schema.sql`.
3. Apply migrations in numeric order.
4. Load controlled vocabularies.
5. Load minimal test fixtures for required theory, claim, and source foreign keys.
6. Run `invariants.sql`.
7. Run `adversarial.sql`.
8. Fail CI if any invariant returns a row or any adversarial corruption succeeds.

## Minimum hostile cases

- CMC 4 without causal manipulation.
- CMC 4 without consciousness-sensitive convergence.
- CMC 4 without preregistration or independent replication.
- approved evidence without approval event.
- score change hidden in legacy JSON.
- audit history update/delete.
- direct component-score mutation without approved proposal.
- qualitative text in CMC/OEC.
- orphan source/evidence/claim references.
- invalid Theory Role.

## Migration rule

No v1.1.1 canonical data migration begins until this suite is executable in CI and all hostile fixtures are rejected.
