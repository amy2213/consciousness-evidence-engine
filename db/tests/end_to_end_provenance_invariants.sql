-- Phase 13 zero-row provenance assertions. Fixture construction lives in end_to_end_provenance.sql.

SELECT 'BROKEN_RELEASE_PROVENANCE_PATH' AS violation,release_id AS detail
FROM dataset_releases dr
WHERE dr.release_id='test-provenance-release'
AND NOT EXISTS (
 SELECT 1 FROM release_provenance_paths rpp
 WHERE rpp.release_id=dr.release_id
   AND rpp.claim_id='TEST-CLAIM'
   AND rpp.evidence_id='TEST-BASE-EVIDENCE'
   AND rpp.source_id='SRC-999'
   AND rpp.work_id='WORK-999'
   AND rpp.locator_text='Fixture result locator'
);

SELECT 'APPROVED_INTERPRETATION_HASH_DRIFT' AS violation,approved_interpretation_id::text AS detail
FROM approved_interpretations ai
WHERE ai.interpretation_hash IS DISTINCT FROM canonical_interpretation_hash(ai.claim_id,ai.evidence_id,ai.evaluation_version);

SELECT 'APPROVED_INTERPRETATION_WITHOUT_PRIMARY_LOCATOR' AS violation,ai.approved_interpretation_id::text AS detail
FROM approved_interpretations ai
WHERE NOT EXISTS (
 SELECT 1 FROM evidence_source_locations esl
 WHERE esl.evidence_id=ai.evidence_id AND esl.is_primary
);

SELECT 'ORPHAN_RELEASE_INTERPRETATION' AS violation,ri.release_id||':'||ri.approved_interpretation_id::text AS detail
FROM release_interpretations ri
LEFT JOIN approved_interpretations ai ON ai.approved_interpretation_id=ri.approved_interpretation_id
WHERE ai.approved_interpretation_id IS NULL;
