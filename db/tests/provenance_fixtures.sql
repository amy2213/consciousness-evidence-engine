-- Phase 13 isolated provenance fixtures loaded before positive approval tests.

INSERT INTO bibliographic_works(work_id,authors,title,venue,year,bibliographic_status,notes)
VALUES ('WORK-999','CI fixture','Disposable provenance work','CI',2026,'CLOSED','Test only.');
INSERT INTO source_works(source_id,work_id,ordinal,relationship)
VALUES ('SRC-999','WORK-999',1,'MEMBER');

INSERT INTO provenance_events(provenance_event_id,entity_type,entity_id,actor_type,actor_identity,action,metadata)
VALUES ('00000000-0000-0000-0000-000000001300','SOURCE_LOCATOR','TEST-BASE-EVIDENCE','SYSTEM','ci-provenance','FIXTURE_CREATE','{"fixture":true}'::jsonb);

INSERT INTO source_locators(source_locator_id,source_id,work_id,locator_type,locator_text,content_hash,provenance_event_id)
VALUES ('00000000-0000-0000-0000-000000001301','SRC-999','WORK-999','RESULT','Test fixture exact locator','fixture-locator-hash','00000000-0000-0000-0000-000000001300');

INSERT INTO evidence_source_locations(evidence_id,source_locator_id,is_primary,rationale)
VALUES ('TEST-BASE-EVIDENCE','00000000-0000-0000-0000-000000001301',TRUE,'Phase 13 positive fixture locator.');
