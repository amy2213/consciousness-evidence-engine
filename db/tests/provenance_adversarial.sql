-- Phase 13 hostile provenance tests.
DO $$
DECLARE msg text;
BEGIN
  BEGIN
    UPDATE source_locators SET locator_text='rewritten locator'
    WHERE source_locator_id='00000000-0000-0000-0000-000000001301';
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS msg=MESSAGE_TEXT;
    IF position('source_locators is append-only provenance state' in msg)=0 THEN
      RAISE EXCEPTION 'locator mutation failed for wrong reason: %',msg;
    END IF;
    RAISE NOTICE 'PASS PROVENANCE_LOCATOR_APPEND_ONLY: %',msg;
    RETURN;
  END;
  RAISE EXCEPTION 'source locator mutation unexpectedly succeeded';
END $$;

DO $$
DECLARE msg text;
BEGIN
  BEGIN
    UPDATE approved_interpretations SET interpretation_hash='tampered'
    WHERE approved_interpretation_id='00000000-0000-0000-0000-000000000813';
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS msg=MESSAGE_TEXT;
    IF position('approved_interpretations is append-only provenance state' in msg)=0 THEN
      RAISE EXCEPTION 'interpretation mutation failed for wrong reason: %',msg;
    END IF;
    RAISE NOTICE 'PASS APPROVED_INTERPRETATION_APPEND_ONLY: %',msg;
    RETURN;
  END;
  RAISE EXCEPTION 'approved interpretation mutation unexpectedly succeeded';
END $$;

DO $$
DECLARE msg text;
BEGIN
  BEGIN
    INSERT INTO evidence_source_locations(evidence_id,source_locator_id,is_primary,rationale)
    VALUES ('TEST-SEMANTIC-NULLS','00000000-0000-0000-0000-000000001301',FALSE,'hostile wrong-source link');
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS msg=MESSAGE_TEXT;
    IF position('evidence source locator must belong to the evidence source container' in msg)=0 THEN
      RAISE EXCEPTION 'source-container mismatch failed for wrong reason: %',msg;
    END IF;
    RAISE NOTICE 'PASS EVIDENCE_LOCATOR_SOURCE_MATCH: %',msg;
    RETURN;
  END;
  RAISE EXCEPTION 'wrong-source evidence locator unexpectedly succeeded';
END $$;
