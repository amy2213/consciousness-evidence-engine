-- Phase 13: end-to-end provenance.
-- Authoritative scientific interpretation must be traversable from release to exact bibliographic locator.

ALTER TYPE approval_scope_code ADD VALUE IF NOT EXISTS 'INTERPRETATION_APPROVAL';

BEGIN;

CREATE TYPE source_locator_type_code AS ENUM (
  'PAGE','SECTION','FIGURE','TABLE','SUPPLEMENT','RESULT','METHOD','ABSTRACT','OTHER'
);

CREATE TABLE source_locators (
  source_locator_id UUID PRIMARY KEY,
  source_id TEXT NOT NULL,
  work_id TEXT NOT NULL,
  locator_type source_locator_type_code NOT NULL,
  locator_text TEXT NOT NULL,
  content_hash TEXT,
  provenance_event_id UUID REFERENCES provenance_events(provenance_event_id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY (source_id,work_id) REFERENCES source_works(source_id,work_id) ON DELETE RESTRICT,
  CHECK (btrim(locator_text) <> ''),
  CHECK (content_hash IS NULL OR btrim(content_hash) <> '')
);

CREATE TABLE evidence_source_locations (
  evidence_id TEXT NOT NULL REFERENCES evidence(evidence_id) ON DELETE RESTRICT,
  source_locator_id UUID NOT NULL REFERENCES source_locators(source_locator_id) ON DELETE RESTRICT,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  rationale TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (evidence_id,source_locator_id),
  CHECK (btrim(rationale) <> '')
);
CREATE UNIQUE INDEX uq_evidence_primary_source_location
ON evidence_source_locations(evidence_id) WHERE is_primary;

CREATE TABLE approved_interpretations (
  approved_interpretation_id UUID PRIMARY KEY,
  claim_id TEXT NOT NULL,
  evidence_id TEXT NOT NULL,
  evaluation_version TEXT NOT NULL,
  interpretation_hash TEXT NOT NULL,
  approval_event_id UUID NOT NULL UNIQUE REFERENCES approval_events(approval_event_id) ON DELETE RESTRICT,
  provenance_event_id UUID NOT NULL REFERENCES provenance_events(provenance_event_id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  FOREIGN KEY (claim_id,evidence_id,evaluation_version)
    REFERENCES claim_evidence(claim_id,evidence_id,evaluation_version) ON DELETE RESTRICT,
  CHECK (btrim(interpretation_hash) <> '')
);

CREATE TABLE release_interpretations (
  release_id TEXT NOT NULL REFERENCES dataset_releases(release_id) ON DELETE RESTRICT,
  approved_interpretation_id UUID NOT NULL REFERENCES approved_interpretations(approved_interpretation_id) ON DELETE RESTRICT,
  ordinal INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (release_id,approved_interpretation_id),
  UNIQUE (release_id,ordinal)
);

ALTER TABLE candidate_records
  ADD COLUMN extraction_protocol TEXT,
  ADD COLUMN candidate_hash TEXT,
  ADD COLUMN parent_source_hash TEXT,
  ADD COLUMN provenance_event_id UUID REFERENCES provenance_events(provenance_event_id) ON DELETE RESTRICT;

COMMENT ON TABLE source_locators IS
'Exact work-level locators. Corrections create new locator/provenance rows rather than rewriting provenance history.';
COMMENT ON TABLE approved_interpretations IS
'Immutable human-approved claim/evidence interpretations bound to exact relation state and approval provenance.';
COMMENT ON TABLE release_interpretations IS
'Explicit release-to-approved-interpretation bridge used for end-to-end scientific provenance.';
COMMENT ON COLUMN candidate_records.extraction_protocol IS
'Protocol/prompt/process identifier used for candidate extraction where available.';
COMMENT ON COLUMN candidate_records.candidate_hash IS
'Hash of the extracted candidate payload where available.';
COMMENT ON COLUMN candidate_records.parent_source_hash IS
'Hash of the parent source representation used for extraction where available.';

CREATE OR REPLACE FUNCTION canonical_interpretation_hash(
  p_claim_id TEXT,p_evidence_id TEXT,p_evaluation_version TEXT
) RETURNS TEXT LANGUAGE sql STABLE AS $$
  SELECT md5(concat_ws('|',
    ce.claim_id,ce.evidence_id,ce.evaluation_version,ce.relationship::text,ce.interpretation,
    ce.score_effect::text,ce.inference_strength::text,ce.inference_target::text,
    ce.result_polarity::text,ce.component_scope_only::text,
    ce.synthetic_experience_bridge_established::text,
    ce.necessity_design_established::text,ce.sufficiency_design_established::text,
    COALESCE(ce.epistemic_rationale,'')))
  FROM claim_evidence ce
  WHERE ce.claim_id=p_claim_id AND ce.evidence_id=p_evidence_id AND ce.evaluation_version=p_evaluation_version;
$$;

ALTER TABLE approval_events DROP CONSTRAINT approval_scope_target_check;
ALTER TABLE approval_events ADD CONSTRAINT approval_scope_target_check CHECK (
    (approval_scope = 'CANDIDATE_DISPOSITION' AND candidate_id IS NOT NULL AND evidence_id IS NULL AND score_change_id IS NULL AND release_id IS NULL)
    OR
    (approval_scope = 'EVIDENCE_PROMOTION' AND evidence_id IS NOT NULL AND candidate_id IS NULL AND score_change_id IS NULL AND release_id IS NULL)
    OR
    (approval_scope = 'SCORE_CHANGE' AND score_change_id IS NOT NULL AND candidate_id IS NULL AND release_id IS NULL)
    OR
    (approval_scope = 'INTERPRETATION_APPROVAL' AND claim_id IS NOT NULL AND evidence_id IS NOT NULL AND candidate_id IS NULL AND score_change_id IS NULL AND release_id IS NULL)
    OR
    (approval_scope = 'RELEASE_CERTIFICATION' AND release_id IS NOT NULL AND candidate_id IS NULL AND score_change_id IS NULL)
    OR
    (approval_scope IN ('SOURCE_CLOSURE','CLAIM_REVISION') AND candidate_id IS NULL AND score_change_id IS NULL AND release_id IS NULL)
);

CREATE OR REPLACE FUNCTION enforce_interpretation_approval_scope()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE expected_hash TEXT;
DECLARE evidence_state evidence_lifecycle_status;
BEGIN
  IF NEW.approval_scope='INTERPRETATION_APPROVAL' THEN
    SELECT canonical_interpretation_hash(NEW.claim_id,NEW.evidence_id,NEW.entity_version)
      INTO expected_hash;
    IF expected_hash IS NULL THEN
      RAISE EXCEPTION 'interpretation approval requires exact claim_evidence tuple';
    END IF;
    IF NEW.scope_hash IS NULL OR NEW.scope_hash IS DISTINCT FROM expected_hash THEN
      RAISE EXCEPTION 'interpretation approval scope_hash must match exact claim_evidence state';
    END IF;
    SELECT evidence_status INTO evidence_state FROM evidence WHERE evidence_id=NEW.evidence_id;
    IF evidence_state <> 'APPROVED' THEN
      RAISE EXCEPTION 'interpretation approval requires APPROVED evidence';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER interpretation_approval_scope_gate
BEFORE INSERT ON approval_events
FOR EACH ROW EXECUTE FUNCTION enforce_interpretation_approval_scope();

CREATE OR REPLACE FUNCTION enforce_approved_interpretation_binding()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE ae approval_events%ROWTYPE;
DECLARE expected_hash TEXT;
DECLARE pe provenance_events%ROWTYPE;
BEGIN
  SELECT * INTO ae FROM approval_events WHERE approval_event_id=NEW.approval_event_id;
  IF ae.approval_event_id IS NULL
     OR ae.approval_scope<>'INTERPRETATION_APPROVAL'
     OR ae.decision<>'APPROVE'
     OR ae.approver_actor_type<>'HUMAN'
     OR ae.claim_id IS DISTINCT FROM NEW.claim_id
     OR ae.evidence_id IS DISTINCT FROM NEW.evidence_id
     OR ae.entity_version IS DISTINCT FROM NEW.evaluation_version THEN
    RAISE EXCEPTION 'approved interpretation requires exact HUMAN INTERPRETATION_APPROVAL event';
  END IF;
  expected_hash := canonical_interpretation_hash(NEW.claim_id,NEW.evidence_id,NEW.evaluation_version);
  IF expected_hash IS NULL OR NEW.interpretation_hash IS DISTINCT FROM expected_hash OR ae.scope_hash IS DISTINCT FROM expected_hash THEN
    RAISE EXCEPTION 'approved interpretation hash must match exact claim_evidence state';
  END IF;
  SELECT * INTO pe FROM provenance_events WHERE provenance_event_id=NEW.provenance_event_id;
  IF pe.provenance_event_id IS NULL OR pe.actor_type<>'HUMAN' OR pe.actor_identity IS DISTINCT FROM ae.approver_identity THEN
    RAISE EXCEPTION 'approved interpretation provenance must bind to same HUMAN approver';
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER approved_interpretation_binding_gate
BEFORE INSERT ON approved_interpretations
FOR EACH ROW EXECUTE FUNCTION enforce_approved_interpretation_binding();

CREATE OR REPLACE FUNCTION prevent_phase13_provenance_mutation()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION '% is append-only provenance state',TG_TABLE_NAME;
END;
$$;
CREATE TRIGGER source_locators_no_update_delete BEFORE UPDATE OR DELETE ON source_locators
FOR EACH ROW EXECUTE FUNCTION prevent_phase13_provenance_mutation();
CREATE TRIGGER evidence_source_locations_no_update_delete BEFORE UPDATE OR DELETE ON evidence_source_locations
FOR EACH ROW EXECUTE FUNCTION prevent_phase13_provenance_mutation();
CREATE TRIGGER approved_interpretations_no_update_delete BEFORE UPDATE OR DELETE ON approved_interpretations
FOR EACH ROW EXECUTE FUNCTION prevent_phase13_provenance_mutation();

CREATE OR REPLACE FUNCTION enforce_evidence_source_location_match()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE evidence_source TEXT;
DECLARE locator_source TEXT;
BEGIN
  SELECT source_id INTO evidence_source FROM evidence WHERE evidence_id=NEW.evidence_id;
  SELECT source_id INTO locator_source FROM source_locators WHERE source_locator_id=NEW.source_locator_id;
  IF evidence_source IS DISTINCT FROM locator_source THEN
    RAISE EXCEPTION 'evidence source locator must belong to the evidence source container';
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER evidence_source_location_match_gate
BEFORE INSERT ON evidence_source_locations
FOR EACH ROW EXECUTE FUNCTION enforce_evidence_source_location_match();

-- Approved evidence must have an exact primary work-level locator.
CREATE OR REPLACE FUNCTION enforce_evidence_primary_source_location()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.evidence_status='APPROVED' AND NOT EXISTS (
    SELECT 1 FROM evidence_source_locations esl
    WHERE esl.evidence_id=NEW.evidence_id AND esl.is_primary
  ) THEN
    RAISE EXCEPTION 'APPROVED evidence requires exact primary bibliographic work locator';
  END IF;
  RETURN NEW;
END;
$$;
CREATE CONSTRAINT TRIGGER evidence_requires_primary_source_location
AFTER INSERT OR UPDATE OF evidence_status ON evidence
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION enforce_evidence_primary_source_location();

CREATE OR REPLACE FUNCTION guard_release_interpretation_mutation()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE rid TEXT;
DECLARE rstatus dataset_release_status_code;
BEGIN
  rid:=COALESCE(NEW.release_id,OLD.release_id);
  SELECT status INTO rstatus FROM dataset_releases WHERE release_id=rid;
  IF rstatus IS DISTINCT FROM 'DRAFT' THEN
    RAISE EXCEPTION 'release provenance membership is immutable after certification';
  END IF;
  RETURN COALESCE(NEW,OLD);
END;
$$;
CREATE TRIGGER release_interpretations_mutation_gate
BEFORE INSERT OR UPDATE OR DELETE ON release_interpretations
FOR EACH ROW EXECUTE FUNCTION guard_release_interpretation_mutation();

CREATE VIEW release_provenance_paths AS
SELECT
  dr.release_id,dr.status AS release_status,dr.specification_version_id,
  ai.approved_interpretation_id,ai.claim_id,ai.evidence_id,ai.evaluation_version,
  ai.approval_event_id,ai.provenance_event_id AS interpretation_provenance_event_id,
  e.source_id,sl.source_locator_id,sl.work_id,sl.locator_type,sl.locator_text,
  sl.content_hash AS locator_content_hash,bw.title AS work_title,bw.doi,bw.pmid,bw.pmcid
FROM dataset_releases dr
JOIN release_interpretations ri ON ri.release_id=dr.release_id
JOIN approved_interpretations ai ON ai.approved_interpretation_id=ri.approved_interpretation_id
JOIN evidence e ON e.evidence_id=ai.evidence_id
JOIN evidence_source_locations esl ON esl.evidence_id=e.evidence_id AND esl.is_primary
JOIN source_locators sl ON sl.source_locator_id=esl.source_locator_id
JOIN bibliographic_works bw ON bw.work_id=sl.work_id;

CREATE INDEX idx_source_locators_source_work ON source_locators(source_id,work_id);
CREATE INDEX idx_evidence_source_locations_locator ON evidence_source_locations(source_locator_id);
CREATE INDEX idx_approved_interpretations_relation ON approved_interpretations(claim_id,evidence_id,evaluation_version);
CREATE INDEX idx_release_interpretations_approved ON release_interpretations(approved_interpretation_id);

GRANT SELECT ON source_locators,evidence_source_locations,approved_interpretations,release_interpretations,release_provenance_paths
TO cee_app_read,cee_ingest,cee_review,cee_approve,cee_release;
GRANT INSERT ON approved_interpretations TO cee_approve;
GRANT INSERT ON release_interpretations TO cee_release;

COMMIT;
