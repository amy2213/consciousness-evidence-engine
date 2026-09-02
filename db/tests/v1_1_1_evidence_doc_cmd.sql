-- Zero rows = pass. Reconcile v1.1.1 Section 24.1 and asymmetric grading rule.

SELECT 'doc_count' AS violation, count(*)::text AS detail
FROM evidence WHERE evidence_id LIKE 'DC-%'
HAVING count(*) <> 8;

WITH expected(evidence_id,source_id,cmc) AS (VALUES
 ('DC-001','SRC-029','3'),('DC-002','SRC-030','3'),('DC-003','SRC-031','3'),
 ('DC-004','SRC-032','3'),('DC-005','SRC-033','3'),('DC-006','SRC-034','3'),
 ('DC-007','SRC-035','3'),('DC-008','SRC-036','2')
)
SELECT 'doc_mapping' AS violation,
       e.evidence_id || ':' || coalesce(a.source_id,'MISSING') || ':' || coalesce(a.cmc::text,'MISSING') AS detail
FROM expected e
LEFT JOIN evidence a USING (evidence_id)
WHERE a.source_id IS DISTINCT FROM e.source_id OR a.cmc::text IS DISTINCT FROM e.cmc;

SELECT 'doc_population' AS violation, evidence_id AS detail
FROM evidence
WHERE evidence_id LIKE 'DC-%' AND population_id <> 'DOC_CMD';

SELECT 'doc_asymmetry_missing' AS violation, evidence_id AS detail
FROM evidence
WHERE evidence_id LIKE 'DC-%'
  AND (asymmetric_inference IS NOT TRUE OR negative_inference_cmc_cap IS DISTINCT FROM 1);

SELECT 'doc_source_locator' AS violation, evidence_id AS detail
FROM evidence
WHERE evidence_id LIKE 'DC-%'
  AND (ledger_version <> 'v1.1.1' OR source_locator <> 'Section 24.1');

SELECT 'doc_score_effect_normalization' AS violation, evidence_id AS detail
FROM evidence
WHERE evidence_id LIKE 'DC-%' AND score_effect <> 'NONE';

SELECT 'dc006_causal_cap' AS violation, evidence_id AS detail
FROM evidence
WHERE evidence_id='DC-006' AND (causal_manipulation <> 'FALSE' OR cmc::text <> '3');

SELECT 'negative_active_test_cap_violation' AS violation, evidence_id AS detail
FROM evidence
WHERE asymmetric_inference IS TRUE AND negative_inference_cmc_cap > 1;
