-- Adversarial database fixtures
-- These tests intentionally attempt forbidden states.
-- Execute against a disposable test database after schema + migrations.

-- Test harness convention:
-- Each DO block must catch the expected exception. If the forbidden operation succeeds,
-- the block raises a test failure.

-- A1: CMC 4 without causal manipulation must fail.
DO $$
BEGIN
    BEGIN
        INSERT INTO evidence (
            evidence_id, source_id, population_id, finding,
            causal_manipulation, consciousness_sensitive_convergence,
            preregistered, independent_replication, cmc
        ) VALUES (
            'TEST-CMC4-NO-CAUSE', 'SRC-001', 'ANESTHESIA', 'fixture',
            FALSE, TRUE, 'TRUE', 'TRUE', '4'
        );
        RAISE EXCEPTION 'TEST FAILURE: CMC4 without causal manipulation was accepted';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE 'TEST FAILURE:%' THEN RAISE; END IF;
    END;
END $$;

-- A2: CMC 4 without consciousness-sensitive convergence must fail.
DO $$
BEGIN
    BEGIN
        INSERT INTO evidence (
            evidence_id, source_id, population_id, finding,
            causal_manipulation, consciousness_sensitive_convergence,
            preregistered, independent_replication, cmc
        ) VALUES (
            'TEST-CMC4-NO-CONV', 'SRC-001', 'ANESTHESIA', 'fixture',
            TRUE, FALSE, 'TRUE', 'TRUE', '4'
        );
        RAISE EXCEPTION 'TEST FAILURE: CMC4 without convergence was accepted';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE 'TEST FAILURE:%' THEN RAISE; END IF;
    END;
END $$;

-- A3: CMC 4 without preregistration or independent replication must fail.
DO $$
BEGIN
    BEGIN
        INSERT INTO evidence (
            evidence_id, source_id, population_id, finding,
            causal_manipulation, consciousness_sensitive_convergence,
            preregistered, independent_replication, cmc
        ) VALUES (
            'TEST-CMC4-NO-REP', 'SRC-001', 'ANESTHESIA', 'fixture',
            TRUE, TRUE, 'FALSE', 'FALSE', '4'
        );
        RAISE EXCEPTION 'TEST FAILURE: CMC4 without preregistration/replication was accepted';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE 'TEST FAILURE:%' THEN RAISE; END IF;
    END;
END $$;

-- A4: Approved evidence without approval event must fail at deferred constraint check.
DO $$
BEGIN
    BEGIN
        SET CONSTRAINTS evidence_requires_approval_event DEFERRED;
        INSERT INTO evidence (
            evidence_id, source_id, population_id, finding, evidence_status
        ) VALUES ('TEST-UNAPPROVED', 'SRC-001', 'ANESTHESIA', 'fixture', 'APPROVED');
        SET CONSTRAINTS evidence_requires_approval_event IMMEDIATE;
        RAISE EXCEPTION 'TEST FAILURE: approved evidence without approval event was accepted';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE 'TEST FAILURE:%' THEN RAISE; END IF;
    END;
END $$;

-- A5: Legacy approved-score JSON must fail.
DO $$
BEGIN
    BEGIN
        INSERT INTO claim_evidence (
            claim_id, evidence_id, evaluation_version, relationship,
            interpretation, approved_score_change, review_status
        ) VALUES (
            'GNW-1', 'TEST-BASE-EVIDENCE', 'test', 'SUPPORT',
            'fixture', '{"ED":4}'::jsonb, 'APPROVED'
        );
        RAISE EXCEPTION 'TEST FAILURE: authoritative score change was accepted in legacy JSON';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE 'TEST FAILURE:%' THEN RAISE; END IF;
    END;
END $$;

-- A6: Audit history must reject mutation.
DO $$
DECLARE aid BIGINT;
BEGIN
    INSERT INTO audit_log(entity_type, entity_id, action, reason, actor)
    VALUES ('TEST','TEST-1','CREATE','fixture','test-suite') RETURNING audit_id INTO aid;
    BEGIN
        UPDATE audit_log SET reason = 'rewritten history' WHERE audit_id = aid;
        RAISE EXCEPTION 'TEST FAILURE: audit_log update was accepted';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE 'TEST FAILURE:%' THEN RAISE; END IF;
    END;
END $$;

-- A7: Direct claim score mutation without approved proposal must fail.
DO $$
BEGIN
    BEGIN
        UPDATE claims SET ed = CASE WHEN ed < 4 THEN ed + 1 ELSE ed - 1 END
        WHERE claim_id = 'GNW-1';
        RAISE EXCEPTION 'TEST FAILURE: direct score mutation was accepted';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE 'TEST FAILURE:%' THEN RAISE; END IF;
    END;
END $$;

-- A8: Invalid semantic score is impossible at type level.
-- Dynamic SQL postpones enum parsing until the inner block so the error can be caught.
DO $$
BEGIN
    BEGIN
        EXECUTE $sql$INSERT INTO evidence(evidence_id, source_id, finding, cmc)
                     VALUES ('TEST-BAD-CMC','SRC-001','fixture','HIGH')$sql$;
        RAISE EXCEPTION 'TEST FAILURE: qualitative CMC was accepted';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE 'TEST FAILURE:%' THEN RAISE; END IF;
    END;
END $$;
