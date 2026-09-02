# Consciousness Evidence Engine Master Build Plan

**Status:** CANONICAL BUILD GOVERNANCE DOCUMENT  
**Authority:** Governs the remaining build unless superseded by an explicitly reviewed and approved revision.  
**Baseline:** Consciousness Evidence Map: Claim Ledger v1.1.1  
**Repository:** `amy2213/consciousness-evidence-engine`

## Governing principle

Nothing becomes authoritative merely because it was extracted, scored, generated, calculated, or successfully inserted into the database. It becomes authoritative only after provenance, schema validation, epistemic-rule validation, adversarial review, and an explicit approval event all succeed.

The required progression for authoritative scientific state is:

`Source gate -> Structural gate -> Epistemic gate -> Adversarial gate -> Human approval gate -> Release gate`

Failure at any gate returns the item to candidate, unresolved, rejected, or superseded status. AI may assist with source processing, extraction, classification, scoring proposals, contradiction detection, rule evaluation, and adversarial review. AI may not issue authoritative human approval.

The system must always preserve three things:

1. what the project originally believed;
2. what evidence changed that state;
3. who authorized the change.

## Change control

This document is the canonical top-to-bottom build sequence. `docs/roadmap.md` and issue-level plans are implementation views subordinate to this plan.

Changes to this plan require:

1. an explicit proposed revision;
2. rationale describing why the current plan is insufficient;
3. assessment of effects on schema, methodology, provenance, testing, releases, and scientific interpretation;
4. review against the frozen v1.1.1 specification and existing architecture decisions;
5. explicit human approval;
6. a versioned Git commit preserving the previous plan.

No implementation shortcut silently changes the governing methodology.

---

## Phase 1: Close the v1.1.1 baseline migration completely

Finish normalization before importing new populations. Populate `bibliographic_works` and `source_works`, including the two-work `SRC066` case and umbrella `SRC067` case. Verify every `SRC001-SRC078` container resolves correctly, underlying publications are traceable, identifiers belong to the correct work, and intentionally partial sources remain explicitly partial.

**Required checks:** source-container membership, duplicate works, orphan works, impossible identifier reuse, closure status, exact 78-source baseline reconciliation, and execution of source-model invariants in CI.

## Phase 2: Finish semantic cleanup of migrated evidence

Review DoC/CMD asymmetry semantics, especially `DC007` and `DC008`. Distinguish evidence that is itself an asymmetric active test from evidence that establishes a methodological rule about asymmetric inference. Review `AN006` and distinguish intervention on a biological mechanism from intervention on a consciousness-sensitive dependent variable. Reassess conservative split-brain unity mappings without permitting phenomenal-subject promotion absent explicit bridge evidence.

**Required checks:** schema semantics must represent distinct concepts distinctly; no Boolean may carry two scientific meanings; reconciliation tests updated alongside any semantic correction.

## Phase 3: Harden approval architecture

Replace the weak same-identity AI approval restriction with the intended authority model: AI cannot issue authoritative approval. Separate proposals from decisions, make proposals immutable after submission, make approval history append-only, and require reviewer identity, actor type, rationale, timestamp, and exact version/evidence scope.

Human approval is required for authoritative score changes, evidence promotions, source closure, claim revisions, and release certification. Reviewer-independence constraints apply where appropriate.

**Required checks:** adversarial attempts at AI approval, self-approval, proposal mutation, historical decision rewriting, and approval without provenance must fail closed.

## Phase 4: Harden database privileges

Create explicit roles for ingestion, review, approval, application read access, release management, and migration administration. Ordinary application and AI accounts cannot directly mutate authoritative claims, evidence, scores, approvals, or audit history. Candidate ingestion occurs through controlled paths. Append-only history tables deny update/delete to non-administrative roles.

**Required checks:** authorization tests must prove forbidden identities cannot bypass database gates even if application logic is defective.

## Phase 5: Create formal specification and release entities

Add `specification_versions`, `dataset_releases`, release membership, status, manifests, errata, supersession relationships, and hashes. Every authoritative state must be answerable by specification version and released dataset.

Freeze v1.1.1 as the initial specification-derived baseline. Later scientific changes create new versions/releases rather than silently mutating history.

**Required checks:** released history immutable; manifest reproducibility; release membership exact; supersession explicit.

## Phase 6: Version theories and claims properly

Separate theory family from theory version using `theory_versions`. Separate stable claim identity from claim wording/version using `claim_versions`. Preserve claim history, falsifiers, operationalizations, target relevance, and theory-version linkage.

**Required checks:** historical releases retain exact historical wording and theory relationships; no overwrite destroys an earlier scientific state.

## Phase 7: Replace mutable score state with score history

Use immutable score observations, events, or snapshots tied to claim version, evidence state, specification version, evaluator, rationale, and approval. Compute ESI, STI, and RPS from approved dimensions rather than treating a mutable row as history.

**Required checks:** current scores reconstruct exactly from history; unauthorized score mutation fails; every score change has approved provenance.

## Phase 8: Complete the canonical relational model

Reach the intended core model:

`THEORIES`, `THEORY_VERSIONS`, `CLAIMS`, `CLAIM_VERSIONS`, `SOURCES`, `BIBLIOGRAPHIC_WORKS`, `SOURCE_WORKS`, `EVIDENCE`, `CLAIM_EVIDENCE`, `EVALUATION_CONTEXTS`, `MEASUREMENTS`, `RULES`, `CANDIDATE_RECORDS`, `REVIEW_EVENTS`, `APPROVAL_EVENTS`, `PROVENANCE_EVENTS`, `SCORE_EVENTS/SNAPSHOTS`, `SPECIFICATION_VERSIONS`, `RELEASES`, `ERRATA`, `MODEL_RUNS`, and `AUDIT_LOG`.

Many-to-many relationships must be explicit. Authoritative state must not rely on slash-delimited taxonomy strings or untyped JSON that substitutes for relational structure.

## Phase 9: Generalize populations into evaluation contexts

Represent human states, nonhuman species, ex vivo systems, artificial systems, simulations, and synthetic constructs through `evaluation_contexts`. Biological population metadata may exist as subtype-specific structure.

**Required checks:** artificial/synthetic contexts can be represented without pretending they are biological populations; existing seven baseline populations migrate without semantic loss.

## Phase 10: Build the measurement layer

Model measurements independently from interpretations. Capture measurement type, operational target, acquisition modality, timing, task/report dependence, state sensitivity, content sensitivity, validation population, consciousness specificity, confounds, causal status, and replication status.

Explicitly distinguish behavioral responsiveness, immediate report, delayed report, confidence, memory, neural decoding, perturbational complexity, recurrence, broadcast, field patterns, and other operational classes.

**Required rule:** measuring an interesting neural or behavioral variable is not equivalent to measuring consciousness.

## Phase 11: Encode epistemic rules as executable logic

Machine-enforce central prohibitions wherever possible:

- correlation does not become causation;
- causal contribution does not become necessity;
- necessity does not become sufficiency;
- cognitive function does not become phenomenality;
- evidence for a component does not confirm a whole theory;
- implementation of a mechanism in a synthetic system does not establish experience;
- CMC4 requires its hard causal/convergence conditions;
- retroactive negative-active-test evidence receives the required cap;
- ex vivo organization scores cannot automatically promote consciousness measurement confidence.

Every rule requires an ID, severity, specification basis, executable expression where possible, human-review fallback where needed, fixtures, and exact failure messages.

## Phase 12: Create the rule conformance suite

Every scientific rule gets positive, negative, edge-case, and adversarial fixtures. Tests fail closed. Mutation testing deliberately breaks gates and verifies CI catches the corruption. Add schema-upgrade, migration-replay, seed-behavior, immutability, rollback, and recovery tests.

**Acceptance principle:** green CI must mean more than successful SQL execution.

## Phase 13: Create end-to-end provenance

Every authoritative datum must trace backward through:

`release -> approved interpretation -> evidence -> source container -> bibliographic work -> exact locator`.

AI-assisted work additionally records model identity/version where available, extraction protocol, timestamp, candidate hash, parent-source hash, and review history. Human corrections create new provenance events rather than erasing candidate history.

## Phase 14: Build the candidate-ingestion pipeline

Canonical flow:

`source -> candidate extraction -> structural validation -> provenance validation -> duplicate detection -> evidence candidate -> scoring candidate -> epistemic-rule evaluation -> adversarial review -> human approval -> authoritative commit`.

AI can propose. AI cannot directly mutate authoritative scientific state.

## Phase 15: Add reproducible model-run tracking

Record model-assisted extraction, classification, scoring, contradiction scans, and synthesis in `model_runs`, including model/configuration where available, task type, specification version, input references, output hashes, date, and disposition.

**Required check:** an authoritative record affected by AI must be traceable to the model-assisted event and subsequent human disposition.

## Phase 16: Finish migrating remaining frozen v1.1.1 populations

After core-model stabilization, migrate development/infants, nonhuman animals, and ex vivo/organoid data. Each receives source-locked seed data, evidence records, claim links, reconciliation tests, domain-specific invariants, and adversarial fixtures.

**Required rule:** no score promotion occurs merely because more rows were imported.

## Phase 17: Perform complete v1.1.1 database-to-document reconciliation

Programmatically compare database state with the frozen ledger for all 27 claims, exact claim text, claim types, roles, target relevance, PS/ED/CI/IR/RD/RR, ESI/STI/RPS, CMC/OF, SRC001-SRC078, Section 4 citations, Section 5.1 source associations, evidence IDs, context mappings, source locators, and operationalized conclusions.

Produce both machine-readable and human-readable reconciliation certificates.

**Release blocker:** zero unexplained mismatches.

## Phase 18: Declare the database authoritative only after reconciliation certification

Until certification, the DOCX remains the frozen specification baseline. After certification:

- DOCX = human-readable scientific specification;
- database = canonical structured representation;
- rules engine = executable methodology;
- release manifest = exact mapping between specification and structured state.

## Phase 19: Build the analysis/query layer

Create tested views/APIs for claim scorecards, evidence by theory/context, support versus pressure, unresolved evidence, provenance completeness, source closure, CMC/OEC distributions, theory-role comparisons, phenomenal-bridge evidence, causal-chain completeness, score history, reviewer disagreement, and evidence gaps.

Derived results must come from canonical relations rather than manually maintained summary tables.

## Phase 20: Build the Consciousness Evidence Engine API

Expose read operations broadly and writes only through controlled workflows. Authoritative mutations must pass the same database gates used in CI. Candidate/proposal operations can be AI-assisted; approval operations require authorized humans.

Add request validation, version negotiation, audit logging, pagination, deterministic error codes, and API documentation.

## Phase 21: Build the public dashboard

The primary analytical unit remains the claim, not the theory. Claim pages display versioned text, classification, role, scores, CMC/OF, supporting evidence, pressuring evidence, unresolved evidence, falsifier, operational test, provenance, score history, rival relevance, and remaining gaps.

Theory pages aggregate claims rather than concealing claim-level disagreement behind a single theory score.

## Phase 22: Build evidence-map visualizations

Represent the functional stack:

`SUB -> GEN -> INT -> ACC -> META -> report/control`

with `BND` cutting across and `PHEN` unresolved.

Add theory/claim coverage, evidence density, causal strength, measurement confidence, context convergence, phenomenal-bridge status, source closure, and evidence-versus-operational-feasibility views.

All visualization calculations must be reproducible from canonical data.

## Phase 23: Make artificial systems the first new engine-native domain

After frozen migration is complete, investigate artificial systems entirely through the engine. Define system classes, synthetic null systems, recurrence, broadcast, predictive inference, higher-order monitoring, attention schema, causal integration, embodiment, memory, closed-loop control, and subject-boundary tests.

Key question: if mechanisms associated with leading consciousness theories can be engineered into systems without justified evidence of phenomenality, which claims remain genuinely consciousness-specific?

## Phase 24: Implement the experiment registry

Encode E1-E6 and later experiments with preregistered hypotheses, target claims, rival predictions, required measurements, falsification criteria, analysis plans, result status, and score consequences.

Prospective predictions receive explicit distinction from post-hoc compatibility.

## Phase 25: Build rival-discrimination analysis

For every experiment/evidence item, record which rival claims predicted the result, whether predictions were distinct, whether parameters were fitted after the result, and whether evidence genuinely discriminates among claims.

Generic compatibility is not theory confirmation.

## Phase 26: Implement theory-retreat tracking

Structure the contradiction/retreat log around protected core claim, original prediction, outcome, revision, core/auxiliary/abandoned classification, preregistration status, and effect on falsifiability.

This operationalizes revision resistance rather than leaving RR as an unexplained number.

## Phase 27: Add contradiction and consistency detection

Detect conflicting operational criteria, evidence simultaneously treated as support and pressure without explanation, cross-claim source interpretation conflicts, role inconsistencies, unsupported score changes, and theory revisions that alter falsifiers.

AI may flag contradictions. Humans adjudicate them.

## Phase 28: Create a formal uncertainty model without probability-of-truth claims

RPS remains a research-priority/evidence-strength index, not the probability that a theory is true. Track uncertainty separately for source closure, extraction, interpretation, measurement relevance, causal inference, and rival discrimination.

Do not compress fundamentally different epistemic uncertainties into a single pseudo-probability.

## Phase 29: Implement release certification gates

A release cannot publish unless migrations pass, populated-upgrade paths pass, reconciliations pass, authoritative evidence has approval provenance, orphan checks pass, blocking rule violations are absent, score history reconstructs current scores, source closure rules pass, manifests/hashes reproduce, and the adversarial suite passes.

Generate certification automatically.

## Phase 30: Create rollback, errata, and supersession procedures

Never rewrite released historical scientific state. Corrections create errata or superseding records, preserve the original, record rationale and authority, and appear in a new release.

**Required check:** every historical release remains reproducible after later corrections.

## Phase 31: Add security and integrity hardening

Implement dependency scanning, SQL-injection testing, API authorization testing, secret scanning, protected branches, required CI, review rules, CODEOWNERS for sensitive paths, secure release workflow, and appropriate verification/signing practices.

Public methodology and data belong in the repository. Secrets and production credentials do not.

## Phase 32: Create repository governance

Add contribution rules, source standards, claim-change standards, reviewer expectations, conflict-of-interest disclosure expectations, issue templates, PR templates requiring evidence/test impact, code of conduct, security policy, citation metadata, licensing decisions, and scientific governance documentation.

## Phase 33: Generate documentation from canonical state wherever possible

Generate controlled vocabularies, rule tables, claim scorecards, source registries, and release statistics from canonical structured data. Humans write scientific interpretation and rationale; machines regenerate tables whose purpose is to reflect authoritative state.

This is a direct defense against the document drift that motivated the engine.

## Phase 34: Build export formats

Support CSV, JSON, SQL/database dump where appropriate, machine-readable release manifests, and human-readable reports. Add graph-oriented formats later if scientifically useful.

Every export carries specification version, dataset release ID, generation timestamp, schema version, hashes, and provenance notes.

## Phase 35: Add reproducibility tooling

A researcher must be able to clone the repository, start the database, run migrations/seeds, execute tests, reproduce a named release, run core analyses, and recover the same claim scorecards/evidence mappings.

Target: one documented command to build/verify the environment and one command to verify a release.

## Phase 36: Perform hostile software QA before engine v1.0

Attempt to inject invalid score changes, bypass approvals, misclassify AI as human, promote correlation to necessity, create orphan evidence, alter released history, collapse source clusters incorrectly, fake CMC4, infer phenomenality from functional evidence, mutate score history without provenance, and break upgrade paths.

Every successful attack becomes a permanent regression test.

## Phase 37: Run a scientific red-team independently of the software red-team

Challenge whether the model itself embeds unjustified philosophical assumptions. Review claim taxonomy, functional stack, CMC/OEC, measurement classifications, theory roles, target relevance, subject-boundary ontology, phenomenal-bridge logic, and evidence weighting.

Software correctness does not guarantee epistemic correctness.

## Phase 38: Release the first certified baseline

Once v1.1.1 is fully represented, reconciled, provenance-complete, migration-safe, adversarially tested, and release-certified, publish the engine's first canonical data release. Bind together Git tag/commit, schema version, specification version, dataset release, reconciliation certificate, source manifest, and hash manifest.

## Phase 39: Begin engine-native scientific expansion

After certified baseline release, new literature enters through the candidate pipeline rather than manual Word edits. Artificial systems come first, followed by future anesthesia, sleep, DoC, development, animal, and ex vivo updates as warranted.

Each study becomes atomic evidence linked to claims and rivals, not an unstructured paragraph appended to a theory narrative.

## Phase 40: Move toward formal publication

The eventual publication should present a reproducible framework for maintaining a living, source-locked, claim-level evidence map in which theory evaluation is versioned, auditable, falsifiable, adversarially tested, and resistant to post-hoc theoretical retreat.

Publication scope should include methodology, architecture, frozen baseline, convergence results, unresolved gaps, and a publicly reproducible engine.

---

## Permanent checks and balances

These controls apply across every phase:

- **Source lock:** no authoritative claim without traceable source/work/locator provenance.
- **Atomic evidence:** evidence findings remain separable from interpretation and theory narrative.
- **Candidate quarantine:** extraction and proposals remain non-authoritative until approved.
- **No AI authority:** AI cannot issue authoritative scientific approval.
- **Human accountability:** authoritative changes identify approving humans and rationale.
- **Append-only history:** prior released states, proposals, decisions, provenance, and audit events remain preserved.
- **Version discipline:** claims, theories, specifications, scores, and releases evolve through explicit versions or events.
- **Fail-closed testing:** tests must require the intended success or intended rejection, not merely any exception.
- **Upgrade-path testing:** populated databases are tested, not only empty installations.
- **Epistemic firewalls:** correlation, causation, necessity, sufficiency, cognition, consciousness, and phenomenality remain distinct evidentiary levels.
- **Rival discrimination:** compatibility is not confirmation.
- **No silent score promotion:** score changes require evidence, rationale, provenance, and approval.
- **Measurement discipline:** operational measures do not inherit consciousness specificity without validation.
- **Phenomenal bridge protection:** functional success does not automatically establish subjective experience.
- **Release certification:** no release is authoritative until all blocking gates pass.
- **Reproducibility:** released state must be independently reconstructable from repository artifacts.
- **Errata over erasure:** mistakes are corrected by supersession, never historical rewriting.
- **Software and scientific red teams remain separate:** both must pass.

## Definition of done

The build is complete when the repository can independently reproduce a certified consciousness-evidence dataset from source-locked inputs; preserve every authoritative scientific transition; enforce the methodology's epistemic rules; distinguish candidate, reviewed, approved, superseded, and released states; expose claim-level evidence and uncertainty transparently; survive populated upgrades and hostile tests; and support new scientific domains without returning to manually maintained document state.
