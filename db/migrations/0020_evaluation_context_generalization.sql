-- Phase 9: generalize legacy biological populations into evaluation contexts.
BEGIN;

CREATE TYPE evaluation_context_type_code AS ENUM (
  'HUMAN_STATE',
  'HUMAN_CLINICAL',
  'HUMAN_BOUNDARY_CASE',
  'HUMAN_DEVELOPMENTAL',
  'NONHUMAN_SPECIES',
  'EX_VIVO_NEURAL_SYSTEM',
  'ARTIFICIAL_SYSTEM',
  'SIMULATION',
  'SYNTHETIC_CONSTRUCT',
  'OTHER'
);

ALTER TABLE evaluation_contexts
  ADD COLUMN context_type evaluation_context_type_code,
  ADD COLUMN translation_framework TEXT,
  ADD COLUMN biological_population BOOLEAN NOT NULL DEFAULT FALSE;

-- Existing rows, if any, must be classified before the column becomes mandatory.
UPDATE evaluation_contexts
SET context_type = CASE context_class
  WHEN 'BIOLOGICAL' THEN 'HUMAN_STATE'::evaluation_context_type_code
  WHEN 'EX_VIVO' THEN 'EX_VIVO_NEURAL_SYSTEM'::evaluation_context_type_code
  WHEN 'ARTIFICIAL' THEN 'ARTIFICIAL_SYSTEM'::evaluation_context_type_code
  WHEN 'SIMULATION' THEN 'SIMULATION'::evaluation_context_type_code
  WHEN 'SYNTHETIC' THEN 'SYNTHETIC_CONSTRUCT'::evaluation_context_type_code
  ELSE 'OTHER'::evaluation_context_type_code
END
WHERE context_type IS NULL;

ALTER TABLE evaluation_contexts
  ALTER COLUMN context_type SET NOT NULL;

-- A legacy population pointer is permitted only for biological or ex-vivo migrated contexts.
ALTER TABLE evaluation_contexts ADD CONSTRAINT evaluation_context_legacy_population_scope_check CHECK (
  legacy_population_id IS NULL
  OR context_type IN ('HUMAN_STATE','HUMAN_CLINICAL','HUMAN_BOUNDARY_CASE','HUMAN_DEVELOPMENTAL','NONHUMAN_SPECIES','EX_VIVO_NEURAL_SYSTEM')
);

-- Nonbiological context classes must not masquerade as biological populations.
ALTER TABLE evaluation_contexts ADD CONSTRAINT evaluation_context_nonbiological_check CHECK (
  context_type NOT IN ('ARTIFICIAL_SYSTEM','SIMULATION','SYNTHETIC_CONSTRUCT')
  OR (legacy_population_id IS NULL AND biological_population IS FALSE)
);

COMMENT ON TABLE populations IS
'Legacy biological/ex-vivo vocabulary retained for frozen v1.1.1 compatibility. New domain modeling uses evaluation_contexts.';
COMMENT ON COLUMN evidence.population_id IS
'Legacy v1.1.1 compatibility pointer. Canonical cross-domain context relationships live in evidence_evaluation_contexts.';

CREATE INDEX idx_evaluation_context_type ON evaluation_contexts(context_type);
GRANT SELECT ON evaluation_contexts,evidence_evaluation_contexts TO cee_app_read,cee_ingest,cee_review,cee_approve,cee_release;

COMMIT;
