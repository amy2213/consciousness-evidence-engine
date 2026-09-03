-- Phase 9 evaluation-context invariants. Zero rows = pass.

SELECT 'BASELINE_CONTEXT_COUNT' AS violation,count(*)::text AS detail
FROM evaluation_contexts WHERE legacy_population_id IS NOT NULL HAVING count(*)<>7;

-- Exact legacy semantics must survive migration.
SELECT 'BASELINE_CONTEXT_SEMANTIC_LOSS' AS violation,p.population_id AS detail
FROM populations p
LEFT JOIN evaluation_contexts ec ON ec.legacy_population_id=p.population_id
WHERE p.population_id IN ('ANESTHESIA','SLEEP','DOC_CMD','SPLIT_BRAIN','DEVELOPMENT','NONHUMAN_ANIMAL','EX_VIVO')
AND (ec.evaluation_context_id IS NULL OR ec.name IS DISTINCT FROM p.name
 OR ec.description IS DISTINCT FROM p.description
 OR ec.translation_framework IS DISTINCT FROM p.translation_framework);

-- Every legacy evidence row must resolve to exactly its migrated primary context.
SELECT 'EVIDENCE_CONTEXT_MIGRATION_LOSS' AS violation,e.evidence_id AS detail
FROM evidence e
WHERE e.population_id IS NOT NULL
AND NOT EXISTS (
 SELECT 1 FROM evidence_evaluation_contexts eec
 WHERE eec.evidence_id=e.evidence_id
   AND eec.evaluation_context_id='CTX-'||e.population_id
   AND eec.is_primary
);

-- Artificial/simulation/synthetic contexts are valid without a biological population row.
SELECT 'NONBIOLOGICAL_CONTEXT_MASQUERADE' AS violation,evaluation_context_id AS detail
FROM evaluation_contexts
WHERE context_type IN ('ARTIFICIAL_SYSTEM','SIMULATION','SYNTHETIC_CONSTRUCT')
AND (legacy_population_id IS NOT NULL OR biological_population);

-- Frozen seven get the intended semantic classes.
WITH expected(population_id,context_type,biological_population) AS (VALUES
 ('ANESTHESIA','HUMAN_STATE'::evaluation_context_type_code,TRUE),
 ('SLEEP','HUMAN_STATE'::evaluation_context_type_code,TRUE),
 ('DOC_CMD','HUMAN_CLINICAL'::evaluation_context_type_code,TRUE),
 ('SPLIT_BRAIN','HUMAN_BOUNDARY_CASE'::evaluation_context_type_code,TRUE),
 ('DEVELOPMENT','HUMAN_DEVELOPMENTAL'::evaluation_context_type_code,TRUE),
 ('NONHUMAN_ANIMAL','NONHUMAN_SPECIES'::evaluation_context_type_code,TRUE),
 ('EX_VIVO','EX_VIVO_NEURAL_SYSTEM'::evaluation_context_type_code,FALSE)
)
SELECT 'BASELINE_CONTEXT_CLASS_DRIFT' AS violation,x.population_id AS detail
FROM expected x JOIN evaluation_contexts ec ON ec.legacy_population_id=x.population_id
WHERE ec.context_type<>x.context_type OR ec.biological_population<>x.biological_population;
