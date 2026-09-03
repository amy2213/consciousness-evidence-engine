-- Phase 12 structural conformance. Zero rows = pass.

-- All active executable rules require governance metadata.
SELECT 'RULE_METADATA_INCOMPLETE' AS violation,rule_id AS detail
FROM rules
WHERE active_from_version='v1.1.1'
AND (btrim(COALESCE(expression,''))='' OR btrim(COALESCE(rationale,''))=''
 OR btrim(COALESCE(specification_reference,''))='' OR btrim(COALESCE(human_review_fallback,''))=''
 OR btrim(COALESCE(exact_failure_message,''))='');

-- The central Phase 11 rule registry must be complete.
WITH required(rule_id) AS (VALUES
 ('R-001'),('R-002'),('R-003'),('R-004'),('R-005'),('R-006'),('R-007'),('R-008'),('R-009'),('R-010'),('R-011'),('R-012'),('R-013'),('R-014'),('R-015')
)
SELECT 'MISSING_RULE' AS violation,r.rule_id AS detail
FROM required r LEFT JOIN rules x ON x.rule_id=r.rule_id WHERE x.rule_id IS NULL;

-- Frozen canonical claim-evidence remains conservative until explicitly reviewed.
SELECT 'BASELINE_SILENT_INFERENCE_PROMOTION' AS violation,claim_id||':'||evidence_id||':'||evaluation_version AS detail
FROM claim_evidence
WHERE evaluation_version='v1.1.1'
AND (inference_strength<>'UNRESOLVED' OR inference_target<>'UNRESOLVED' OR result_polarity<>'UNRESOLVED' OR component_scope_only IS FALSE OR synthetic_experience_bridge_established IS TRUE);

-- No theory-level aggregate truth score may appear while conformance fixtures run.
SELECT 'THEORY_SCORE_REINTRODUCED' AS violation,column_name AS detail
FROM information_schema.columns
WHERE table_schema='public' AND table_name IN ('theories','theory_versions')
AND lower(column_name) IN ('score','confidence','esi','sti','rps','probability');
