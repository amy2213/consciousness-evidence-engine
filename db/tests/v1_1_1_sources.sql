-- v1.1.1 source registry reconciliation.
-- Every returned row is a migration failure.

SELECT 'source_count:' || count(*) AS violation
FROM sources
WHERE source_class='V1.1.1_LEDGER_SOURCE'
HAVING count(*) <> 78;

WITH expected AS (
    SELECT format('SRC-%s', lpad(n::text,3,'0')) AS source_id
    FROM generate_series(1,78) AS g(n)
)
SELECT 'missing_source:' || e.source_id AS violation
FROM expected e
LEFT JOIN sources s USING (source_id)
WHERE s.source_id IS NULL;

SELECT 'unexpected_source:' || s.source_id AS violation
FROM sources s
WHERE s.source_class='V1.1.1_LEDGER_SOURCE'
  AND s.source_id !~ '^SRC-(00[1-9]|0[1-6][0-9]|07[0-8])$';

SELECT 'missing_registry_text:' || source_id AS violation
FROM sources
WHERE source_class='V1.1.1_LEDGER_SOURCE'
  AND (registry_text IS NULL OR btrim(registry_text)='');

SELECT 'wrong_source_artifact:' || source_id AS violation
FROM sources
WHERE source_class='V1.1.1_LEDGER_SOURCE'
  AND source_artifact IS DISTINCT FROM 'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx';

SELECT 'partial_not_preserved:' || source_id AS violation
FROM sources
WHERE source_id IN ('SRC-043','SRC-052','SRC-054','SRC-067')
  AND closure_status <> 'PARTIAL';

SELECT 'unexpected_partial:' || source_id AS violation
FROM sources
WHERE source_id BETWEEN 'SRC-001' AND 'SRC-078'
  AND closure_status='PARTIAL'
  AND source_id NOT IN ('SRC-043','SRC-052','SRC-054','SRC-067');

SELECT 'src066_not_paired_cluster' AS violation
WHERE (SELECT source_kind FROM sources WHERE source_id='SRC-066') <> 'PAIRED_CLUSTER';

SELECT 'src067_not_umbrella_cluster' AS violation
WHERE (SELECT source_kind FROM sources WHERE source_id='SRC-067') <> 'UMBRELLA_CLUSTER';

SELECT 'src055_not_consensus' AS violation
WHERE (SELECT source_kind FROM sources WHERE source_id='SRC-055') <> 'CONSENSUS';

SELECT 'src062_not_review_report' AS violation
WHERE (SELECT source_kind FROM sources WHERE source_id='SRC-062') <> 'REVIEW_REPORT';

-- Known frozen bibliographic facts/uncertainties must survive migration exactly.
SELECT 'src013_doi_drift' AS violation
WHERE (SELECT notes FROM sources WHERE source_id='SRC-013') NOT ILIKE '%10.1080/17588921003632529%';

SELECT 'src052_partial_author_gap_lost' AS violation
WHERE NOT EXISTS (
    SELECT 1 FROM sources WHERE source_id='SRC-052'
      AND closure_status='PARTIAL'
      AND notes ILIKE '%author string not present%'
      AND notes ILIKE '%10.1093/cercor/bhad327%'
);

SELECT 'src054_partial_author_gap_lost' AS violation
WHERE NOT EXISTS (
    SELECT 1 FROM sources WHERE source_id='SRC-054'
      AND closure_status='PARTIAL'
      AND notes ILIKE '%author string not present%'
      AND notes ILIKE '%10.1093/nc/niag014%'
);

SELECT 'src067_promotion_guard_lost' AS violation
WHERE NOT EXISTS (
    SELECT 1 FROM sources WHERE source_id='SRC-067'
      AND closure_status='PARTIAL'
      AND notes ILIKE '%exact study-level source IDs required before any score promotion%'
);

SELECT 'orphan_source_work:' || sw.source_id || ':' || sw.work_id AS violation
FROM source_works sw
LEFT JOIN sources s ON s.source_id=sw.source_id
LEFT JOIN bibliographic_works w ON w.work_id=sw.work_id
WHERE s.source_id IS NULL OR w.work_id IS NULL;
