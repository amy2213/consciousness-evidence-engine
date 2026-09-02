-- Source-model invariants. Any returned row is a failure after v1.1.1 migration.

-- Exactly 78 authoritative ledger source objects.
SELECT 'source_count' AS violation
WHERE (SELECT count(*) FROM sources WHERE source_id BETWEEN 'SRC-001' AND 'SRC-078') <> 78;

-- Sequence must be contiguous SRC-001 through SRC-078.
WITH expected AS (
    SELECT 'SRC-' || lpad(n::text,3,'0') AS source_id
    FROM generate_series(1,78) AS n
)
SELECT 'missing_source:' || e.source_id AS violation
FROM expected e
LEFT JOIN sources s USING (source_id)
WHERE s.source_id IS NULL;

-- Every normalized work member resolves.
SELECT 'orphan_source_work:' || sw.source_id || ':' || sw.work_id AS violation
FROM source_works sw
LEFT JOIN sources s ON s.source_id=sw.source_id
LEFT JOIN bibliographic_works w ON w.work_id=sw.work_id
WHERE s.source_id IS NULL OR w.work_id IS NULL;

-- Every frozen non-umbrella source must resolve to at least one normalized work.
SELECT 'source_without_work:' || s.source_id AS violation
FROM sources s
WHERE s.source_id BETWEEN 'SRC-001' AND 'SRC-078'
  AND s.source_kind <> 'UMBRELLA_CLUSTER'
  AND NOT EXISTS (SELECT 1 FROM source_works sw WHERE sw.source_id=s.source_id);

-- Ordinary single-work, partial-record, consensus and review/report containers must resolve to exactly one work.
SELECT 'single_container_wrong_cardinality:' || s.source_id AS violation
FROM sources s
WHERE s.source_id BETWEEN 'SRC-001' AND 'SRC-078'
  AND s.source_kind IN ('SINGLE_WORK','PARTIAL_RECORD','CONSENSUS','REVIEW_REPORT')
  AND (SELECT count(*) FROM source_works sw WHERE sw.source_id=s.source_id) <> 1;

-- Paired clusters must not masquerade as one merged bibliographic record.
SELECT 'paired_cluster_without_multiple_works:' || s.source_id AS violation
FROM sources s
WHERE s.source_kind='PAIRED_CLUSTER'
  AND (SELECT count(*) FROM source_works sw WHERE sw.source_id=s.source_id) < 2;

-- Frozen v1.1.1 has one paired cluster, SRC-066, and it must preserve both exact DOI-bearing works.
SELECT 'src066_wrong_cardinality' AS violation
WHERE (SELECT count(*) FROM source_works WHERE source_id='SRC-066') <> 2;

SELECT 'src066_missing_doi:' || required.doi AS violation
FROM (VALUES
    ('10.1098/rspb.2003.2349'::text),
    ('10.1067/S1526-5900(03)00717-X'::text)
) AS required(doi)
WHERE NOT EXISTS (
    SELECT 1
    FROM source_works sw
    JOIN bibliographic_works w ON w.work_id=sw.work_id
    WHERE sw.source_id='SRC-066' AND lower(w.doi)=lower(required.doi)
);

-- SRC-067 is intentionally unresolved. Inventing child works would falsely close the frozen umbrella cluster.
SELECT 'src067_must_remain_unresolved' AS violation
WHERE EXISTS (SELECT 1 FROM source_works WHERE source_id='SRC-067');

SELECT 'src067_not_partial' AS violation
WHERE NOT EXISTS (
    SELECT 1 FROM sources
    WHERE source_id='SRC-067'
      AND source_kind='UMBRELLA_CLUSTER'
      AND closure_status='PARTIAL'
);

-- No normalized DOI or PMID may silently identify multiple distinct work rows.
SELECT 'duplicate_doi:' || lower(doi) AS violation
FROM bibliographic_works
WHERE doi IS NOT NULL
GROUP BY lower(doi)
HAVING count(*) > 1;

SELECT 'duplicate_pmid:' || pmid AS violation
FROM bibliographic_works
WHERE pmid IS NOT NULL
GROUP BY pmid
HAVING count(*) > 1;

-- A CLOSED parent source cannot point to a non-closed child work.
SELECT 'closed_source_has_unclosed_work:' || s.source_id || ':' || w.work_id AS violation
FROM sources s
JOIN source_works sw ON sw.source_id=s.source_id
JOIN bibliographic_works w ON w.work_id=sw.work_id
WHERE s.closure_status='CLOSED'
  AND w.bibliographic_status <> 'CLOSED';

-- Partial/open ledger entries cannot be silently upgraded by all child works being marked CLOSED.
-- Such a condition is blocking because parent closure requires an explicit later reconciliation event.
SELECT 'closure_review_required:' || s.source_id AS violation
FROM sources s
WHERE s.closure_status IN ('PARTIAL','OPEN')
  AND EXISTS (SELECT 1 FROM source_works sw WHERE sw.source_id=s.source_id)
  AND NOT EXISTS (
      SELECT 1 FROM source_works sw
      JOIN bibliographic_works w ON w.work_id=sw.work_id
      WHERE sw.source_id=s.source_id AND w.bibliographic_status <> 'CLOSED'
  );

-- Baseline citations and accumulated links are explicitly typed.
SELECT 'untyped_claim_source_link' AS violation
FROM claim_source_links
WHERE link_kind IS NULL;
