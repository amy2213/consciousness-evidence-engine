-- Post-migration assertions for a database that contained claims before migration 0003.
-- The companion harness creates TEST-UPGRADE-M and TEST-UPGRADE-P before 0003 runs.
-- Zero rows = pass.

SELECT 'UPGRADE_0003_LOOKUP_COUNT' AS violation, count(*)::text AS detail
FROM claim_types
HAVING count(*) <> 6;

SELECT 'UPGRADE_0003_MISSING_MEMBERSHIP' AS violation, expected.claim_id AS detail
FROM (VALUES
    ('TEST-UPGRADE-M'::text, 'M'::claim_type_code),
    ('TEST-UPGRADE-P'::text, 'P'::claim_type_code)
) AS expected(claim_id, claim_type)
LEFT JOIN claim_claim_types cct
  ON cct.claim_id = expected.claim_id
 AND cct.claim_type = expected.claim_type
 AND cct.ordinal = 1
WHERE cct.claim_id IS NULL;

SELECT 'UPGRADE_0003_LEGACY_COLUMN_REMAINS' AS violation, column_name AS detail
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'claims'
  AND column_name = 'claim_type';
