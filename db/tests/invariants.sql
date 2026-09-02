-- Read-only integrity checks. Each query should return zero rows unless noted.

-- 1. Orphan claim roles
SELECT ctr.*
FROM claim_theory_roles ctr
LEFT JOIN claims c ON c.claim_id = ctr.claim_id
WHERE c.claim_id IS NULL;

-- 2. Canonical source IDs must match SRC-### format (constraint should make this impossible).
SELECT source_id FROM sources WHERE source_id !~ '^SRC-[0-9]{3}$';

-- 3. Approved score changes without approval must never exist.
SELECT claim_id, evidence_id, evaluation_version
FROM claim_evidence
WHERE approved_score_change IS NOT NULL
  AND review_status <> 'APPROVED';

-- 4. CMC 4 requires an explicit TRUE causal-manipulation determination.
SELECT evidence_id
FROM evidence
WHERE cmc = '4' AND causal_manipulation <> 'TRUE';

-- 5. ESI/STI/RPS must equal their component formulas.
SELECT claim_id
FROM claims
WHERE esi <> ed + ci + ir + rd
   OR sti <> ps + rr
   OR rps <> ed + ci + ir + rd + ps + rr;

-- 6. Canonical evidence must resolve to a source.
SELECT e.evidence_id
FROM evidence e
LEFT JOIN sources s ON s.source_id = e.source_id
WHERE s.source_id IS NULL;

-- 7. Canonical claim-evidence links must resolve both sides.
SELECT ce.claim_id, ce.evidence_id
FROM claim_evidence ce
LEFT JOIN claims c ON c.claim_id = ce.claim_id
LEFT JOIN evidence e ON e.evidence_id = ce.evidence_id
WHERE c.claim_id IS NULL OR e.evidence_id IS NULL;

-- 8. Informational: score range sanity. Expected result: zero rows.
SELECT claim_id, esi, sti, rps
FROM claims
WHERE esi NOT BETWEEN 0 AND 16
   OR sti NOT BETWEEN 0 AND 8
   OR rps NOT BETWEEN 0 AND 24;
