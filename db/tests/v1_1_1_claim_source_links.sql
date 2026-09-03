-- Any row returned is a migration failure.
SELECT 'claim_source_total_count' AS violation
WHERE (SELECT count(*) FROM claim_source_links WHERE ledger_version='v1.1.1') <> 128;

SELECT 'baseline_citation_count' AS violation
WHERE (SELECT count(*) FROM claim_source_links WHERE ledger_version='v1.1.1' AND link_kind='BASELINE_CITATION') <> 41;

SELECT 'accumulated_link_count' AS violation
WHERE (SELECT count(*) FROM claim_source_links WHERE ledger_version='v1.1.1' AND link_kind='ACCUMULATED_EVIDENCE_LINK') <> 87;

SELECT 'baseline_population_leak:' || claim_id || ':' || source_id AS violation
FROM claim_source_links
WHERE ledger_version='v1.1.1' AND link_kind='BASELINE_CITATION' AND population_id IS NOT NULL;

SELECT 'duplicate_claim_source_semantics:' || claim_id || ':' || source_id AS violation
FROM claim_source_links
WHERE ledger_version='v1.1.1'
GROUP BY claim_id,source_id
HAVING count(*) > 1;

SELECT 'orphan_claim_source_claim:' || l.claim_id AS violation
FROM claim_source_links l LEFT JOIN claims c ON c.claim_id=l.claim_id
WHERE c.claim_id IS NULL;

SELECT 'orphan_claim_source_source:' || l.source_id AS violation
FROM claim_source_links l LEFT JOIN sources s ON s.source_id=l.source_id
WHERE s.source_id IS NULL;

-- Canonical spot checks guarding historically important distinctions.
SELECT 'GNW-1_baseline_missing_SRC-001' AS violation
WHERE NOT EXISTS (SELECT 1 FROM claim_source_links WHERE ledger_version='v1.1.1' AND claim_id='GNW-1' AND source_id='SRC-001' AND link_kind='BASELINE_CITATION');
SELECT 'GNW-1_accumulated_missing_SRC-034' AS violation
WHERE NOT EXISTS (SELECT 1 FROM claim_source_links WHERE ledger_version='v1.1.1' AND claim_id='GNW-1' AND source_id='SRC-034' AND link_kind='ACCUMULATED_EVIDENCE_LINK');
SELECT 'HOT-1_baseline_missing_SRC-014' AS violation
WHERE NOT EXISTS (SELECT 1 FROM claim_source_links WHERE ledger_version='v1.1.1' AND claim_id='HOT-1' AND source_id='SRC-014' AND link_kind='BASELINE_CITATION');
SELECT 'OR-5_accumulated_missing_SRC-034' AS violation
WHERE NOT EXISTS (SELECT 1 FROM claim_source_links WHERE ledger_version='v1.1.1' AND claim_id='OR-5' AND source_id='SRC-034' AND link_kind='ACCUMULATED_EVIDENCE_LINK');
