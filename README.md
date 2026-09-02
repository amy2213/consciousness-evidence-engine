# Consciousness Evidence Engine

A computational research instrument for evaluating consciousness theories claim by claim under explicit evidentiary, measurement, falsifiability, and provenance rules.

## Status

**Phase:** v0.1 foundation  
**Specification baseline:** Consciousness Evidence Map: Claim Ledger v1.1.1  
**Repository role:** canonical operational implementation of the frozen human-readable specification.

## Core principle

The engine must never silently promote:

- correlation to causation;
- causal contribution to necessity;
- necessity to sufficiency;
- cognitive function to subjective experience;
- evidence for one component to confirmation of an entire theory;
- organizational sophistication to consciousness.

## Architecture

The initial canonical objects are:

- `theories`
- `claims`
- `sources`
- `evidence`
- `claim_evidence`
- `populations`
- `measurements`
- `rules`
- `audit_log`

See [`docs/architecture.md`](docs/architecture.md).

## Governance rule

No AI model writes directly to canonical evidence or scores. Model output enters as a candidate record, retains provenance, passes deterministic validation, then adversarial review, and only then may be accepted.

## Near-term milestones

1. Freeze schema and controlled vocabularies.
2. Encode deterministic validation rules.
3. Migrate the v1.1.1 ledger into structured seed data.
4. Build integrity tests.
5. Add candidate-evidence ingestion and review states.
6. Build an analytical API/dashboard.
7. Use artificial systems as the first new domain processed through the computational engine rather than by manual document expansion.

## License and citation

License and citation files will be added before the first public research release. Until then, this repository should be treated as an active pre-release research project.
