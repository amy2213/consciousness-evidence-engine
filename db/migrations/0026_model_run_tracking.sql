-- Phase 15: reproducible model-run tracking.
-- Model-assisted work is provenance, never scientific authority.
BEGIN;

CREATE TYPE model_run_disposition_code AS ENUM (
  'PENDING_HUMAN_REVIEW','ACCEPTED_AS_CANDIDATE','REVISED_BY_HUMAN','REJECTED_BY_HUMAN','SUPERSEDED','NOT_APPLICABLE'
);
CREATE TYPE model_run_io_kind_code AS ENUM ('INPUT','OUTPUT');
CREATE TYPE model_run_reference_type_code AS ENUM (
  'SOURCE','BIBLIOGRAPHIC_WORK','SOURCE_LOCATOR','CANDIDATE','EVIDENCE','CLAIM','MEASUREMENT','MODEL_RUN','OTHER'
);

ALTER TABLE model_runs
  ADD COLUMN provider TEXT,
  ADD COLUMN model_name TEXT,
  ADD COLUMN model_version TEXT,
  ADD COLUMN configuration JSONB,
  ADD COLUMN prompt_or_protocol_id TEXT,
  ADD COLUMN started_at TIMESTAMPTZ,
  ADD COLUMN completed_at TIMESTAMPTZ,
  ADD COLUMN run_disposition model_run_disposition_code NOT NULL DEFAULT 'PENDING_HUMAN_REVIEW',
  ADD COLUMN disposition_actor_type provenance_actor_type,
  ADD COLUMN disposition_actor_identity TEXT,
  ADD COLUMN disposition_rationale TEXT,
  ADD COLUMN disposition_provenance_event_id UUID REFERENCES provenance_events(provenance_event_id) ON DELETE RESTRICT,
  ADD CONSTRAINT model_run_actor_nonblank CHECK (btrim(actor_identity)<>''),
  ADD CONSTRAINT model_run_model_name_nonblank CHECK (model_name IS NULL OR btrim(model_name)<>''),
  ADD CONSTRAINT model_run_model_version_nonblank CHECK (model_version IS NULL OR btrim(model_version)<>''),
  ADD CONSTRAINT model_run_protocol_nonblank CHECK (prompt_or_protocol_id IS NULL OR btrim(prompt_or_protocol_id)<>''),
  ADD CONSTRAINT model_run_time_order CHECK (completed_at IS NULL OR started_at IS NULL OR completed_at>=started_at),
  ADD CONSTRAINT model_run_disposition_review CHECK (
    (run_disposition='PENDING_HUMAN_REVIEW' AND disposition_actor_type IS NULL AND disposition_actor_identity IS NULL AND disposition_provenance_event_id IS NULL)
    OR
    (run_disposition<>'PENDING_HUMAN_REVIEW' AND disposition_actor_type='HUMAN' AND disposition_actor_identity IS NOT NULL AND disposition_rationale IS NOT NULL AND disposition_provenance_event_id IS NOT NULL)
  );

COMMENT ON COLUMN model_runs.disposition IS 'Legacy review-status field retained for compatibility. Canonical Phase 15 human disposition is run_disposition plus disposition provenance.';
COMMENT ON COLUMN model_runs.configuration_hash IS 'Stable hash of model/tool configuration where available; configuration JSON is descriptive and non-authoritative.';
COMMENT ON COLUMN model_runs.output_hash IS 'Hash of the complete run output where available. Individual outputs are represented in model_run_artifacts.';

CREATE TABLE model_run_references (
  model_run_reference_id UUID PRIMARY KEY,
  model_run_id UUID NOT NULL REFERENCES model_runs(model_run_id) ON DELETE RESTRICT,
  io_kind model_run_io_kind_code NOT NULL,
  reference_type model_run_reference_type_code NOT NULL,
  reference_id TEXT NOT NULL,
  content_hash TEXT,
  ordinal INTEGER NOT NULL CHECK (ordinal>0),
  rationale TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(model_run_id,io_kind,ordinal),
  CHECK (btrim(reference_id)<>''),CHECK (content_hash IS NULL OR btrim(content_hash)<>''),CHECK (btrim(rationale)<>'')
);

CREATE TABLE model_run_artifacts (
  model_run_artifact_id UUID PRIMARY KEY,
  model_run_id UUID NOT NULL REFERENCES model_runs(model_run_id) ON DELETE RESTRICT,
  artifact_kind TEXT NOT NULL,
  artifact_hash TEXT NOT NULL,
  media_type TEXT,
  storage_reference TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (btrim(artifact_kind)<>''),CHECK (btrim(artifact_hash)<>''),
  CHECK (media_type IS NULL OR btrim(media_type)<>''),CHECK (storage_reference IS NULL OR btrim(storage_reference)<>'')
);

CREATE TABLE authoritative_model_run_links (
  authoritative_model_run_link_id UUID PRIMARY KEY,
  model_run_id UUID NOT NULL REFERENCES model_runs(model_run_id) ON DELETE RESTRICT,
  entity_type TEXT NOT NULL CHECK (entity_type IN ('EVIDENCE','CLAIM_EVIDENCE','SCORE_CHANGE','APPROVED_INTERPRETATION')),
  entity_id TEXT NOT NULL,
  relationship TEXT NOT NULL CHECK (relationship IN ('INFORMED','EXTRACTED_CANDIDATE','CLASSIFIED_CANDIDATE','SCORED_CANDIDATE','CONTRADICTION_FLAG','SYNTHESIS_INPUT')),
  human_disposition_provenance_event_id UUID NOT NULL REFERENCES provenance_events(provenance_event_id) ON DELETE RESTRICT,
  rationale TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(model_run_id,entity_type,entity_id,relationship),
  CHECK (btrim(entity_id)<>''),CHECK (btrim(rationale)<>'')
);

CREATE OR REPLACE FUNCTION prevent_model_run_history_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION '% is append-only model-run history',TG_TABLE_NAME; END;$$;
CREATE TRIGGER model_run_references_no_mutation BEFORE UPDATE OR DELETE ON model_run_references FOR EACH ROW EXECUTE FUNCTION prevent_model_run_history_mutation();
CREATE TRIGGER model_run_artifacts_no_mutation BEFORE UPDATE OR DELETE ON model_run_artifacts FOR EACH ROW EXECUTE FUNCTION prevent_model_run_history_mutation();
CREATE TRIGGER authoritative_model_run_links_no_mutation BEFORE UPDATE OR DELETE ON authoritative_model_run_links FOR EACH ROW EXECUTE FUNCTION prevent_model_run_history_mutation();

CREATE OR REPLACE FUNCTION enforce_model_run_disposition_provenance() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE pe provenance_events%ROWTYPE;
BEGIN
 IF NEW.run_disposition<>'PENDING_HUMAN_REVIEW' THEN
   SELECT * INTO pe FROM provenance_events WHERE provenance_event_id=NEW.disposition_provenance_event_id;
   IF pe.provenance_event_id IS NULL OR pe.actor_type<>'HUMAN' OR pe.actor_identity IS DISTINCT FROM NEW.disposition_actor_identity THEN
     RAISE EXCEPTION 'model-run disposition requires matching HUMAN provenance event';
   END IF;
 END IF;
 RETURN NEW;
END;$$;
CREATE TRIGGER model_run_disposition_provenance_gate BEFORE INSERT OR UPDATE OF run_disposition,disposition_actor_type,disposition_actor_identity,disposition_provenance_event_id ON model_runs FOR EACH ROW EXECUTE FUNCTION enforce_model_run_disposition_provenance();

CREATE OR REPLACE FUNCTION enforce_authoritative_model_run_link() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE mr model_runs%ROWTYPE; pe provenance_events%ROWTYPE;
BEGIN
 SELECT * INTO mr FROM model_runs WHERE model_run_id=NEW.model_run_id;
 IF mr.model_run_id IS NULL OR mr.run_disposition NOT IN ('ACCEPTED_AS_CANDIDATE','REVISED_BY_HUMAN') THEN
   RAISE EXCEPTION 'authoritative AI/model-run link requires explicit human disposition';
 END IF;
 SELECT * INTO pe FROM provenance_events WHERE provenance_event_id=NEW.human_disposition_provenance_event_id;
 IF pe.provenance_event_id IS NULL OR pe.actor_type<>'HUMAN' OR pe.actor_identity IS DISTINCT FROM mr.disposition_actor_identity THEN
   RAISE EXCEPTION 'authoritative AI/model-run link must bind to model run human disposition provenance';
 END IF;
 RETURN NEW;
END;$$;
CREATE TRIGGER authoritative_model_run_link_gate BEFORE INSERT ON authoritative_model_run_links FOR EACH ROW EXECUTE FUNCTION enforce_authoritative_model_run_link();

CREATE OR REPLACE FUNCTION enforce_candidate_model_run_semantics() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE mr model_runs%ROWTYPE;
BEGIN
 SELECT * INTO mr FROM model_runs WHERE model_run_id=NEW.model_run_id;
 IF mr.model_run_id IS NULL THEN RAISE EXCEPTION 'candidate model-run link requires existing model run'; END IF;
 IF NEW.relationship='GENERATED_BY' AND mr.task_type<>'EXTRACTION' THEN
   RAISE EXCEPTION 'GENERATED_BY candidate relationship requires EXTRACTION model run';
 END IF;
 RETURN NEW;
END;$$;
CREATE TRIGGER candidate_model_run_semantics_gate BEFORE INSERT ON candidate_model_runs FOR EACH ROW EXECUTE FUNCTION enforce_candidate_model_run_semantics();

CREATE VIEW model_run_trace AS
SELECT mr.model_run_id,mr.actor_identity,mr.actor_version,mr.provider,mr.model_name,mr.model_version,mr.task_type,
 mr.specification_version_id,mr.input_hash,mr.output_hash,mr.configuration_hash,mr.prompt_or_protocol_id,mr.created_at,
 mr.started_at,mr.completed_at,mr.run_disposition,mr.disposition_actor_identity,mr.disposition_provenance_event_id,
 count(DISTINCT mrr.model_run_reference_id) FILTER (WHERE mrr.io_kind='INPUT') AS input_reference_count,
 count(DISTINCT mrr.model_run_reference_id) FILTER (WHERE mrr.io_kind='OUTPUT') AS output_reference_count,
 count(DISTINCT mra.model_run_artifact_id) AS artifact_count,
 count(DISTINCT aml.authoritative_model_run_link_id) AS authoritative_link_count
FROM model_runs mr
LEFT JOIN model_run_references mrr ON mrr.model_run_id=mr.model_run_id
LEFT JOIN model_run_artifacts mra ON mra.model_run_id=mr.model_run_id
LEFT JOIN authoritative_model_run_links aml ON aml.model_run_id=mr.model_run_id
GROUP BY mr.model_run_id;

CREATE INDEX idx_model_run_references_run ON model_run_references(model_run_id,io_kind,ordinal);
CREATE INDEX idx_model_run_artifacts_run ON model_run_artifacts(model_run_id);
CREATE INDEX idx_authoritative_model_run_links_entity ON authoritative_model_run_links(entity_type,entity_id);
CREATE INDEX idx_model_runs_task_disposition ON model_runs(task_type,run_disposition);

GRANT SELECT ON model_run_references,model_run_artifacts,authoritative_model_run_links,model_run_trace TO cee_app_read,cee_ingest,cee_review,cee_approve,cee_release;
GRANT INSERT ON model_runs,model_run_references,model_run_artifacts,candidate_model_runs TO cee_ingest;
GRANT UPDATE(run_disposition,disposition_actor_type,disposition_actor_identity,disposition_rationale,disposition_provenance_event_id) ON model_runs TO cee_review;
GRANT INSERT ON authoritative_model_run_links TO cee_approve;

COMMIT;
