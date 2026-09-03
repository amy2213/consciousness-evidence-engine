-- Phase 10: measurement layer. Measurements are modeled independently from interpretation.
BEGIN;

CREATE TYPE measurement_type_code AS ENUM (
  'BEHAVIORAL_RESPONSIVENESS','IMMEDIATE_REPORT','DELAYED_REPORT','CONFIDENCE','MEMORY',
  'NEURAL_DECODING','PERTURBATIONAL_COMPLEXITY','RECURRENCE','BROADCAST','FIELD_PATTERN',
  'CONNECTIVITY','PHYSIOLOGICAL_SIGNAL','MODEL_DERIVED','OTHER'
);
CREATE TYPE operational_target_code AS ENUM (
  'CONSCIOUSNESS_STATE','CONSCIOUS_CONTENT','ACCESS','REPORT','MEMORY','METACOGNITION',
  'CAUSAL_INTEGRATION','BOUNDARY','SUBSTRATE_MECHANISM','GENERAL_COGNITION','OTHER','UNRESOLVED'
);
CREATE TYPE task_report_dependence_code AS ENUM (
  'TASK_FREE','ACTIVE_TASK','PASSIVE','IMMEDIATE_REPORT','DELAYED_REPORT','NO_REPORT','MIXED','UNRESOLVED'
);
CREATE TYPE consciousness_specificity_code AS ENUM ('NONE','INDIRECT','CANDIDATE','VALIDATED','UNRESOLVED');
CREATE TYPE measurement_causal_status_code AS ENUM ('OBSERVATIONAL','PERTURBATIONAL','CAUSAL_MANIPULATION','METHODOLOGICAL','UNRESOLVED');
CREATE TYPE measurement_replication_status_code AS ENUM ('NONE_REPORTED','PREREGISTERED','INDEPENDENT_REPLICATION','BOTH','ND');

ALTER TABLE measurements
  ALTER COLUMN measurement_type DROP NOT NULL,
  ADD COLUMN measurement_type_code measurement_type_code NOT NULL DEFAULT 'OTHER',
  ADD COLUMN operational_target operational_target_code NOT NULL DEFAULT 'UNRESOLVED',
  ADD COLUMN acquisition_modality TEXT,
  ADD COLUMN timing TEXT,
  ADD COLUMN task_report_dependence task_report_dependence_code NOT NULL DEFAULT 'UNRESOLVED',
  ADD COLUMN state_sensitive tri_state_code NOT NULL DEFAULT 'ND',
  ADD COLUMN content_sensitive tri_state_code NOT NULL DEFAULT 'ND',
  ADD COLUMN validation_context_id TEXT REFERENCES evaluation_contexts(evaluation_context_id) ON DELETE RESTRICT,
  ADD COLUMN consciousness_specificity consciousness_specificity_code NOT NULL DEFAULT 'UNRESOLVED',
  ADD COLUMN consciousness_specificity_rationale TEXT NOT NULL DEFAULT 'Not established by the source-locked record.',
  ADD COLUMN causal_status measurement_causal_status_code NOT NULL DEFAULT 'UNRESOLVED',
  ADD COLUMN replication_status measurement_replication_status_code NOT NULL DEFAULT 'ND',
  ADD COLUMN legacy_operational_class TEXT;

CREATE TABLE measurement_confounds (
  measurement_id TEXT NOT NULL REFERENCES measurements(measurement_id) ON DELETE RESTRICT,
  confound TEXT NOT NULL,
  mitigation TEXT,
  ordinal SMALLINT NOT NULL CHECK (ordinal > 0),
  PRIMARY KEY (measurement_id,ordinal),
  CHECK (btrim(confound) <> '')
);

-- A measurement can be consciousness-sensitive without being a theory-neutral consciousness criterion.
-- VALIDATED is reserved for records with an explicit validation context and rationale.
CREATE OR REPLACE FUNCTION enforce_measurement_specificity_boundary()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.consciousness_specificity='VALIDATED' THEN
    IF NEW.validation_context_id IS NULL OR btrim(COALESCE(NEW.consciousness_specificity_rationale,''))='' THEN
      RAISE EXCEPTION 'validated consciousness specificity requires validation context and rationale';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER measurements_specificity_gate
BEFORE INSERT OR UPDATE OF consciousness_specificity,validation_context_id,consciousness_specificity_rationale ON measurements
FOR EACH ROW EXECUTE FUNCTION enforce_measurement_specificity_boundary();

COMMENT ON TABLE measurements IS
'Measurement definitions and measurement properties. A measurement is not, by itself, an interpretation or proof of consciousness.';
COMMENT ON COLUMN measurements.consciousness_specificity IS
'How specifically the measurement has been validated for consciousness inference. Interesting neural or behavioral variables are not automatically consciousness measurements.';
COMMENT ON COLUMN evidence.measured_variable IS
'Frozen v1.1.1 compatibility text. Canonical measurement representation lives in measurements/evidence_measurements.';
COMMENT ON COLUMN evidence.operational_class IS
'Frozen v1.1.1 compatibility text. Canonical measurement representation lives in measurements/evidence_measurements.';

CREATE INDEX idx_measurements_type ON measurements(measurement_type_code);
CREATE INDEX idx_measurements_target ON measurements(operational_target);
CREATE INDEX idx_measurements_specificity ON measurements(consciousness_specificity);
GRANT SELECT ON measurements,evidence_measurements,measurement_confounds TO cee_app_read,cee_ingest,cee_review,cee_approve,cee_release;

COMMIT;
