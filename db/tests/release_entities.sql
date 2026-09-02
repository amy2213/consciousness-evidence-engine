-- Phase 5 specification/release invariants. Zero rows = pass.

SELECT 'MISSING_FROZEN_SPEC' AS violation, 'v1.1.1' AS detail
WHERE NOT EXISTS (
  SELECT 1 FROM specification_versions
  WHERE specification_version_id='v1.1.1'
    AND status='FROZEN'
    AND source_artifact='Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx'
);

SELECT 'CERTIFIED_RELEASE_WITHOUT_MANIFEST' AS violation, release_id AS detail
FROM dataset_releases
WHERE status IN ('CERTIFIED','PUBLISHED','SUPERSEDED')
  AND (manifest_hash IS NULL OR btrim(manifest_hash)='');

SELECT 'CERTIFIED_RELEASE_WITHOUT_HUMAN_APPROVAL' AS violation, dr.release_id AS detail
FROM dataset_releases dr
WHERE dr.status IN ('CERTIFIED','PUBLISHED','SUPERSEDED')
  AND NOT EXISTS (
    SELECT 1 FROM approval_events ae
    WHERE ae.release_id=dr.release_id
      AND ae.approval_scope='RELEASE_CERTIFICATION'
      AND ae.decision='APPROVE'
      AND ae.approver_actor_type='HUMAN'
      AND ae.entity_version=dr.specification_version_id
  );

SELECT 'RELEASE_MEMBER_EMPTY_HASH' AS violation, release_id || ':' || member_id AS detail
FROM release_membership WHERE btrim(content_hash)='';

SELECT 'SELF_SUPERSESSION' AS violation, release_id AS detail
FROM dataset_releases WHERE supersedes_release_id=release_id;

SELECT 'RESOLVED_ERRATUM_WITHOUT_TIMESTAMP' AS violation, erratum_id::text AS detail
FROM release_errata WHERE status='RESOLVED' AND resolved_at IS NULL;

-- Release role may construct release records but may not issue authoritative approvals.
SELECT 'RELEASE_ROLE_APPROVAL_AUTHORITY' AS violation, 'approval_events' AS detail
WHERE has_table_privilege('cee_release','approval_events','INSERT');

SELECT 'RELEASE_ROLE_MISSING_DRAFT_RIGHT' AS violation, v.table_name AS detail
FROM (VALUES ('dataset_releases'),('release_membership'),('release_errata')) v(table_name)
WHERE NOT has_table_privilege('cee_release',v.table_name,'INSERT');
