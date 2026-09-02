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

SELECT 'partial_not_preserved:' || source_id AS violation
FROM sources
WHERE source_id IN ('SRC-043','SRC-052','SRC-054','SRC-067')
  AND closure_status <> 'PARTIAL';

SELECT 'src066_not_paired_cluster' AS violation
WHERE (SELECT source_kind FROM sources WHERE source_id='SRC-066') <> 'PAIRED_CLUSTER';

SELECT 'src067_not_umbrella_cluster' AS violation
WHERE (SELECT source_kind FROM sources WHERE source_id='SRC-067') <> 'UMBRELLA_CLUSTER';

SELECT 'src055_not_consensus' AS violation
WHERE (SELECT source_kind FROM sources WHERE source_id='SRC-055') <> 'CONSENSUS';

SELECT 'src062_not_review_report' AS violation
WHERE (SELECT source_kind FROM sources WHERE source_id='SRC-062') <> 'REVIEW_REPORT';

-- No bibliographic work is required yet for partial/cluster records. When works are added,
-- no orphan memberships are permitted.
SELECT 'orphan_source_work:' || sw.source_id || ':' || sw.work_id AS violation
FROM source_works sw
LEFT JOIN sources s ON s.source_id=sw.source_id
LEFT JOIN bibliographic_works w ON w.work_id=sw.work_id
WHERE s.source_id IS NULL OR w.work_id IS NULL;
