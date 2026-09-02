# Architecture

## 1. Purpose

The Consciousness Evidence Engine converts the frozen v1.1.1 claim ledger into a structured, auditable, machine-enforceable research system.

The document remains the human-readable specification. The database becomes the canonical operational representation.

## 2. Separation of concerns

### Specification layer
The v1.1.1 ledger defines the methodology, claim taxonomy, scoring semantics, translation penalties, measurement cautions, and release controls.

### Data layer
Stores normalized theories, claims, sources, evidence records, claim-evidence relationships, populations, measurements, and audit events.

### Rules layer
Enforces constraints that were previously maintained manually.

### Candidate ingestion layer
Accepts extracted paper data into a quarantine state. Candidate data cannot mutate canonical scores.

### Review layer
Supports independent scoring, adversarial review, disagreement retention, and explicit approval/rejection.

### Analytical layer
Produces claim views, theory comparisons, population matrices, score histories, evidence gaps, contradiction/retreat logs, and research-priority views.

## 3. Canonical relational objects

### theories
One row per theory/version family represented in the engine.

### claims
Atomic evaluated propositions. Canonical Theory Role and Target Relevance live here and are not retyped by population views.

### sources
One authoritative bibliographic record per `SRC-###` identifier.

### evidence
One empirical or methodological evidence unit. CMC belongs here because it characterizes confidence in the consciousness-sensitive measurement of that evidence unit. OEC also belongs here when organizational evidence is applicable.

### claim_evidence
Many-to-many relationship describing what a piece of evidence does to a claim. This is where support, pressure, compatibility, contradiction, null effect, and score consequences are represented.

### populations
Controlled population/system contexts such as anesthesia, sleep, DoC/CMD, split-brain, development, nonhuman animals, and ex vivo systems.

### measurements
Definitions and provenance for scored dimensions and population-specific measurement frameworks.

### rules
Machine-readable validation constraints and human-readable rationale.

### audit_log
Append-only record of accepted changes to canonical data and scores.

## 4. Evidence lifecycle

`INGESTED -> EXTRACTED -> VALIDATED -> SCORED -> ADVERSARIAL_REVIEW -> APPROVED | REJECTED | NEEDS_RESOLUTION`

No state before `APPROVED` is canonical evidence.

## 5. AI boundary

AI systems may:
- extract candidate study metadata;
- propose claim links;
- propose provisional rubric scores;
- identify conflicts and missing fields;
- perform adversarial review.

AI systems may not:
- directly change canonical ESI/STI/RPS values;
- directly approve evidence;
- silently resolve reviewer disagreement;
- create bibliographic facts not present in a source;
- infer phenomenality from organizational complexity.

## 6. Null semantics

- `NA`: not applicable by definition.
- `ND`: applicable but not determined from available evidence.
- Database `NULL`: structurally absent/unentered data only. It must not be used as a synonym for `NA` or `ND`.

## 7. Design target

The system should make invalid epistemic promotions harder to perform than valid ones. If a rule exists only in prose and can be bypassed by typing a different string into a table, it is not yet implemented.
