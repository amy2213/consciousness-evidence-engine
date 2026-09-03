-- Phase 7 hostile mutation test. Exact intended guard must reject history rewriting.
DO $$
DECLARE msg text;
BEGIN
  BEGIN
    UPDATE claim_score_snapshots SET rationale='tampered history'
    WHERE score_snapshot_id='00000000-0000-0000-0000-000000000701';
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS msg=MESSAGE_TEXT;
    IF position('claim_score_snapshots is append-only' in msg)=0 THEN
      RAISE EXCEPTION 'score-history mutation failed for wrong reason: %',msg;
    END IF;
    RAISE NOTICE 'PASS SCORE_HISTORY_IMMUTABILITY: %',msg;
    RETURN;
  END;
  RAISE EXCEPTION 'score-history mutation unexpectedly succeeded';
END $$;
