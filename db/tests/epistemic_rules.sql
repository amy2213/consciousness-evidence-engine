-- Phase 11 executable epistemic-rule invariants. Zero rows = pass.

-- Every active rule must carry the governance contract required by Phase 11.
SELECT 'RULE_GOVERNANCE_INCOMPLETE' AS violation,rule_id AS detail
FROM rules
WHERE rule_id BETWEEN 'R-001' AND 'R-015'
AND (btrim(COALESCE(expression,''))='' OR btrim(COALESCE(specification_reference,''))=''
     OR btrim(COALESCE(human_review_fallback,''))='' OR btrim(COALESCE(exact_failure_message,''))='');

-- All central Phase-11 prohibitions must exist.
WITH required(rule_id) AS (VALUES
 ('R-001'),('R-002'),('R-003'),('R-004'),('R-005'),('R-007'),('R-008'),('R-009'),('R-010'),('R-015')
)
SELECT 'MISSING_PHASE11_RULE' AS violation,r.rule_id AS detail
FROM required r LEFT JOIN rules x USING(rule_id) WHERE x.rule_id IS NULL;

-- Existing frozen baseline relations must remain conservative until explicitly reviewed.
SELECT 'BASELINE_INFERENCE_OVERPROMOTION' AS violation,claim_id||':'||evidence_id AS detail
FROM claim_evidence
WHERE evaluation_version='v1.1.1'
AND (inference_strength<>'UNRESOLVED' OR inference_target<>'UNRESOLVED'
     OR result_polarity<>'UNRESOLVED' OR component_scope_only IS FALSE
     OR synthetic_experience_bridge_established IS TRUE);

-- Whole-theory inference is structurally forbidden at the atomic claim/evidence layer.
SELECT 'WHOLE_THEORY_ATOMIC_INFERENCE' AS violation,claim_id||':'||evidence_id AS detail
FROM claim_evidence WHERE inference_target='WHOLE_THEORY' OR component_scope_only IS FALSE;

-- Synthetic experience claims require an explicit bridge even as stored state.
SELECT 'SYNTHETIC_EXPERIENCE_WITHOUT_BRIDGE' AS violation,ce.claim_id||':'||ce.evidence_id AS detail
FROM claim_evidence ce
WHERE ce.inference_target IN ('CONSCIOUSNESS','PHENOMENALITY')
AND ce.synthetic_experience_bridge_established IS FALSE
AND EXISTS (
 SELECT 1 FROM evidence_evaluation_contexts eec
 JOIN evaluation_contexts ec ON ec.evaluation_context_id=eec.evaluation_context_id
 WHERE eec.evidence_id=ce.evidence_id
 AND ec.context_type IN ('ARTIFICIAL_SYSTEM','SIMULATION','SYNTHETIC_CONSTRUCT')
);
