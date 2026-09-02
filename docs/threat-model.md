# Threat Model v0.1

The engine is designed against both ordinary software corruption and research-specific epistemic corruption.

## Protected assets

1. Canonical claim definitions.
2. Canonical Theory Roles and Target Relevance.
3. Source provenance.
4. Evidence interpretation.
5. CMC/OEC semantics.
6. PS/ED/CI/IR/RD/RR component scores.
7. Historical audit trail.
8. Reviewer disagreement.

## Threat classes

### T-01 Taxonomic drift
A population-specific table silently renames or mutates a canonical claim role.

**Control:** roles normalized in `claim_theory_roles`; display views reference canonical records.

### T-02 Score drift
A total changes independently from component scores or a component changes without provenance.

**Control:** generated ESI/STI/RPS; component mutation gate; typed score-change proposals; audit events.

### T-03 AI authority escalation
An extraction/scoring model writes its own interpretation into canonical evidence or approves its own score.

**Control:** candidate quarantine; explicit actor types; approval events; self-approval prohibition.

### T-04 Phenomenality laundering
Evidence for cognition, organization, complexity, recurrence, prediction, or report is silently treated as evidence for subjective experience.

**Control:** Target Relevance; claim types; R-004/R-009/R-010; CMC/OEC separation; claim-evidence review.

### T-05 Negative-evidence overclaim
Failure on an active task becomes evidence of absent consciousness.

**Control:** asymmetric negative-evidence rule; future structured false-negative fields; absence-directed CMC cap.

### T-06 Source laundering
A theory-level citation is used to support an exact empirical claim it does not test.

**Control:** evidence requires registered source; claim-evidence links explicit; source closure tracked.

### T-07 Historical rewriting
A correction overwrites an earlier decision, hiding why a score changed.

**Control:** append-only audit log and event-based approvals.

### T-08 Semantic null collapse
`0`, `ND`, `NA`, and SQL NULL are treated as equivalent.

**Control:** typed semantic score enum and documented null semantics.

### T-09 CMC inflation
Prestige, sample size, multicenter design, or multimodal observation is used to award CMC 4 without causal manipulation and consciousness-sensitive convergence.

**Control:** full CMC-4 database gate.

### T-10 Circular sufficiency confirmation
A theory-defined mechanism is detected, consciousness is inferred from that same mechanism, and the inference is then used to confirm the theory.

**Control:** independent consciousness-measurement requirement; synthetic-null and ex vivo firewalls; adversarial review.

## Security philosophy

A database constraint should enforce every rule that can be determined from structured fields alone. Rules requiring scientific interpretation remain in the versioned rules engine and review workflow. The system must never disguise a judgment call as deterministic merely to automate it.
