# Roadmap

## Milestone 0: Foundation

- [x] Public repository created.
- [x] Freeze v1.1.1 as specification baseline.
- [x] Define logical architecture.
- [x] Define canonical relational objects.
- [x] Encode first-pass epistemic rules.
- [x] Define migration invariants.
- [ ] Review and freeze physical database schema.

## Milestone 1: Database Core

- [ ] Choose implementation database.
- [ ] Create migrations.
- [ ] Create enums/lookup tables.
- [ ] Add constraints and foreign keys.
- [ ] Add generated ESI/STI/RPS values.
- [ ] Implement append-only audit logging.
- [ ] Add deterministic integrity tests.

## Milestone 2: Ledger Migration

- [ ] Import eight theories.
- [ ] Import 27 claims.
- [ ] Import SRC-001 through SRC-078.
- [ ] Import seven populated state/population deep dives.
- [ ] Import claim-evidence relationships.
- [ ] Reconcile every migration difference against v1.1.1.

## Milestone 3: Rules Engine

- [ ] Implement R-001 through R-014 as executable validations.
- [ ] Implement target-relevance promotion gates.
- [ ] Implement CMC causal gate.
- [ ] Implement asymmetric negative-evidence gate.
- [ ] Implement developmental translation penalty.
- [ ] Implement phylogenetic translation penalty.
- [ ] Implement ex vivo EV/OEC firewall.

## Milestone 4: Candidate Ingestion

- [ ] Paper metadata ingestion.
- [ ] Structured extraction schema.
- [ ] Candidate evidence quarantine.
- [ ] Independent provisional scoring.
- [ ] Adversarial review.
- [ ] Disagreement preservation.
- [ ] Approval/rejection workflow.

## Milestone 5: Analytical Interface

- [ ] Claim detail view.
- [ ] Theory comparison view.
- [ ] Population matrix.
- [ ] Evidence provenance view.
- [ ] Score history/audit view.
- [ ] Contradiction and retreat log.
- [ ] Research-gap finder.

## Milestone 6: Prospective Validation

Artificial and synthetic systems become the first new domain processed entirely through the engine rather than manually appended to the Word specification.

Success criterion: the engine must reproduce or improve the methodological discipline of the manual ledger without introducing hidden score promotions or taxonomy drift.
