-- Zero rows = pass. Reconcile frozen anesthesia + sleep atomic evidence.

SELECT 'atomic_evidence_count' AS violation, count(*)::text AS detail
FROM evidence
WHERE evidence_id ~ '^(AN|SL)-[0-9]{3}$'
HAVING count(*) <> 14;

SELECT 'anesthesia_count' AS violation, count(*)::text AS detail
FROM evidence
WHERE evidence_id ~ '^AN-[0-9]{3}$'
HAVING count(*) <> 6;

SELECT 'sleep_count' AS violation, count(*)::text AS detail
FROM evidence
WHERE evidence_id ~ '^SL-[0-9]{3}$'
HAVING count(*) <> 8;

SELECT 'wrong_population' AS violation, evidence_id || ':' || population_id AS detail
FROM evidence
WHERE (evidence_id LIKE 'AN-%' AND population_id <> 'ANESTHESIA')
   OR (evidence_id LIKE 'SL-%' AND population_id <> 'SLEEP');

SELECT 'missing_source' AS violation, e.evidence_id || ':' || e.source_id AS detail
FROM evidence e
LEFT JOIN sources s ON s.source_id = e.source_id
WHERE e.evidence_id ~ '^(AN|SL)-[0-9]{3}$' AND s.source_id IS NULL;

SELECT 'missing_ledger_contract' AS violation, evidence_id AS detail
FROM evidence
WHERE evidence_id ~ '^(AN|SL)-[0-9]{3}$'
  AND (ledger_version <> 'v1.1.1'
       OR source_artifact IS NULL
       OR source_locator IS NULL
       OR ledger_score_effect_text IS NULL
       OR ledger_interpretation IS NULL
       OR operational_class IS NULL
       OR finding IS NULL);

SELECT 'score_mutation_leak' AS violation, evidence_id || ':' || score_effect::text AS detail
FROM evidence
WHERE evidence_id ~ '^(AN|SL)-[0-9]{3}$'
  AND score_effect <> 'NONE';

SELECT 'cmc_mismatch' AS violation, evidence_id || ':' || cmc::text AS detail
FROM evidence
WHERE (evidence_id, cmc::text) NOT IN (
 ('AN-001','3'),('AN-002','2'),('AN-003','2'),('AN-004','3'),('AN-005','2'),('AN-006','0'),
 ('SL-001','3'),('SL-002','3'),('SL-003','2'),('SL-004','2'),('SL-005','3'),('SL-006','3'),('SL-007','1'),('SL-008','2')
)
AND evidence_id ~ '^(AN|SL)-[0-9]{3}$';

SELECT 'source_mismatch' AS violation, evidence_id || ':' || source_id AS detail
FROM evidence
WHERE (evidence_id, source_id) NOT IN (
 ('AN-001','SRC-015'),('AN-002','SRC-016'),('AN-003','SRC-017'),('AN-004','SRC-018'),('AN-005','SRC-019'),('AN-006','SRC-020'),
 ('SL-001','SRC-021'),('SL-002','SRC-022'),('SL-003','SRC-023'),('SL-004','SRC-024'),('SL-005','SRC-025'),('SL-006','SRC-026'),('SL-007','SRC-028'),('SL-008','SRC-027')
)
AND evidence_id ~ '^(AN|SL)-[0-9]{3}$';

SELECT 'cmc0_consciousness_laundering' AS violation, evidence_id AS detail
FROM evidence
WHERE evidence_id = 'AN-006'
  AND ledger_score_effect_text NOT ILIKE '%no consciousness-dependent variable%';

-- AN-006 has a real intervention, but only at the substrate-mechanism level.
SELECT 'an006_causal_scope' AS violation, evidence_id AS detail
FROM evidence
WHERE evidence_id='AN-006'
  AND (causal_manipulation <> 'TRUE' OR causal_manipulation_scope <> 'SUBSTRATE_MECHANISM_ONLY');

-- No CMC0 substrate assay may masquerade as a consciousness-sensitive causal manipulation.
SELECT 'cmc0_consciousness_sensitive_scope' AS violation, evidence_id AS detail
FROM evidence
WHERE evidence_id ~ '^(AN|SL)-[0-9]{3}$'
  AND cmc='0' AND causal_manipulation_scope='CONSCIOUSNESS_SENSITIVE_VARIABLE';
