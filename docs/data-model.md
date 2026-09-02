# Canonical Data Model v0.1

This file defines the logical schema. Physical SQL migrations will implement it after review.

## theories

- `theory_id` PK
- `name`
- `version_label`
- `description`
- `status` enum: ACTIVE, HISTORICAL, DEPRECATED

## claims

- `claim_id` PK, stable ledger ID such as `GNW-1`
- `theory_id` FK
- `claim_type` enum: M, N, S, C, B, P
- `theory_role` controlled set or combination of SUB, GEN, INT, ACC, META, BND, PHEN
- `target_relevance` FK/control value
- `claim_text`
- `logical_falsifier`
- `operational_test`
- `operational_feasibility` integer 0-4
- `ps`, `ed`, `ci`, `ir`, `rd`, `rr` integer 0-4
- generated `esi = ed + ci + ir + rd`
- generated `sti = ps + rr`
- generated `rps = esi + sti`
- `status`

## sources

- `source_id` PK, `SRC-###`
- `authors`
- `title`
- `venue`
- `year`
- `doi`
- `pmid`
- `pmcid`
- `source_class`
- `closure_status` enum: CLOSED, PARTIAL, OPEN
- `notes`

## populations

- `population_id` PK
- `name`
- `description`
- `translation_framework`

Initial controlled values:
- ANESTHESIA
- SLEEP
- DOC_CMD
- SPLIT_BRAIN
- DEVELOPMENT
- NONHUMAN_ANIMAL
- EX_VIVO

## evidence

- `evidence_id` PK
- `source_id` FK
- `population_id` FK
- `design_class`
- `intervention`
- `sample_or_system`
- `measured_variable`
- `finding`
- `operational_class`
- `causal_manipulation` boolean
- `preregistered` boolean or ND
- `independent_replication` boolean or ND
- `cmc` typed score: 0-4, ND, NA
- `oec` typed score: 0-4, ND, NA
- `evidence_status`
- `provenance`

## claim_evidence

- composite PK (`claim_id`, `evidence_id`, `evaluation_version`)
- `relationship` enum: SUPPORT, PRESSURE, CONTRADICTION, COMPATIBILITY, NONE, UNRESOLVED
- `target_match`
- `interpretation`
- `score_effect` enum: NONE, SUPPORT, PRESSURE, DOWNGRADE, CLOSURE_REQUIRED
- `proposed_score_change`
- `approved_score_change`
- `review_status`

## candidate_records

Quarantine table for model/human extraction before canonical acceptance.

- `candidate_id` PK
- `source_id` nullable FK
- `raw_payload`
- `extractor_identity`
- `extractor_version`
- `created_at`
- `validation_status`
- `review_status`

## review_events

- `review_event_id` PK
- `candidate_id` FK
- `reviewer_identity`
- `reviewer_role` enum: EXTRACTOR, SCORER, ADVERSARIAL_REVIEWER, APPROVER
- `decision`
- `rationale`
- `structured_scores`
- `created_at`

## rules

- `rule_id` PK
- `name`
- `scope`
- `severity` enum: ERROR, BLOCK, WARNING, INFO
- `expression`
- `rationale`
- `specification_reference`
- `active_from_version`

## audit_log

Append-only.

- `audit_id` PK
- `entity_type`
- `entity_id`
- `action`
- `old_value`
- `new_value`
- `reason`
- `evidence_id` nullable FK
- `rule_id` nullable FK
- `actor`
- `timestamp`

## Invariants

1. Canonical claim role is stored once in `claims`.
2. Every canonical evidence row resolves to one source.
3. Every source ID resolves to one source row.
4. CMC and OEC accept only 0-4, ND, or NA.
5. OEC is never aggregated into CMC.
6. ESI/STI/RPS are derived, never hand-entered totals.
7. Candidate model output cannot directly modify canonical tables.
8. Accepted score changes require an audit event.
