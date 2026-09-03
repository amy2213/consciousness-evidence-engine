-- Phase 8 relational-model invariants. Zero rows = pass.

-- Every canonical Phase 8 entity must exist.
WITH required(name) AS (VALUES
 ('evaluation_contexts'),('evidence_evaluation_contexts'),('measurements'),('evidence_measurements'),
 ('model_runs'),('candidate_model_runs'),('evidence_provenance_links'),('review_score_dimensions')
)
SELECT 'MISSING_RELATIONAL_ENTITY' AS violation,r.name AS detail
FROM required r
LEFT JOIN information_schema.tables t ON t.table_schema='public' AND t.table_name=r.name
WHERE t.table_name IS NULL;

-- The legacy JSON fields may remain for compatibility, but may not be authoritative.
SELECT 'APPROVED_JSON_SCORE_STATE' AS violation,claim_id||':'||evidence_id AS detail
FROM claim_evidence WHERE approved_score_change IS NOT NULL;

SELECT 'APPROVED_REVIEW_JSON_SCORE_STATE' AS violation,review_event_id::text AS detail
FROM review_events WHERE decision='APPROVED' AND structured_scores IS NOT NULL;

-- Relational links must never orphan.
SELECT 'ORPHAN_EVIDENCE_CONTEXT' AS violation,eec.evidence_id||':'||eec.evaluation_context_id AS detail
FROM evidence_evaluation_contexts eec
LEFT JOIN evidence e ON e.evidence_id=eec.evidence_id
LEFT JOIN evaluation_contexts ec ON ec.evaluation_context_id=eec.evaluation_context_id
WHERE e.evidence_id IS NULL OR ec.evaluation_context_id IS NULL;

SELECT 'ORPHAN_EVIDENCE_MEASUREMENT' AS violation,em.evidence_id||':'||em.measurement_id AS detail
FROM evidence_measurements em
LEFT JOIN evidence e ON e.evidence_id=em.evidence_id
LEFT JOIN measurements m ON m.measurement_id=em.measurement_id
WHERE e.evidence_id IS NULL OR m.measurement_id IS NULL;

SELECT 'ORPHAN_MODEL_RUN_LINK' AS violation,cmr.candidate_id::text||':'||cmr.model_run_id::text AS detail
FROM candidate_model_runs cmr
LEFT JOIN candidate_records c ON c.candidate_id=cmr.candidate_id
LEFT JOIN model_runs mr ON mr.model_run_id=cmr.model_run_id
WHERE c.candidate_id IS NULL OR mr.model_run_id IS NULL;

SELECT 'ORPHAN_EVIDENCE_PROVENANCE' AS violation,epl.evidence_id||':'||epl.provenance_event_id::text AS detail
FROM evidence_provenance_links epl
LEFT JOIN evidence e ON e.evidence_id=epl.evidence_id
LEFT JOIN provenance_events pe ON pe.provenance_event_id=epl.provenance_event_id
WHERE e.evidence_id IS NULL OR pe.provenance_event_id IS NULL;

-- One evidence row may have many contexts, but never more than one declared primary context.
SELECT 'MULTIPLE_PRIMARY_CONTEXTS' AS violation,evidence_id AS detail
FROM evidence_evaluation_contexts WHERE is_primary GROUP BY evidence_id HAVING count(*)>1;

-- No stored theory-level aggregate truth score is allowed.
SELECT 'THEORY_LEVEL_SCORE_COLUMN' AS violation,column_name AS detail
FROM information_schema.columns
WHERE table_schema='public' AND table_name IN ('theories','theory_versions')
AND lower(column_name) IN ('score','confidence','esi','sti','rps');
