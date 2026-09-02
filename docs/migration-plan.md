# v1.1.1 Migration Plan

## Objective

Migrate the frozen ledger into structured seed data without changing its substantive scores, verdicts, or source interpretations.

## Migration order

1. Controlled vocabularies
2. Theories
3. Populations
4. Claims
5. Sources SRC-001 through SRC-078
6. Evidence units from each deep dive
7. Claim-evidence relationships
8. Measurement metadata
9. Rules and release controls
10. Audit baseline

## Required reconciliation reports

Every migration run must produce:

- orphan source IDs;
- duplicate source IDs;
- orphan claim IDs;
- duplicate claim IDs;
- Theory Role mismatches;
- invalid claim types;
- invalid CMC/OEC values;
- ESI/STI/RPS recomputation differences;
- evidence rows lacking provenance;
- claim-evidence links lacking an interpretation;
- source closure-status distribution;
- ND/NA usage report.

## Baseline invariants from v1.1.1

- 27 canonical claims.
- Eight theory families.
- Source registry contiguous from SRC-001 through SRC-078.
- No canonical Theory Role drift.
- CMC/OEC values restricted to 0-4, ND, NA.
- HOT-3 canonical Theory Role is META/GEN.
- IIT-3 canonical Theory Role is GEN/PHEN.
- RPT-3 canonical Theory Role is GEN/PHEN.
- PP-2 canonical Theory Role is GEN.
- Legacy PS/ED/CI/IR/RD/RR values are frozen during migration.

## Migration philosophy

A migration discrepancy is not permission to silently repair the scientific record. Differences must be surfaced as reconciliation items. Corrections to the frozen specification require a documented erratum and audit event.
