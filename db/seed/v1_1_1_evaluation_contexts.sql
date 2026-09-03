-- Phase 9: lossless v1.1.1 population-to-context migration.
BEGIN;
INSERT INTO evaluation_contexts(
 evaluation_context_id,context_class,context_type,name,description,legacy_population_id,
 translation_framework,biological_population
)
SELECT
 'CTX-'||p.population_id,
 CASE WHEN p.population_id='EX_VIVO' THEN 'EX_VIVO'::evaluation_context_class_code ELSE 'BIOLOGICAL'::evaluation_context_class_code END,
 CASE p.population_id
  WHEN 'ANESTHESIA' THEN 'HUMAN_STATE'::evaluation_context_type_code
  WHEN 'SLEEP' THEN 'HUMAN_STATE'::evaluation_context_type_code
  WHEN 'DOC_CMD' THEN 'HUMAN_CLINICAL'::evaluation_context_type_code
  WHEN 'SPLIT_BRAIN' THEN 'HUMAN_BOUNDARY_CASE'::evaluation_context_type_code
  WHEN 'DEVELOPMENT' THEN 'HUMAN_DEVELOPMENTAL'::evaluation_context_type_code
  WHEN 'NONHUMAN_ANIMAL' THEN 'NONHUMAN_SPECIES'::evaluation_context_type_code
  WHEN 'EX_VIVO' THEN 'EX_VIVO_NEURAL_SYSTEM'::evaluation_context_type_code
 END,
 p.name,p.description,p.population_id,p.translation_framework,
 CASE WHEN p.population_id='EX_VIVO' THEN FALSE ELSE TRUE END
FROM populations p
WHERE p.population_id IN ('ANESTHESIA','SLEEP','DOC_CMD','SPLIT_BRAIN','DEVELOPMENT','NONHUMAN_ANIMAL','EX_VIVO')
ON CONFLICT (evaluation_context_id) DO NOTHING;

-- Every already-migrated evidence row inherits its exact legacy population as its primary context.
INSERT INTO evidence_evaluation_contexts(evidence_id,evaluation_context_id,is_primary,rationale)
SELECT e.evidence_id,'CTX-'||e.population_id,TRUE,
       'Lossless migration from frozen v1.1.1 evidence.population_id.'
FROM evidence e
WHERE e.population_id IS NOT NULL
ON CONFLICT (evidence_id,evaluation_context_id) DO NOTHING;
COMMIT;
