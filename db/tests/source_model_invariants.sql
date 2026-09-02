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

-- Cluster types must not masquerade as a single merged bibliographic record.
SELECT 'paired_cluster_without_multiple_works:' || s.source_id AS violation
FROM sources s
WHERE s.source_kind='PAIRED_CLUSTER'
  AND (SELECT count(*) FROM source_works sw WHERE sw.source_id=s.source_id) < 2;

-- Partial/open ledger entries cannot be silently upgraded by all child works being marked CLOSED
-- without an explicit later reconciliation process. This check flags the condition for review.
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
