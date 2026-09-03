-- Phase 13 positive and reconciliation tests.

INSERT INTO bibliographic_works(work_id,authors,title,venue,year,bibliographic_status,notes)
VALUES ('WORK-999','CI fixture','Disposable provenance work','CI',2026,'CLOSED','Test only.');
INSERT INTO source_works(source_id,work_id,ordinal,relationship)
VALUES ('SRC-999','WORK-999',1,'MEMBER');

INSERT INTO provenance_events(provenance_event_id,entity_type,entity_id,actor_type,actor_identity,action,metadata)
VALUES
('00000000-0000-0000-0000-000000000801','SOURCE_LOCATOR','TEST-LOCATOR','SYSTEM','ci-provenance','FIXTURE_CREATE','{"fixture":true}'::jsonb),
('00000000-0000-0000-0000-000000000802','CLAIM_EVIDENCE','TEST-CLAIM:TEST-BASE-EVIDENCE:test-positive','HUMAN','human-interpretation-reviewer','APPROVAL_REVIEW','{"fixture":true}'::jsonb);

INSERT INTO source_locators(source_locator_id,source_id,work_id,locator_type,locator_text,content_hash,provenance_event_id)
VALUES ('00000000-0000-0000-0000-000000000811','SRC-999','WORK-999','RESULT','Fixture result locator','fixture-locator-hash','00000000-0000-0000-0000-000000000801');
INSERT INTO evidence_source_locations(evidence_id,source_locator_id,is_primary,rationale)
VALUES ('TEST-BASE-EVIDENCE','00000000-0000-0000-0000-000000000811',TRUE,'Exact CI work-level locator.');

INSERT INTO approval_events(
 approval_event_id,claim_id,evidence_id,decision,approver_identity,approver_actor_type,reviewer_role,
 approval_scope,entity_version,scope_hash,rationale,provenance_event_id
) VALUES (
 '00000000-0000-0000-0000-000000000812','TEST-CLAIM','TEST-BASE-EVIDENCE','APPROVE','human-interpretation-reviewer','HUMAN','APPROVER',
 'INTERPRETATION_APPROVAL','test-positive',canonical_interpretation_hash('TEST-CLAIM','TEST-BASE-EVIDENCE','test-positive'),
 'Exact interpretation approval fixture.','00000000-0000-0000-0000-000000000802');

INSERT INTO approved_interpretations(
 approved_interpretation_id,claim_id,evidence_id,evaluation_version,interpretation_hash,approval_event_id,provenance_event_id
) VALUES (
 '00000000-0000-0000-0000-000000000813','TEST-CLAIM','TEST-BASE-EVIDENCE','test-positive',
 canonical_interpretation_hash('TEST-CLAIM','TEST-BASE-EVIDENCE','test-positive'),
 '00000000-0000-0000-0000-000000000812','00000000-0000-0000-0000-000000000802');

INSERT INTO dataset_releases(release_id,specification_version_id,status,rationale)
VALUES ('test-provenance-release','test-positive','DRAFT','Disposable provenance chain fixture.');
INSERT INTO release_interpretations(release_id,approved_interpretation_id,ordinal)
VALUES ('test-provenance-release','00000000-0000-0000-0000-000000000813',1);

-- Zero rows = pass.
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
WHERE NOT EXISTS (SELECT 1 FROM evidence_source_locations esl WHERE esl.evidence_id=ai.evidence_id AND esl.is_primary);

SELECT 'ORPHAN_RELEASE_INTERPRETATION' AS violation,ri.release_id||':'||ri.approved_interpretation_id::text AS detail
FROM release_interpretations ri
LEFT JOIN approved_interpretations ai ON ai.approved_interpretation_id=ri.approved_interpretation_id
WHERE ai.approved_interpretation_id IS NULL;
