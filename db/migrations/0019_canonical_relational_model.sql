-- Phase 8: complete the canonical relational skeleton without pre-empting later semantic phases.
-- Phases 9, 10, and 15 will enrich evaluation contexts, measurements, and model runs respectively.
BEGIN;

CREATE TYPE evaluation_context_class_code AS ENUM (
  'BIOLOGICAL','EX_VIVO','ARTIFICIAL','SIMULATION','SYNTHETIC','OTHER'
);

CREATE TYPE model_run_task_code AS ENUM (
  'EXTRACTION','CLASSIFICATION','SCORING','CONTRADICTION_SCAN','SYNTHESIS','OTHER'
);

CREATE TABLE evaluation_contexts (
    evaluation_context_id TEXT PRIMARY KEY,
    context_class evaluation_context_class_code NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    legacy_population_id TEXT UNIQUE REFERENCES populations(population_id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE evidence_evaluation_contexts (
    evidence_id TEXT NOT NULL REFERENCES evidence(evidence_id) ON DELETE RESTRICT,
    evaluation_context_id TEXT NOT NULL REFERENCES evaluation_contexts(evaluation_context_id) ON DELETE RESTRICT,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    rationale TEXT NOT NULL,
    PRIMARY KEY (evidence_id,evaluation_context_id),
    CHECK (btrim(rationale) <> '')
);
CREATE UNIQUE INDEX uq_evidence_primary_context
ON evidence_evaluation_contexts(evidence_id) WHERE is_primary;

CREATE TABLE measurements (
    measurement_id TEXT PRIMARY KEY,
    measurement_type TEXT NOT NULL,
    label TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (btrim(measurement_type) <> ''),
    CHECK (btrim(label) <> '')
);

CREATE TABLE evidence_measurements (
    evidence_id TEXT NOT NULL REFERENCES evidence(evidence_id) ON DELETE RESTRICT,
    measurement_id TEXT NOT NULL REFERENCES measurements(measurement_id) ON DELETE RESTRICT,
    measured_variable TEXT,
    finding_locator TEXT,
    interpretation_boundary TEXT,
    ordinal SMALLINT NOT NULL DEFAULT 1 CHECK (ordinal > 0),
    PRIMARY KEY (evidence_id,measurement_id),
    UNIQUE (evidence_id,ordinal)
);

CREATE TABLE model_runs (
    model_run_id UUID PRIMARY KEY,
    actor_identity TEXT NOT NULL,
    actor_version TEXT,
    task_type model_run_task_code NOT NULL,
    specification_version_id TEXT REFERENCES specification_versions(specification_version_id) ON DELETE RESTRICT,
    input_hash TEXT NOT NULL,
    output_hash TEXT,
    configuration_hash TEXT,
    disposition review_status_code NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (btrim(actor_identity) <> ''),
    CHECK (btrim(input_hash) <> '')
);

CREATE TABLE candidate_model_runs (
    candidate_id UUID NOT NULL REFERENCES candidate_records(candidate_id) ON DELETE RESTRICT,
    model_run_id UUID NOT NULL REFERENCES model_runs(model_run_id) ON DELETE RESTRICT,
    relationship TEXT NOT NULL DEFAULT 'GENERATED_BY',
    PRIMARY KEY (candidate_id,model_run_id),
    CHECK (btrim(relationship) <> '')
);

CREATE TABLE evidence_provenance_links (
    evidence_id TEXT NOT NULL REFERENCES evidence(evidence_id) ON DELETE RESTRICT,
    provenance_event_id UUID NOT NULL REFERENCES provenance_events(provenance_event_id) ON DELETE RESTRICT,
    relationship TEXT NOT NULL,
    PRIMARY KEY (evidence_id,provenance_event_id),
    CHECK (btrim(relationship) <> '')
);

CREATE TABLE review_score_dimensions (
    review_event_id UUID NOT NULL REFERENCES review_events(review_event_id) ON DELETE RESTRICT,
    dimension score_dimension_code NOT NULL,
    proposed_value SMALLINT NOT NULL CHECK (proposed_value BETWEEN 0 AND 4),
    rationale TEXT NOT NULL,
    PRIMARY KEY (review_event_id,dimension),
    CHECK (btrim(rationale) <> '')
);

COMMENT ON COLUMN evidence.provenance IS
'Legacy/non-authoritative context only. Canonical provenance relationships live in provenance_events and evidence_provenance_links.';
COMMENT ON COLUMN review_events.structured_scores IS
'Legacy/non-authoritative context only. Canonical review score dimensions live in review_score_dimensions.';
COMMENT ON COLUMN claim_evidence.proposed_score_change IS
'Legacy/non-authoritative context only. Authoritative score proposals live in score_change_proposals.';
COMMENT ON COLUMN claim_evidence.approved_score_change IS
'Deprecated and constrained NULL. Authoritative approved changes are represented by approval_events and claim_score_snapshots.';

CREATE OR REPLACE FUNCTION prevent_authoritative_json_score_use()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.structured_scores IS NOT NULL AND NEW.decision='APPROVED' THEN
        RAISE EXCEPTION 'approved review scores must use review_score_dimensions, not structured_scores JSON';
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER review_events_no_authoritative_json_scores
BEFORE INSERT OR UPDATE OF structured_scores,decision ON review_events
FOR EACH ROW EXECUTE FUNCTION prevent_authoritative_json_score_use();

CREATE INDEX idx_evidence_context_context ON evidence_evaluation_contexts(evaluation_context_id);
CREATE INDEX idx_evidence_measurements_measurement ON evidence_measurements(measurement_id);
CREATE INDEX idx_model_runs_specification ON model_runs(specification_version_id);
CREATE INDEX idx_candidate_model_runs_model ON candidate_model_runs(model_run_id);
CREATE INDEX idx_evidence_provenance_event ON evidence_provenance_links(provenance_event_id);

GRANT SELECT ON evaluation_contexts,evidence_evaluation_contexts,measurements,evidence_measurements,model_runs,candidate_model_runs,evidence_provenance_links,review_score_dimensions
TO cee_app_read,cee_ingest,cee_review,cee_approve,cee_release;

COMMIT;
