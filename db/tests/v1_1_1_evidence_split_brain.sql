-- Zero rows = pass. Exact v1.1.1 split-brain/hemispherectomy reconciliation.

-- Exact record count.
SELECT 'BD_COUNT' AS violation, count(*)::text AS detail
FROM evidence WHERE evidence_id LIKE 'BD-%'
HAVING count(*) <> 8;

-- Exact source + CMC mapping.
WITH expected(evidence_id,source_id,cmc) AS (VALUES
 ('BD-001','SRC-037','3'::scored_or_semantic_code),
 ('BD-002','SRC-038','3'::scored_or_semantic_code),
 ('BD-003','SRC-039','3'::scored_or_semantic_code),
 ('BD-004','SRC-040','2'::scored_or_semantic_code),
 ('BD-005','SRC-041','2'::scored_or_semantic_code),
 ('BD-006','SRC-042','3'::scored_or_semantic_code),
 ('BD-007','SRC-043','2'::scored_or_semantic_code),
 ('BD-008','SRC-044','1'::scored_or_semantic_code)
)
SELECT 'BD_MAPPING' AS violation, x.evidence_id AS detail
FROM expected x
LEFT JOIN evidence e USING (evidence_id)
WHERE e.evidence_id IS NULL OR e.source_id <> x.source_id OR e.cmc <> x.cmc;

SELECT 'BD_METADATA' AS violation, evidence_id AS detail
FROM evidence
WHERE evidence_id LIKE 'BD-%'
  AND (population_id <> 'SPLIT_BRAIN' OR ledger_version <> 'v1.1.1' OR source_locator <> 'Section 29.1');

SELECT 'UNITY_CLASS_COUNT' AS violation, count(*)::text AS detail
FROM unity_classes HAVING count(*) <> 5;

SELECT 'BD_MISSING_UNITY_LINK' AS violation, e.evidence_id AS detail
FROM evidence e
WHERE e.evidence_id LIKE 'BD-%'
  AND NOT EXISTS (SELECT 1 FROM evidence_unity_links u WHERE u.evidence_id=e.evidence_id);

-- No v1.1.1 boundary record establishes a bridge to phenomenal-subject unity.
SELECT 'ILLEGAL_PHENOMENAL_BRIDGE' AS violation, evidence_id || ':' || unity_class::text AS detail
FROM evidence_unity_links
WHERE evidence_id LIKE 'BD-%' AND bridge_to_phenomenal_established IS TRUE;

-- A phenomenal-subject link is permitted only as an explicit unresolved constraint/prediction here.
-- It must never be phrased as an established positive subject-count result while the bridge is false.
SELECT 'PHENOMENAL_LINK_OVERCLAIM' AS violation, evidence_id AS detail
FROM evidence_unity_links
WHERE evidence_id LIKE 'BD-%'
  AND unity_class='PHENOMENAL_SUBJECT'
  AND bridge_to_phenomenal_established IS FALSE
  AND relationship !~* '(unresolved|does not identify|unvalidated|constraint|prediction)';

SELECT 'BD001_PROMOTION' AS violation, unity_class::text AS detail
FROM evidence_unity_links
WHERE evidence_id='BD-001' AND unity_class='PHENOMENAL_SUBJECT';

SELECT 'BD002_ACCESS_MISSING' AS violation, 'BD-002' AS detail
WHERE NOT EXISTS (SELECT 1 FROM evidence_unity_links WHERE evidence_id='BD-002' AND unity_class='ACCESS');
SELECT 'BD002_AGENTIVE_MISSING' AS violation, 'BD-002' AS detail
WHERE NOT EXISTS (SELECT 1 FROM evidence_unity_links WHERE evidence_id='BD-002' AND unity_class='AGENTIVE');
SELECT 'BD002_PHENOMENAL_PROMOTION' AS violation, 'BD-002' AS detail
WHERE EXISTS (SELECT 1 FROM evidence_unity_links WHERE evidence_id='BD-002' AND unity_class='PHENOMENAL_SUBJECT');

-- Anatomical/network reorganization cannot be silently promoted into phenomenal subject evidence.
SELECT 'BD006_PHENOMENAL_PROMOTION' AS violation, 'BD-006' AS detail
WHERE EXISTS (SELECT 1 FROM evidence_unity_links WHERE evidence_id='BD-006' AND unity_class='PHENOMENAL_SUBJECT');

SELECT 'BD008_THEORY_BOUNDARY' AS violation, evidence_id AS detail
FROM evidence
WHERE evidence_id='BD-008' AND (source_id <> 'SRC-044' OR cmc <> '1'::scored_or_semantic_code);
