-- Adversarial database fixtures.
-- Every block passes only when the exact intended database guard rejects the hostile state.
-- Unexpected success or the wrong failure message fails CI.

CREATE OR REPLACE FUNCTION test_expect_failure(label text, sql_text text, expected_message text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE msg text;
BEGIN
    BEGIN EXECUTE sql_text;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS msg = MESSAGE_TEXT;
        IF position(expected_message in msg) = 0 THEN
            RAISE EXCEPTION 'adversarial test % failed for wrong reason: %', label, msg;
        END IF;
        RAISE NOTICE 'PASS %: %', label, msg; RETURN;
    END;
    RAISE EXCEPTION 'adversarial test % unexpectedly succeeded', label;
END;
$$;

SELECT test_expect_failure('A1_CMC4_NO_CAUSAL',
$q$INSERT INTO evidence (evidence_id,source_id,population_id,finding,causal_manipulation,causal_manipulation_scope,consciousness_sensitive_convergence,preregistered,independent_replication,cmc,oec,evidence_status) VALUES ('TEST-A1','SRC-999','ANESTHESIA','hostile','FALSE','NONE',TRUE,'TRUE','FALSE','4','NA','VALIDATED')$q$,
'CMC 4 requires causal manipulation');
SELECT test_expect_failure('A2_CMC4_NO_CONVERGENCE',
$q$INSERT INTO evidence (evidence_id,source_id,population_id,finding,causal_manipulation,causal_manipulation_scope,consciousness_sensitive_convergence,preregistered,independent_replication,cmc,oec,evidence_status) VALUES ('TEST-A2','SRC-999','ANESTHESIA','hostile','TRUE','CONSCIOUSNESS_SENSITIVE_VARIABLE',FALSE,'TRUE','FALSE','4','NA','VALIDATED')$q$,
'CMC 4 requires convergent consciousness-sensitive measurement');
SELECT test_expect_failure('A3_CMC4_NO_PREREG_REPLICATION',
$q$INSERT INTO evidence (evidence_id,source_id,population_id,finding,causal_manipulation,causal_manipulation_scope,consciousness_sensitive_convergence,preregistered,independent_replication,cmc,oec,evidence_status) VALUES ('TEST-A3','SRC-999','ANESTHESIA','hostile','TRUE','CONSCIOUSNESS_SENSITIVE_VARIABLE',TRUE,'FALSE','FALSE','4','NA','VALIDATED')$q$,
'CMC 4 requires preregistration or independent replication');
SELECT test_expect_failure('A4_CMC4_SUBSTRATE_ONLY',
$q$INSERT INTO evidence (evidence_id,source_id,population_id,finding,causal_manipulation,causal_manipulation_scope,consciousness_sensitive_convergence,preregistered,independent_replication,cmc,oec,evidence_status) VALUES ('TEST-A4','SRC-999','ANESTHESIA','hostile','TRUE','SUBSTRATE_MECHANISM_ONLY',TRUE,'TRUE','FALSE','4','NA','VALIDATED')$q$,
'CMC 4 requires causal manipulation of a consciousness-sensitive variable');

-- Unapproved evidence promotion must fail immediately.
SELECT test_expect_failure('A5_EVIDENCE_APPROVAL_BYPASS',
$q$UPDATE evidence SET evidence_status='APPROVED' WHERE evidence_id='TEST-CMC4-VALID'$q$,
'APPROVED evidence requires separate HUMAN approval_event for exact evidence version');

SELECT test_expect_failure('A6_APPROVED_JSON_BYPASS',
$q$INSERT INTO claim_evidence (claim_id,evidence_id,evaluation_version,relationship,interpretation,approved_score_change,review_status) VALUES ('TEST-CLAIM','TEST-BASE-EVIDENCE','hostile','SUPPORT','hostile','{"ED":4}'::jsonb,'APPROVED')$q$,
'approved_score_change_json_must_be_null');

INSERT INTO audit_log (entity_type,entity_id,action,reason,actor) VALUES ('TEST','A7','INSERT','hostile fixture','test');
SELECT test_expect_failure('A7_AUDIT_MUTATION',
$q$UPDATE audit_log SET reason='tampered' WHERE entity_type='TEST' AND entity_id='A7'$q$,
'audit_log is append-only');

SELECT test_expect_failure('A8_SCORE_WITHOUT_APPROVAL',
$q$UPDATE claims SET ps=4 WHERE claim_id='TEST-CLAIM'$q$,
'without separate HUMAN approval_event for exact proposal version');

INSERT INTO provenance_events (provenance_event_id,entity_type,entity_id,actor_type,actor_identity,action) VALUES ('00000000-0000-0000-0000-000000000301','TEST','A9','AI_MODEL','ai-reviewer','APPROVAL_REVIEW');
SELECT test_expect_failure('A9_AI_APPROVAL',
$q$INSERT INTO approval_events (approval_event_id,evidence_id,decision,approver_identity,approver_actor_type,reviewer_role,approval_scope,entity_version,rationale,provenance_event_id) VALUES ('00000000-0000-0000-0000-000000000302','TEST-BASE-EVIDENCE','APPROVE','ai-reviewer','AI_MODEL','APPROVER','EVIDENCE_PROMOTION','test-positive','hostile','00000000-0000-0000-0000-000000000301')$q$,
'authoritative approval decisions require HUMAN actor type');
SELECT test_expect_failure('A10_AI_PROVENANCE_LAUNDERING',
$q$INSERT INTO approval_events (approval_event_id,evidence_id,decision,approver_identity,approver_actor_type,reviewer_role,approval_scope,entity_version,rationale,provenance_event_id) VALUES ('00000000-0000-0000-0000-000000000303','TEST-BASE-EVIDENCE','APPROVE','human-reviewer-x','HUMAN','APPROVER','EVIDENCE_PROMOTION','test-positive','hostile','00000000-0000-0000-0000-000000000301')$q$,
'approval provenance must bind to the same HUMAN approver identity');

-- Exact link fixtures for hostile proposal cases.
INSERT INTO claim_evidence (claim_id,evidence_id,evaluation_version,relationship,interpretation,score_effect,review_status) VALUES
('TEST-CLAIM','TEST-BASE-EVIDENCE','self-test','SUPPORT','self approval hostile link','SUPPORT','PENDING'),
('TEST-CLAIM','TEST-BASE-EVIDENCE','version-correct','SUPPORT','version hostile link','SUPPORT','PENDING');

INSERT INTO score_change_proposals (score_change_id,claim_id,evidence_id,evaluation_version,dimension,old_value,proposed_value,rationale,proposed_by,proposed_by_type) VALUES ('00000000-0000-0000-0000-000000000311','TEST-CLAIM','TEST-BASE-EVIDENCE','self-test','PS',3,4,'hostile','human-self','HUMAN');
INSERT INTO provenance_events (provenance_event_id,entity_type,entity_id,actor_type,actor_identity,action) VALUES ('00000000-0000-0000-0000-000000000312','SCORE_CHANGE_PROPOSAL','00000000-0000-0000-0000-000000000311','HUMAN','human-self','APPROVAL_REVIEW');
SELECT test_expect_failure('A11_SELF_APPROVAL',
$q$INSERT INTO approval_events (approval_event_id,claim_id,evidence_id,score_change_id,decision,approver_identity,approver_actor_type,reviewer_role,approval_scope,entity_version,rationale,provenance_event_id) VALUES ('00000000-0000-0000-0000-000000000313','TEST-CLAIM','TEST-BASE-EVIDENCE','00000000-0000-0000-0000-000000000311','APPROVE','human-self','HUMAN','APPROVER','SCORE_CHANGE','self-test','hostile','00000000-0000-0000-0000-000000000312')$q$,
'score-change proposer cannot approve their own proposal');
SELECT test_expect_failure('A12_PROPOSAL_MUTATION',
$q$UPDATE score_change_proposals SET rationale='rewritten after review' WHERE score_change_id='00000000-0000-0000-0000-000000000311'$q$,
'score_change_proposals are immutable after submission');
SELECT test_expect_failure('A13_APPROVAL_MUTATION',
$q$UPDATE approval_events SET rationale='tampered' WHERE approval_event_id='00000000-0000-0000-0000-000000000101'$q$,
'approval_events are append-only');

-- Wrong-version approval must now fail at insertion, not merely fail to authorize mutation.
INSERT INTO score_change_proposals (score_change_id,claim_id,evidence_id,evaluation_version,dimension,old_value,proposed_value,rationale,proposed_by,proposed_by_type) VALUES ('00000000-0000-0000-0000-000000000321','TEST-CLAIM','TEST-BASE-EVIDENCE','version-correct','CI',2,3,'hostile','ai-proposer-2','AI_MODEL');
INSERT INTO provenance_events (provenance_event_id,entity_type,entity_id,actor_type,actor_identity,action) VALUES ('00000000-0000-0000-0000-000000000322','SCORE_CHANGE_PROPOSAL','00000000-0000-0000-0000-000000000321','HUMAN','human-reviewer-2','APPROVAL_REVIEW');
SELECT test_expect_failure('A14_VERSION_MISMATCH',
$q$INSERT INTO approval_events (approval_event_id,claim_id,evidence_id,score_change_id,decision,approver_identity,approver_actor_type,reviewer_role,approval_scope,entity_version,rationale,provenance_event_id) VALUES ('00000000-0000-0000-0000-000000000323','TEST-CLAIM','TEST-BASE-EVIDENCE','00000000-0000-0000-0000-000000000321','APPROVE','human-reviewer-2','HUMAN','APPROVER','SCORE_CHANGE','version-wrong','hostile','00000000-0000-0000-0000-000000000322')$q$,
'score-change approval scope must exactly match proposal claim, evidence, and evaluation version');

SELECT test_expect_failure('A15_INVALID_ENUM',
$q$UPDATE evidence SET preregistered='HIGH' WHERE evidence_id='TEST-BASE-EVIDENCE'$q$,
'invalid input value for enum tri_state_code');

-- New audit-derived hostile cases.
SELECT test_expect_failure('A16_PROVENANCE_MUTATION',
$q$UPDATE provenance_events SET action='TAMPERED' WHERE provenance_event_id='00000000-0000-0000-0000-000000000201'$q$,
'provenance_events are append-only');

SELECT test_expect_failure('A17_ORPHAN_SCORE_PROPOSAL_LINK',
$q$INSERT INTO score_change_proposals (score_change_id,claim_id,evidence_id,evaluation_version,dimension,old_value,proposed_value,rationale,proposed_by,proposed_by_type) VALUES ('00000000-0000-0000-0000-000000000331','TEST-CLAIM','TEST-BASE-EVIDENCE','no-such-link','RR',1,2,'hostile','ai','AI_MODEL')$q$,
'violates foreign key constraint "scp_claim_evidence_fk"');

-- A valid score mutation must have emitted an immutable audit row.
DO $$ BEGIN
IF NOT EXISTS (
    SELECT 1 FROM audit_log
    WHERE entity_type='CLAIM_SCORE' AND entity_id='TEST-CLAIM:ED'
      AND action='APPROVED_SCORE_CHANGE' AND evidence_id='TEST-BASE-EVIDENCE'
      AND actor='human-reviewer-1'
) THEN RAISE EXCEPTION 'A18_SCORE_AUDIT_EMISSION missing expected immutable audit row'; END IF;
RAISE NOTICE 'PASS A18_SCORE_AUDIT_EMISSION';
END $$;

DROP FUNCTION test_expect_failure(text,text,text);
