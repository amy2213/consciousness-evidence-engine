# Database Decisions v0.1

## Decision 001: PostgreSQL is the canonical database

**Status:** proposed for foundation freeze.

### Why

The engine requires:
- foreign-key integrity;
- generated score columns;
- strong check constraints;
- enum/controlled-value enforcement;
- JSONB for provenance and proposed changes;
- triggers for release gates;
- append-only audit behavior;
- mature migration and analytical tooling.

SQLite remains suitable for disposable local demos but is not the canonical research store.

## Decision 002: Multi-valued Theory Roles are normalized

Theory Role is not stored as a free-text string such as `GEN/PHEN`. It is represented through `claim_theory_roles`, one controlled role per row. Display layers may render the ordered set as `GEN/PHEN`, but population matrices cannot redefine it.

## Decision 003: CMC/OEC semantic scores are typed categorical values

The physical schema stores `0`, `1`, `2`, `3`, `4`, `ND`, or `NA` as a controlled database type. This preserves the critical difference between zero evidence, not determined, and not applicable.

These values must not be blindly averaged. Any future aggregation function requires an explicit methodology and versioned rule.

## Decision 004: CMC 4 receives a database hard gate

An evidence row cannot be stored with CMC 4 unless `causal_manipulation = true`.

This database constraint is necessary but not sufficient. The full methodological requirement also includes convergent consciousness-sensitive measurement and preregistration or independent replication; those will be enforced in the application/rules layer once the necessary structured fields are finalized.

## Decision 005: Derived scores are generated

ESI, STI, and RPS are generated from component values. They cannot drift independently from ED/CI/IR/RD/PS/RR.

## Decision 006: Candidate evidence is quarantined

Candidate/model extraction lives in `candidate_records` and `review_events`. It does not become an `evidence` row merely because extraction succeeded.

## Decision 007: Audit history is append-only

`audit_log` rejects UPDATE and DELETE operations. Corrections are represented by later audit events, not historical rewriting.

## Open decisions before schema freeze

1. Whether `target_match` should remain boolean or become a richer controlled classification.
2. Whether score changes should be normalized into a separate table rather than JSONB.
3. Whether bibliographic authors should remain display text or receive normalized person/authorship tables.
4. Exact provenance JSON schema.
5. Exact mechanism for preventing direct application-user writes to canonical tables outside an approval transaction.
