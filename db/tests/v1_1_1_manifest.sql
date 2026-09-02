-- Run after the v1.1.1 canonical claim import.
-- Any row returned is a migration failure.

-- Exactly 27 frozen claim snapshots.
SELECT 'baseline_claim_count' AS violation
WHERE (SELECT count(*) FROM claim_baseline_snapshots WHERE ledger_version='v1.1.1') <> 27;

-- Operational claim scores must reproduce the immutable baseline exactly at import time.
SELECT 'score_mismatch:' || c.claim_id AS violation
FROM claims c
JOIN claim_baseline_snapshots b ON b.claim_id=c.claim_id AND b.ledger_version='v1.1.1'
WHERE c.ps<>b.ps OR c.ed<>b.ed OR c.ci<>b.ci OR c.ir<>b.ir OR c.rd<>b.rd OR c.rr<>b.rr
   OR c.esi<>b.esi OR c.sti<>b.sti OR c.rps<>b.rps
   OR c.operational_feasibility<>b.operational_feasibility;

-- Every claim must have at least one normalized type and role.
SELECT 'missing_claim_type:' || c.claim_id AS violation
FROM claims c LEFT JOIN claim_claim_types ct ON ct.claim_id=c.claim_id
WHERE ct.claim_id IS NULL;

SELECT 'missing_theory_role:' || c.claim_id AS violation
FROM claims c LEFT JOIN claim_theory_roles cr ON cr.claim_id=c.claim_id
WHERE cr.claim_id IS NULL;

-- Compound source labels must survive as normalized junction rows, not slash strings.
SELECT 'EM-3_type_normalization' AS violation
WHERE (SELECT string_agg(claim_type::text,'/' ORDER BY ordinal) FROM claim_claim_types WHERE claim_id='EM-3') <> 'S/C';

SELECT 'OR-5_type_normalization' AS violation
WHERE (SELECT string_agg(claim_type::text,'/' ORDER BY ordinal) FROM claim_claim_types WHERE claim_id='OR-5') <> 'C/P';

SELECT 'IIT-3_role_normalization' AS violation
WHERE (SELECT string_agg(theory_role::text,'/' ORDER BY CASE theory_role WHEN 'GEN' THEN 1 WHEN 'PHEN' THEN 2 ELSE 99 END) FROM claim_theory_roles WHERE claim_id='IIT-3') <> 'GEN/PHEN';
