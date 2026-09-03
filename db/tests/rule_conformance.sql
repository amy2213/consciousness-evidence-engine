-- Phase 12: rule conformance suite.
-- Every executable epistemic firewall is tested for exact intended rejection and safe boundary behavior.

CREATE OR REPLACE FUNCTION rule_expect_failure(label text, sql_text text, expected_message text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE msg text;
BEGIN
  BEGIN EXECUTE sql_text;
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS msg=MESSAGE_TEXT;
    IF position(expected_message in msg)=0 THEN
      RAISE EXCEPTION 'rule conformance % failed for wrong reason: %',label,msg;
    END IF;
    RAISE NOTICE 'PASS %: %',label,msg;
    RETURN;
  END;
  RAISE EXCEPTION 'rule conformance % unexpectedly succeeded',label;
END;
$$;

SELECT rule_expect_failure('RC_R001_CORRELATION_TO_CAUSATION',
$q$INSERT INTO claim_evidence(claim_id,evidence_id,evaluation_version,relationship,interpretation,review_status,inference_strength,inference_target) VALUES ('TEST-CLAIM','TEST-BASE-EVIDENCE','rc-r001','SUPPORT','hostile causal promotion','PENDING','CAUSAL_CONTRIBUTION','CONSCIOUSNESS_ADJACENT')$q$,
'R-001 correlation cannot be promoted to causal inference without qualifying causal manipulation');

SELECT rule_expect_failure('RC_R002_CONTRIBUTION_TO_NECESSITY',
$q$INSERT INTO claim_evidence(claim_id,evidence_id,evaluation_version,relationship,interpretation,review_status,inference_strength,inference_target) VALUES ('TEST-CLAIM','TEST-CMC4-VALID','rc-r002','SUPPORT','causal contribution is not enough for necessity','PENDING','NECESSITY','CONSCIOUSNESS')$q$,
'R-002 causal contribution cannot independently establish necessity');

-- Positive R002 boundary: a necessity inference is representable only when the exact relation
-- explicitly records a necessity-capable design and rationale.
INSERT INTO claim_evidence(
 claim_id,evidence_id,evaluation_version,relationship,interpretation,review_status,
 inference_strength,inference_target,necessity_design_established,epistemic_rationale
) VALUES (
 'TEST-CLAIM','TEST-CMC4-VALID','rc-r002-positive','SUPPORT','explicit necessity design fixture','PENDING',
 'NECESSITY','CONSCIOUSNESS',TRUE,'Fixture explicitly establishes a necessity-capable intervention design.'
);

SELECT rule_expect_failure('RC_R003_NECESSITY_TO_SUFFICIENCY',
$q$INSERT INTO claim_evidence(claim_id,evidence_id,evaluation_version,relationship,interpretation,review_status,inference_strength,inference_target) VALUES ('TEST-CLAIM','TEST-CMC4-VALID','rc-r003','SUPPORT','necessity evidence is not enough for sufficiency','PENDING','SUFFICIENCY','CONSCIOUSNESS_ADJACENT')$q$,
'R-003 necessity evidence cannot independently establish sufficiency');

-- Positive R003 boundary requires explicit sufficiency-capable design and rationale.
INSERT INTO claim_evidence(
 claim_id,evidence_id,evaluation_version,relationship,interpretation,review_status,
 inference_strength,inference_target,sufficiency_design_established,epistemic_rationale
) VALUES (
 'TEST-CLAIM','TEST-CMC4-VALID','rc-r003-positive','SUPPORT','explicit sufficiency design fixture','PENDING',
 'SUFFICIENCY','CONSCIOUSNESS_ADJACENT',TRUE,'Fixture explicitly establishes a sufficiency-capable intervention design.'
);

-- R004 edge: PHEN role with unresolved inference remains representable; positive phenomenal promotion is blocked.
INSERT INTO claim_theory_roles(claim_id,theory_role) VALUES ('TEST-CLAIM','PHEN');
INSERT INTO claim_evidence(claim_id,evidence_id,evaluation_version,relationship,interpretation,review_status,inference_strength,inference_target)
VALUES ('TEST-CLAIM','TEST-BASE-EVIDENCE','rc-r004-edge','UNRESOLVED','unresolved phenomenal-adjacent record is allowed','PENDING','UNRESOLVED','UNRESOLVED');
SELECT rule_expect_failure('RC_R004_COGNITION_TO_PHENOMENALITY',
$q$INSERT INTO claim_evidence(claim_id,evidence_id,evaluation_version,relationship,interpretation,review_status,inference_strength,inference_target) VALUES ('TEST-CLAIM','TEST-BASE-EVIDENCE','rc-r004','SUPPORT','hostile phenomenal promotion','PENDING','ASSOCIATIVE','PHENOMENALITY')$q$,
'R-004 cognitive or organizational evidence cannot independently promote phenomenality without validated consciousness-sensitive measurement');
DELETE FROM claim_theory_roles WHERE claim_id='TEST-CLAIM' AND theory_role='PHEN';

SELECT rule_expect_failure('RC_R005_COMPONENT_TO_WHOLE_THEORY',
$q$INSERT INTO claim_evidence(claim_id,evidence_id,evaluation_version,relationship,interpretation,review_status,inference_strength,inference_target) VALUES ('TEST-CLAIM','TEST-BASE-EVIDENCE','rc-r005','SUPPORT','hostile whole-theory promotion','PENDING','ASSOCIATIVE','WHOLE_THEORY')$q$,
'R-005 component evidence cannot be promoted to confirmation of a whole theory');

SELECT rule_expect_failure('RC_R007_CAUSAL_MUTATION',
$q$INSERT INTO evidence(evidence_id,source_id,population_id,finding,causal_manipulation,causal_manipulation_scope,consciousness_sensitive_convergence,preregistered,independent_replication,cmc,oec,evidence_status) VALUES ('RC-E7A','SRC-999','ANESTHESIA','mutation','FALSE','NONE',TRUE,'TRUE','FALSE','4','NA','VALIDATED')$q$,
'R-007 CMC 4 requires causal manipulation');
SELECT rule_expect_failure('RC_R007_CONVERGENCE_MUTATION',
$q$INSERT INTO evidence(evidence_id,source_id,population_id,finding,causal_manipulation,causal_manipulation_scope,consciousness_sensitive_convergence,preregistered,independent_replication,cmc,oec,evidence_status) VALUES ('RC-E7B','SRC-999','ANESTHESIA','mutation','TRUE','CONSCIOUSNESS_SENSITIVE_VARIABLE',FALSE,'TRUE','FALSE','4','NA','VALIDATED')$q$,
'R-007 CMC 4 requires convergent consciousness-sensitive measurement');
SELECT rule_expect_failure('RC_R007_REPLICATION_MUTATION',
$q$INSERT INTO evidence(evidence_id,source_id,population_id,finding,causal_manipulation,causal_manipulation_scope,consciousness_sensitive_convergence,preregistered,independent_replication,cmc,oec,evidence_status) VALUES ('RC-E7C','SRC-999','ANESTHESIA','mutation','TRUE','CONSCIOUSNESS_SENSITIVE_VARIABLE',TRUE,'FALSE','FALSE','4','NA','VALIDATED')$q$,
'R-007 CMC 4 requires preregistration or independent replication');
SELECT rule_expect_failure('RC_R007_SCOPE_MUTATION',
$q$INSERT INTO evidence(evidence_id,source_id,population_id,finding,causal_manipulation,causal_manipulation_scope,consciousness_sensitive_convergence,preregistered,independent_replication,cmc,oec,evidence_status) VALUES ('RC-E7D','SRC-999','ANESTHESIA','mutation','TRUE','SUBSTRATE_MECHANISM_ONLY',TRUE,'TRUE','FALSE','4','NA','VALIDATED')$q$,
'R-007 CMC 4 requires causal manipulation of a consciousness-sensitive variable');

INSERT INTO evidence(evidence_id,source_id,population_id,finding,causal_manipulation,causal_manipulation_scope,asymmetry_role,negative_inference_cmc_cap,preregistered,independent_replication,cmc,oec,evidence_status)
VALUES ('RC-E8','SRC-999','DOC_CMD','explicit negative active-test fixture','FALSE','NONE','ACTIVE_TEST',1,'FALSE','FALSE','2','NA','VALIDATED');
SELECT rule_expect_failure('RC_R008_NEGATIVE_ACTIVE_TEST',
$q$INSERT INTO claim_evidence(claim_id,evidence_id,evaluation_version,relationship,interpretation,review_status,inference_strength,inference_target,result_polarity) VALUES ('TEST-CLAIM','RC-E8','rc-r008','PRESSURE','hostile absence inference','PENDING','ASSOCIATIVE','CONSCIOUSNESS','NEGATIVE')$q$,
'R-008 negative active-test absence inference is capped at CMC 1 unless independent sensitivity and state-quality constraints are established');
INSERT INTO claim_evidence(claim_id,evidence_id,evaluation_version,relationship,interpretation,review_status,inference_strength,inference_target,result_polarity)
VALUES ('TEST-CLAIM','RC-E8','rc-r008-edge','UNRESOLVED','negative result retained without overclaim','PENDING','UNRESOLVED','UNRESOLVED','NEGATIVE');

INSERT INTO evidence(evidence_id,source_id,finding,causal_manipulation,causal_manipulation_scope,preregistered,independent_replication,cmc,oec,evidence_status)
VALUES ('RC-E9','SRC-999','ex vivo organization fixture','FALSE','NONE','FALSE','FALSE','0','3','VALIDATED');
INSERT INTO evaluation_contexts(evaluation_context_id,context_class,name,context_type,biological_population)
VALUES ('RC-EXVIVO','EX_VIVO','rule conformance ex vivo','EX_VIVO_NEURAL_SYSTEM',FALSE);
INSERT INTO evidence_evaluation_contexts(evidence_id,evaluation_context_id,is_primary,rationale)
VALUES ('RC-E9','RC-EXVIVO',TRUE,'rule conformance fixture');
SELECT rule_expect_failure('RC_R009_OEC_TO_CMC',
$q$INSERT INTO claim_evidence(claim_id,evidence_id,evaluation_version,relationship,interpretation,review_status,inference_strength,inference_target) VALUES ('TEST-CLAIM','RC-E9','rc-r009','SUPPORT','hostile OEC-to-consciousness promotion','PENDING','ASSOCIATIVE','CONSCIOUSNESS')$q$,
'R-009 ex vivo organizational evidence cannot promote consciousness measurement confidence without validated consciousness-sensitive measurement');

INSERT INTO evidence(evidence_id,source_id,finding,causal_manipulation,causal_manipulation_scope,preregistered,independent_replication,cmc,oec,evidence_status)
VALUES ('RC-E15','SRC-999','synthetic mechanism fixture','FALSE','NONE','FALSE','FALSE','0','NA','VALIDATED');
INSERT INTO evaluation_contexts(evaluation_context_id,context_class,name,context_type,biological_population)
VALUES ('RC-SYNTH','SYNTHETIC','rule conformance synthetic','SYNTHETIC_CONSTRUCT',FALSE);
INSERT INTO evidence_evaluation_contexts(evidence_id,evaluation_context_id,is_primary,rationale)
VALUES ('RC-E15','RC-SYNTH',TRUE,'rule conformance fixture');
SELECT rule_expect_failure('RC_R015_SYNTHETIC_TO_EXPERIENCE',
$q$INSERT INTO claim_evidence(claim_id,evidence_id,evaluation_version,relationship,interpretation,review_status,inference_strength,inference_target) VALUES ('TEST-CLAIM','RC-E15','rc-r015','SUPPORT','hostile synthetic experience promotion','PENDING','ASSOCIATIVE','CONSCIOUSNESS')$q$,
'R-015 synthetic mechanism implementation does not establish consciousness or experience without an explicit validated bridge');

INSERT INTO claim_evidence(claim_id,evidence_id,evaluation_version,relationship,interpretation,review_status,inference_strength,inference_target,result_polarity)
VALUES ('TEST-CLAIM','TEST-BASE-EVIDENCE','rc-positive','SUPPORT','legal associative claim-level support','PENDING','ASSOCIATIVE','CONSCIOUSNESS_ADJACENT','POSITIVE');

DROP FUNCTION rule_expect_failure(text,text,text);
