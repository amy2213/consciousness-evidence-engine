-- Phase 11 hostile fixtures. Every attempted epistemic promotion must fail for the exact rule reason.
DO $$
DECLARE msg text;
BEGIN
  BEGIN
    UPDATE claim_evidence SET inference_strength='CAUSAL_CONTRIBUTION'
    WHERE claim_id='TEST-CLAIM' AND evidence_id='TEST-BASE-EVIDENCE' AND evaluation_version='test-positive';
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS msg=MESSAGE_TEXT;
    IF msg <> 'R-001 correlation cannot be promoted to causal inference without qualifying causal manipulation' THEN
      RAISE EXCEPTION 'R-001 failed for wrong reason: %',msg;
    END IF;
    RAISE NOTICE 'PASS R-001: %',msg;
    RETURN;
  END;
  RAISE EXCEPTION 'R-001 promotion unexpectedly succeeded';
END $$;

DO $$
DECLARE msg text;
BEGIN
  BEGIN
    UPDATE claim_evidence SET inference_target='WHOLE_THEORY'
    WHERE claim_id='TEST-CLAIM' AND evidence_id='TEST-BASE-EVIDENCE' AND evaluation_version='test-positive';
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS msg=MESSAGE_TEXT;
    IF msg <> 'R-005 component evidence cannot be promoted to confirmation of a whole theory' THEN
      RAISE EXCEPTION 'R-005 failed for wrong reason: %',msg;
    END IF;
    RAISE NOTICE 'PASS R-005: %',msg;
    RETURN;
  END;
  RAISE EXCEPTION 'R-005 promotion unexpectedly succeeded';
END $$;

DO $$
DECLARE msg text;
BEGIN
  BEGIN
    INSERT INTO evidence(
      evidence_id,source_id,population_id,finding,causal_manipulation,causal_manipulation_scope,
      consciousness_sensitive_convergence,preregistered,independent_replication,cmc,oec,evidence_status,ledger_version
    ) VALUES (
      'TEST-CMC4-R007','SRC-999','ANESTHESIA','Hostile CMC4 fixture.','FALSE','NONE',FALSE,'TRUE','TRUE','4','NA','VALIDATED','test-positive'
    );
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS msg=MESSAGE_TEXT;
    IF msg <> 'R-007 CMC 4 requires causal manipulation' THEN
      RAISE EXCEPTION 'R-007 failed for wrong reason: %',msg;
    END IF;
    RAISE NOTICE 'PASS R-007: %',msg;
    RETURN;
  END;
  RAISE EXCEPTION 'R-007 CMC4 bypass unexpectedly succeeded';
END $$;
