-- Phase 13 positive fixture construction. Assertions live in end_to_end_provenance_invariants.sql.

INSERT INTO provenance_events(provenance_event_id,entity_type,entity_id,actor_type,actor_identity,action,metadata)
VALUES ('00000000-0000-0000-0000-000000000802','CLAIM_EVIDENCE','TEST-CLAIM:TEST-BASE-EVIDENCE:test-positive','HUMAN','human-interpretation-reviewer','APPROVAL_REVIEW','{"fixture":true}'::jsonb);

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
