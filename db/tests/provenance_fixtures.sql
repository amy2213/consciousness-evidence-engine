-- Phase 13 isolated provenance fixtures used by positive and hostile tests.

INSERT INTO source_locators(source_locator_id,source_id,work_id,locator_type,locator_text,content_hash)
VALUES ('00000000-0000-0000-0000-000000001301','SRC-001','WORK-001','OTHER','Test fixture exact locator','fixture-locator-hash');

INSERT INTO evidence_source_locations(evidence_id,source_locator_id,is_primary,rationale)
VALUES ('TEST-BASE-EVIDENCE','00000000-0000-0000-0000-000000001301',TRUE,'Phase 13 positive fixture locator.');
