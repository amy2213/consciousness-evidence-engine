-- Phase 14: candidate-ingestion pipeline.
-- Candidates move through a typed, append-only quarantine workflow. AI may propose; only human approval can authorize promotion.

ALTER TYPE approval_scope_code ADD VALUE IF NOT EXISTS 'CANDIDATE_PROMOTION';

BEGIN;

CREATE TYPE candidate_stage_code AS ENUM (
  'EXTRACTED','STRUCTURALLY_VALIDATED','PROVENANCE_VALIDATED','DEDUPLICATED',
  'EVIDENCE_PROPOSED','SCORING_PROPOSED','EPISTEMIC_EVALUATED','ADVERSARIAL_REVIEWED',
  'HUMAN_APPROVED','COMMITTED','REJECTED','NEEDS_RESOLUTION'
);
CREATE TYPE candidate_validation_code AS ENUM ('PASS','FAIL','NEEDS_RESOLUTION');
CREATE TYPE duplicate_disposition_code AS ENUM ('UNIQUE','POSSIBLE_DUPLICATE','DUPLICATE','NEEDS_RESOLUTION');

ALTER TABLE candidate_records
  ADD COLUMN current_stage candidate_stage_code NOT NULL DEFAULT 'EXTRACTED',
  ADD COLUMN proposed_evidence_id TEXT,
  ADD COLUMN proposed_evaluation_version TEXT,
  ADD COLUMN committed_evidence_id TEXT REFERENCES evidence(evidence_id) ON DELETE RESTRICT,
  ADD CONSTRAINT candidate_source_required CHECK (source_id IS NOT NULL),
  ADD CONSTRAINT candidate_extractor_nonblank CHECK (btrim(extractor_identity)<>''),
  ADD CONSTRAINT candidate_hash_nonblank CHECK (candidate_hash IS NULL OR btrim(candidate_hash)<>''),
  ADD CONSTRAINT candidate_parent_hash_nonblank CHECK (parent_source_hash IS NULL OR btrim(parent_source_hash)<>'');

CREATE TABLE candidate_stage_events (
  candidate_stage_event_id UUID PRIMARY KEY,
  candidate_id UUID NOT NULL REFERENCES candidate_records(candidate_id) ON DELETE RESTRICT,
  from_stage candidate_stage_code,
  to_stage candidate_stage_code NOT NULL,
  actor_type provenance_actor_type NOT NULL,
  actor_identity TEXT NOT NULL,
  rationale TEXT NOT NULL,
  provenance_event_id UUID NOT NULL REFERENCES provenance_events(provenance_event_id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (btrim(actor_identity)<>''), CHECK (btrim(rationale)<>'')
);

CREATE TABLE candidate_validations (
  candidate_validation_id UUID PRIMARY KEY,
  candidate_id UUID NOT NULL REFERENCES candidate_records(candidate_id) ON DELETE RESTRICT,
  validation_kind TEXT NOT NULL CHECK (validation_kind IN ('STRUCTURAL','PROVENANCE')),
  result candidate_validation_code NOT NULL,
  validator_identity TEXT NOT NULL,
  validator_actor_type provenance_actor_type NOT NULL,
  details JSONB NOT NULL DEFAULT '{}'::jsonb,
  provenance_event_id UUID NOT NULL REFERENCES provenance_events(provenance_event_id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (btrim(validator_identity)<>'')
);

CREATE TABLE candidate_duplicate_checks (
  duplicate_check_id UUID PRIMARY KEY,
  candidate_id UUID NOT NULL REFERENCES candidate_records(candidate_id) ON DELETE RESTRICT,
  disposition duplicate_disposition_code NOT NULL,
  matched_candidate_id UUID REFERENCES candidate_records(candidate_id) ON DELETE RESTRICT,
  matched_evidence_id TEXT REFERENCES evidence(evidence_id) ON DELETE RESTRICT,
  method TEXT NOT NULL,
  rationale TEXT NOT NULL,
  provenance_event_id UUID NOT NULL REFERENCES provenance_events(provenance_event_id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (btrim(method)<>''), CHECK (btrim(rationale)<>''),
  CHECK (candidate_id IS DISTINCT FROM matched_candidate_id),
  CHECK ((disposition='UNIQUE' AND matched_candidate_id IS NULL AND matched_evidence_id IS NULL) OR disposition<>'UNIQUE')
);

CREATE TABLE candidate_evidence_proposals (
  candidate_evidence_proposal_id UUID PRIMARY KEY,
  candidate_id UUID NOT NULL UNIQUE REFERENCES candidate_records(candidate_id) ON DELETE RESTRICT,
  proposed_evidence_id TEXT NOT NULL,
  source_id TEXT NOT NULL REFERENCES sources(source_id) ON DELETE RESTRICT,
  evaluation_version TEXT NOT NULL,
  evidence_payload JSONB NOT NULL,
  payload_hash TEXT NOT NULL,
  proposed_by TEXT NOT NULL,
  proposed_by_type provenance_actor_type NOT NULL,
  provenance_event_id UUID NOT NULL REFERENCES provenance_events(provenance_event_id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (btrim(proposed_evidence_id)<>''),CHECK (btrim(evaluation_version)<>''),CHECK (btrim(payload_hash)<>''),CHECK (btrim(proposed_by)<>'')
);

CREATE TABLE candidate_score_proposals (
  candidate_score_proposal_id UUID PRIMARY KEY,
  candidate_id UUID NOT NULL REFERENCES candidate_records(candidate_id) ON DELETE RESTRICT,
  claim_id TEXT NOT NULL REFERENCES claims(claim_id) ON DELETE RESTRICT,
  evaluation_version TEXT NOT NULL,
  dimension score_dimension_code NOT NULL,
  proposed_value SMALLINT NOT NULL CHECK (proposed_value BETWEEN 0 AND 4),
  rationale TEXT NOT NULL,
  proposed_by TEXT NOT NULL,
  proposed_by_type provenance_actor_type NOT NULL,
  provenance_event_id UUID NOT NULL REFERENCES provenance_events(provenance_event_id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(candidate_id,claim_id,evaluation_version,dimension),
  CHECK (btrim(rationale)<>''),CHECK (btrim(proposed_by)<>'')
);

CREATE TABLE candidate_rule_evaluations (
  candidate_rule_evaluation_id UUID PRIMARY KEY,
  candidate_id UUID NOT NULL REFERENCES candidate_records(candidate_id) ON DELETE RESTRICT,
  rule_id TEXT NOT NULL REFERENCES rules(rule_id) ON DELETE RESTRICT,
  result candidate_validation_code NOT NULL,
  evaluator_identity TEXT NOT NULL,
  evaluator_actor_type provenance_actor_type NOT NULL,
  rationale TEXT NOT NULL,
  provenance_event_id UUID NOT NULL REFERENCES provenance_events(provenance_event_id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(candidate_id,rule_id), CHECK (btrim(evaluator_identity)<>''),CHECK (btrim(rationale)<>'')
);

CREATE TABLE candidate_adversarial_reviews (
  candidate_adversarial_review_id UUID PRIMARY KEY,
  candidate_id UUID NOT NULL REFERENCES candidate_records(candidate_id) ON DELETE RESTRICT,
  reviewer_identity TEXT NOT NULL,
  reviewer_actor_type provenance_actor_type NOT NULL,
  decision candidate_validation_code NOT NULL,
  rationale TEXT NOT NULL,
  provenance_event_id UUID NOT NULL REFERENCES provenance_events(provenance_event_id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (btrim(reviewer_identity)<>''),CHECK (btrim(rationale)<>'')
);

CREATE TABLE candidate_authoritative_commits (
  candidate_authoritative_commit_id UUID PRIMARY KEY,
  candidate_id UUID NOT NULL UNIQUE REFERENCES candidate_records(candidate_id) ON DELETE RESTRICT,
  evidence_id TEXT NOT NULL UNIQUE REFERENCES evidence(evidence_id) ON DELETE RESTRICT,
  approval_event_id UUID NOT NULL UNIQUE REFERENCES approval_events(approval_event_id) ON DELETE RESTRICT,
  provenance_event_id UUID NOT NULL REFERENCES provenance_events(provenance_event_id) ON DELETE RESTRICT,
  committed_by TEXT NOT NULL,
  committed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (btrim(committed_by)<>'')
);

CREATE OR REPLACE FUNCTION prevent_candidate_pipeline_fact_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION '% is append-only candidate pipeline history',TG_TABLE_NAME; END;$$;
CREATE TRIGGER candidate_stage_events_no_mutation BEFORE UPDATE OR DELETE ON candidate_stage_events FOR EACH ROW EXECUTE FUNCTION prevent_candidate_pipeline_fact_mutation();
CREATE TRIGGER candidate_validations_no_mutation BEFORE UPDATE OR DELETE ON candidate_validations FOR EACH ROW EXECUTE FUNCTION prevent_candidate_pipeline_fact_mutation();
CREATE TRIGGER candidate_duplicate_checks_no_mutation BEFORE UPDATE OR DELETE ON candidate_duplicate_checks FOR EACH ROW EXECUTE FUNCTION prevent_candidate_pipeline_fact_mutation();
CREATE TRIGGER candidate_evidence_proposals_no_mutation BEFORE UPDATE OR DELETE ON candidate_evidence_proposals FOR EACH ROW EXECUTE FUNCTION prevent_candidate_pipeline_fact_mutation();
CREATE TRIGGER candidate_score_proposals_no_mutation BEFORE UPDATE OR DELETE ON candidate_score_proposals FOR EACH ROW EXECUTE FUNCTION prevent_candidate_pipeline_fact_mutation();
CREATE TRIGGER candidate_rule_evaluations_no_mutation BEFORE UPDATE OR DELETE ON candidate_rule_evaluations FOR EACH ROW EXECUTE FUNCTION prevent_candidate_pipeline_fact_mutation();
CREATE TRIGGER candidate_adversarial_reviews_no_mutation BEFORE UPDATE OR DELETE ON candidate_adversarial_reviews FOR EACH ROW EXECUTE FUNCTION prevent_candidate_pipeline_fact_mutation();
CREATE TRIGGER candidate_authoritative_commits_no_mutation BEFORE UPDATE OR DELETE ON candidate_authoritative_commits FOR EACH ROW EXECUTE FUNCTION prevent_candidate_pipeline_fact_mutation();

CREATE OR REPLACE FUNCTION candidate_stage_rank(s candidate_stage_code) RETURNS integer LANGUAGE sql IMMUTABLE AS $$
 SELECT CASE s WHEN 'EXTRACTED' THEN 1 WHEN 'STRUCTURALLY_VALIDATED' THEN 2 WHEN 'PROVENANCE_VALIDATED' THEN 3 WHEN 'DEDUPLICATED' THEN 4
 WHEN 'EVIDENCE_PROPOSED' THEN 5 WHEN 'SCORING_PROPOSED' THEN 6 WHEN 'EPISTEMIC_EVALUATED' THEN 7 WHEN 'ADVERSARIAL_REVIEWED' THEN 8
 WHEN 'HUMAN_APPROVED' THEN 9 WHEN 'COMMITTED' THEN 10 ELSE 99 END;
$$;

CREATE OR REPLACE FUNCTION enforce_candidate_stage_transition() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE current_s candidate_stage_code; expected_rank integer; prov provenance_events%ROWTYPE;
BEGIN
 SELECT current_stage INTO current_s FROM candidate_records WHERE candidate_id=NEW.candidate_id FOR UPDATE;
 IF current_s IS NULL THEN RAISE EXCEPTION 'candidate stage transition requires existing candidate'; END IF;
 IF NEW.from_stage IS DISTINCT FROM current_s THEN RAISE EXCEPTION 'candidate stage transition from_stage must match current stage'; END IF;
 IF NEW.to_stage NOT IN ('REJECTED','NEEDS_RESOLUTION') THEN
   expected_rank:=candidate_stage_rank(current_s)+1;
   IF candidate_stage_rank(NEW.to_stage)<>expected_rank THEN RAISE EXCEPTION 'candidate stage transition cannot skip canonical ingestion gates'; END IF;
 END IF;
 SELECT * INTO prov FROM provenance_events WHERE provenance_event_id=NEW.provenance_event_id;
 IF prov.provenance_event_id IS NULL OR prov.actor_type IS DISTINCT FROM NEW.actor_type OR prov.actor_identity IS DISTINCT FROM NEW.actor_identity
 THEN RAISE EXCEPTION 'candidate stage transition requires matching provenance actor'; END IF;
 IF NEW.to_stage='STRUCTURALLY_VALIDATED' AND NOT EXISTS (SELECT 1 FROM candidate_validations WHERE candidate_id=NEW.candidate_id AND validation_kind='STRUCTURAL' AND result='PASS') THEN RAISE EXCEPTION 'structural validation PASS required'; END IF;
 IF NEW.to_stage='PROVENANCE_VALIDATED' AND NOT EXISTS (SELECT 1 FROM candidate_validations WHERE candidate_id=NEW.candidate_id AND validation_kind='PROVENANCE' AND result='PASS') THEN RAISE EXCEPTION 'provenance validation PASS required'; END IF;
 IF NEW.to_stage='DEDUPLICATED' AND NOT EXISTS (SELECT 1 FROM candidate_duplicate_checks WHERE candidate_id=NEW.candidate_id AND disposition='UNIQUE') THEN RAISE EXCEPTION 'unique duplicate check required'; END IF;
 IF NEW.to_stage='EVIDENCE_PROPOSED' AND NOT EXISTS (SELECT 1 FROM candidate_evidence_proposals WHERE candidate_id=NEW.candidate_id) THEN RAISE EXCEPTION 'evidence candidate proposal required'; END IF;
 IF NEW.to_stage='SCORING_PROPOSED' AND NOT EXISTS (SELECT 1 FROM candidate_score_proposals WHERE candidate_id=NEW.candidate_id) THEN RAISE EXCEPTION 'scoring candidate required'; END IF;
 IF NEW.to_stage='EPISTEMIC_EVALUATED' AND EXISTS (SELECT 1 FROM rules r WHERE r.severity IN ('ERROR','BLOCK') AND NOT EXISTS (SELECT 1 FROM candidate_rule_evaluations cre WHERE cre.candidate_id=NEW.candidate_id AND cre.rule_id=r.rule_id AND cre.result='PASS')) THEN RAISE EXCEPTION 'all active blocking epistemic rules require PASS'; END IF;
 IF NEW.to_stage='ADVERSARIAL_REVIEWED' AND NOT EXISTS (SELECT 1 FROM candidate_adversarial_reviews WHERE candidate_id=NEW.candidate_id AND decision='PASS') THEN RAISE EXCEPTION 'adversarial review PASS required'; END IF;
 IF NEW.to_stage='HUMAN_APPROVED' AND NOT EXISTS (SELECT 1 FROM approval_events ae WHERE ae.candidate_id=NEW.candidate_id AND ae.approval_scope='CANDIDATE_PROMOTION' AND ae.decision='APPROVE' AND ae.approver_actor_type='HUMAN') THEN RAISE EXCEPTION 'candidate promotion requires HUMAN approval'; END IF;
 IF NEW.to_stage='COMMITTED' AND NOT EXISTS (SELECT 1 FROM candidate_authoritative_commits cac WHERE cac.candidate_id=NEW.candidate_id) THEN RAISE EXCEPTION 'authoritative commit record required'; END IF;
 RETURN NEW;
END;$$;
CREATE TRIGGER candidate_stage_transition_gate BEFORE INSERT ON candidate_stage_events FOR EACH ROW EXECUTE FUNCTION enforce_candidate_stage_transition();

CREATE OR REPLACE FUNCTION apply_candidate_stage_transition() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN UPDATE candidate_records SET current_stage=NEW.to_stage WHERE candidate_id=NEW.candidate_id; RETURN NEW; END;$$;
CREATE TRIGGER candidate_stage_transition_apply AFTER INSERT ON candidate_stage_events FOR EACH ROW EXECUTE FUNCTION apply_candidate_stage_transition();

CREATE OR REPLACE FUNCTION enforce_candidate_proposal_source() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE candidate_source TEXT;
BEGIN SELECT source_id INTO candidate_source FROM candidate_records WHERE candidate_id=NEW.candidate_id;
 IF candidate_source IS DISTINCT FROM NEW.source_id THEN RAISE EXCEPTION 'candidate evidence proposal source must match candidate source'; END IF;
 RETURN NEW; END;$$;
CREATE TRIGGER candidate_evidence_proposal_source_gate BEFORE INSERT ON candidate_evidence_proposals FOR EACH ROW EXECUTE FUNCTION enforce_candidate_proposal_source();

CREATE OR REPLACE FUNCTION enforce_candidate_approval_scope() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE c candidate_records%ROWTYPE; expected_hash TEXT;
BEGIN
 IF NEW.approval_scope='CANDIDATE_PROMOTION' THEN
   SELECT * INTO c FROM candidate_records WHERE candidate_id=NEW.candidate_id;
   IF c.candidate_id IS NULL THEN RAISE EXCEPTION 'candidate promotion approval requires existing candidate'; END IF;
   IF c.current_stage<>'ADVERSARIAL_REVIEWED' THEN RAISE EXCEPTION 'candidate promotion approval requires completed adversarial review'; END IF;
   SELECT cep.payload_hash INTO expected_hash FROM candidate_evidence_proposals cep WHERE cep.candidate_id=NEW.candidate_id;
   IF expected_hash IS NULL OR NEW.scope_hash IS DISTINCT FROM expected_hash THEN RAISE EXCEPTION 'candidate promotion approval scope_hash must match evidence proposal payload'; END IF;
 END IF; RETURN NEW;
END;$$;
CREATE TRIGGER candidate_approval_scope_gate BEFORE INSERT ON approval_events FOR EACH ROW EXECUTE FUNCTION enforce_candidate_approval_scope();

CREATE OR REPLACE FUNCTION enforce_candidate_authoritative_commit() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE c candidate_records%ROWTYPE; ae approval_events%ROWTYPE; e evidence%ROWTYPE; cep candidate_evidence_proposals%ROWTYPE;
BEGIN
 SELECT * INTO c FROM candidate_records WHERE candidate_id=NEW.candidate_id;
 SELECT * INTO ae FROM approval_events WHERE approval_event_id=NEW.approval_event_id;
 SELECT * INTO e FROM evidence WHERE evidence_id=NEW.evidence_id;
 SELECT * INTO cep FROM candidate_evidence_proposals WHERE candidate_id=NEW.candidate_id;
 IF c.current_stage<>'HUMAN_APPROVED' THEN RAISE EXCEPTION 'authoritative commit requires HUMAN_APPROVED candidate stage'; END IF;
 IF ae.approval_scope<>'CANDIDATE_PROMOTION' OR ae.decision<>'APPROVE' OR ae.approver_actor_type<>'HUMAN' OR ae.candidate_id IS DISTINCT FROM NEW.candidate_id THEN RAISE EXCEPTION 'authoritative commit requires exact HUMAN candidate promotion approval'; END IF;
 IF e.evidence_id IS NULL OR e.source_id IS DISTINCT FROM c.source_id OR e.evidence_id IS DISTINCT FROM cep.proposed_evidence_id THEN RAISE EXCEPTION 'authoritative commit evidence must match approved candidate proposal'; END IF;
 RETURN NEW; END;$$;
CREATE TRIGGER candidate_authoritative_commit_gate BEFORE INSERT ON candidate_authoritative_commits FOR EACH ROW EXECUTE FUNCTION enforce_candidate_authoritative_commit();

ALTER TABLE approval_events DROP CONSTRAINT approval_scope_target_check;
ALTER TABLE approval_events ADD CONSTRAINT approval_scope_target_check CHECK (
 (approval_scope='CANDIDATE_DISPOSITION' AND candidate_id IS NOT NULL AND evidence_id IS NULL AND score_change_id IS NULL AND release_id IS NULL) OR
 (approval_scope='CANDIDATE_PROMOTION' AND candidate_id IS NOT NULL AND evidence_id IS NULL AND score_change_id IS NULL AND release_id IS NULL) OR
 (approval_scope='EVIDENCE_PROMOTION' AND evidence_id IS NOT NULL AND candidate_id IS NULL AND score_change_id IS NULL AND release_id IS NULL) OR
 (approval_scope='SCORE_CHANGE' AND score_change_id IS NOT NULL AND candidate_id IS NULL AND release_id IS NULL) OR
 (approval_scope='INTERPRETATION_APPROVAL' AND claim_id IS NOT NULL AND evidence_id IS NOT NULL AND candidate_id IS NULL AND score_change_id IS NULL AND release_id IS NULL) OR
 (approval_scope='RELEASE_CERTIFICATION' AND release_id IS NOT NULL AND candidate_id IS NULL AND score_change_id IS NULL) OR
 (approval_scope IN ('SOURCE_CLOSURE','CLAIM_REVISION') AND candidate_id IS NULL AND score_change_id IS NULL AND release_id IS NULL));

CREATE VIEW candidate_pipeline_status AS
SELECT c.candidate_id,c.source_id,c.current_stage,c.extractor_identity,c.extractor_version,c.created_at,
 EXISTS(SELECT 1 FROM candidate_validations v WHERE v.candidate_id=c.candidate_id AND v.validation_kind='STRUCTURAL' AND v.result='PASS') AS structural_valid,
 EXISTS(SELECT 1 FROM candidate_validations v WHERE v.candidate_id=c.candidate_id AND v.validation_kind='PROVENANCE' AND v.result='PASS') AS provenance_valid,
 EXISTS(SELECT 1 FROM candidate_duplicate_checks d WHERE d.candidate_id=c.candidate_id AND d.disposition='UNIQUE') AS duplicate_cleared,
 EXISTS(SELECT 1 FROM candidate_evidence_proposals ep WHERE ep.candidate_id=c.candidate_id) AS evidence_proposed,
 EXISTS(SELECT 1 FROM candidate_score_proposals sp WHERE sp.candidate_id=c.candidate_id) AS score_proposed,
 EXISTS(SELECT 1 FROM candidate_adversarial_reviews ar WHERE ar.candidate_id=c.candidate_id AND ar.decision='PASS') AS adversarial_passed,
 EXISTS(SELECT 1 FROM approval_events ae WHERE ae.candidate_id=c.candidate_id AND ae.approval_scope='CANDIDATE_PROMOTION' AND ae.decision='APPROVE') AS human_approved,
 EXISTS(SELECT 1 FROM candidate_authoritative_commits ac WHERE ac.candidate_id=c.candidate_id) AS committed
FROM candidate_records c;

CREATE INDEX idx_candidate_stage_events_candidate ON candidate_stage_events(candidate_id,created_at);
CREATE INDEX idx_candidate_validations_candidate ON candidate_validations(candidate_id,validation_kind,result);
CREATE INDEX idx_candidate_duplicate_checks_candidate ON candidate_duplicate_checks(candidate_id,disposition);
CREATE INDEX idx_candidate_rule_evaluations_candidate ON candidate_rule_evaluations(candidate_id,result);
CREATE INDEX idx_candidate_adversarial_candidate ON candidate_adversarial_reviews(candidate_id,decision);

GRANT SELECT ON candidate_stage_events,candidate_validations,candidate_duplicate_checks,candidate_evidence_proposals,candidate_score_proposals,candidate_rule_evaluations,candidate_adversarial_reviews,candidate_authoritative_commits,candidate_pipeline_status TO cee_app_read,cee_ingest,cee_review,cee_approve,cee_release;
GRANT INSERT ON candidate_stage_events,candidate_validations,candidate_duplicate_checks,candidate_evidence_proposals,candidate_score_proposals,candidate_rule_evaluations TO cee_ingest;
GRANT INSERT ON candidate_adversarial_reviews TO cee_review;
GRANT INSERT ON candidate_authoritative_commits TO cee_approve;

COMMIT;
