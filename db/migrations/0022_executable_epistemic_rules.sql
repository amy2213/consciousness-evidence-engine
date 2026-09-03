-- Phase 11: executable epistemic rules.
-- Central scientific prohibitions become typed, machine-enforceable state.
BEGIN;

CREATE TYPE inference_strength_code AS ENUM (
  'CORRELATIONAL','ASSOCIATIVE','CAUSAL_CONTRIBUTION','NECESSITY','SUFFICIENCY','IDENTITY','UNRESOLVED'
);
CREATE TYPE inference_target_code AS ENUM (
  'SUBSTRATE','GENERAL_COGNITION','CONSCIOUSNESS_ADJACENT','CONSCIOUSNESS','PHENOMENALITY','WHOLE_THEORY','UNRESOLVED'
);
CREATE TYPE result_polarity_code AS ENUM ('POSITIVE','NEGATIVE','MIXED','NOT_APPLICABLE','UNRESOLVED');

ALTER TABLE claim_evidence
  ADD COLUMN inference_strength inference_strength_code NOT NULL DEFAULT 'UNRESOLVED',
  ADD COLUMN inference_target inference_target_code NOT NULL DEFAULT 'UNRESOLVED',
  ADD COLUMN result_polarity result_polarity_code NOT NULL DEFAULT 'UNRESOLVED',
  ADD COLUMN component_scope_only BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN synthetic_experience_bridge_established BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN epistemic_rationale TEXT;

ALTER TABLE rules
  ADD COLUMN human_review_fallback TEXT,
  ADD COLUMN exact_failure_message TEXT;

CREATE OR REPLACE FUNCTION enforce_epistemic_claim_evidence_rules()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  has_phen_role BOOLEAN;
  is_ex_vivo BOOLEAN;
  is_synthetic BOOLEAN;
BEGIN
  -- R-001: correlation is not causation.
  IF NEW.inference_strength IN ('CAUSAL_CONTRIBUTION','NECESSITY','SUFFICIENCY','IDENTITY')
     AND NOT EXISTS (
       SELECT 1 FROM evidence e
       WHERE e.evidence_id=NEW.evidence_id
         AND e.causal_manipulation='TRUE'
         AND e.causal_manipulation_scope IN ('CONSCIOUSNESS_LINKED_SYSTEM','CONSCIOUSNESS_SENSITIVE_VARIABLE')
     ) THEN
    RAISE EXCEPTION 'R-001 correlation cannot be promoted to causal inference without qualifying causal manipulation';
  END IF;

  -- R-002: causal contribution is not necessity.
  IF NEW.inference_strength='NECESSITY'
     AND NOT EXISTS (
       SELECT 1 FROM evidence e
       WHERE e.evidence_id=NEW.evidence_id
         AND e.causal_manipulation='TRUE'
         AND e.causal_manipulation_scope='CONSCIOUSNESS_SENSITIVE_VARIABLE'
     ) THEN
    RAISE EXCEPTION 'R-002 causal contribution cannot independently establish necessity';
  END IF;

  -- R-003: necessity is not sufficiency.
  IF NEW.inference_strength='SUFFICIENCY'
     AND EXISTS (SELECT 1 FROM claim_claim_types cct WHERE cct.claim_id=NEW.claim_id AND cct.claim_type='N')
     AND NOT EXISTS (SELECT 1 FROM claim_claim_types cct WHERE cct.claim_id=NEW.claim_id AND cct.claim_type='S') THEN
    RAISE EXCEPTION 'R-003 necessity evidence cannot independently establish sufficiency';
  END IF;

  SELECT EXISTS(
    SELECT 1 FROM claim_theory_roles ctr WHERE ctr.claim_id=NEW.claim_id AND ctr.theory_role='PHEN'
  ) INTO has_phen_role;

  -- R-004/R-010: functional or organizational evidence is not phenomenality.
  IF NEW.relationship='SUPPORT'
     AND NEW.inference_strength<>'UNRESOLVED'
     AND (has_phen_role OR NEW.inference_target='PHENOMENALITY')
     AND NOT EXISTS (
       SELECT 1 FROM evidence_measurements em
       JOIN measurements m ON m.measurement_id=em.measurement_id
       WHERE em.evidence_id=NEW.evidence_id
         AND m.consciousness_specificity='VALIDATED'
     ) THEN
    RAISE EXCEPTION 'R-004 cognitive or organizational evidence cannot independently promote phenomenality without validated consciousness-sensitive measurement';
  END IF;

  -- R-005: component evidence cannot confirm a whole theory.
  IF NEW.inference_target='WHOLE_THEORY' OR NEW.component_scope_only IS FALSE THEN
    RAISE EXCEPTION 'R-005 component evidence cannot be promoted to confirmation of a whole theory';
  END IF;

  -- R-015: implementation in an artificial/simulated/synthetic system is not experience.
  SELECT EXISTS(
    SELECT 1 FROM evidence_evaluation_contexts eec
    JOIN evaluation_contexts ec ON ec.evaluation_context_id=eec.evaluation_context_id
    WHERE eec.evidence_id=NEW.evidence_id
      AND ec.context_type IN ('ARTIFICIAL_SYSTEM','SIMULATION','SYNTHETIC_CONSTRUCT')
  ) INTO is_synthetic;
  IF is_synthetic
     AND NEW.inference_target IN ('CONSCIOUSNESS','PHENOMENALITY')
     AND NEW.synthetic_experience_bridge_established IS NOT TRUE THEN
    RAISE EXCEPTION 'R-015 synthetic mechanism implementation does not establish consciousness or experience without an explicit validated bridge';
  END IF;

  -- R-008: negative demanding active tests have an absence-inference CMC cap.
  IF NEW.result_polarity='NEGATIVE'
     AND NEW.inference_target IN ('CONSCIOUSNESS','PHENOMENALITY')
     AND EXISTS (
       SELECT 1 FROM evidence e
       WHERE e.evidence_id=NEW.evidence_id
         AND e.asymmetry_role='ACTIVE_TEST'
         AND COALESCE(e.negative_inference_cmc_cap,4) <= 1
         AND e.cmc IN ('2','3','4')
     ) THEN
    RAISE EXCEPTION 'R-008 negative active-test absence inference is capped at CMC 1 unless independent sensitivity and state-quality constraints are established';
  END IF;

  -- R-009: ex-vivo organization confidence cannot become consciousness measurement confidence.
  SELECT EXISTS(
    SELECT 1 FROM evidence_evaluation_contexts eec
    JOIN evaluation_contexts ec ON ec.evaluation_context_id=eec.evaluation_context_id
    WHERE eec.evidence_id=NEW.evidence_id AND ec.context_type='EX_VIVO_NEURAL_SYSTEM'
  ) INTO is_ex_vivo;
  IF is_ex_vivo
     AND NEW.inference_target IN ('CONSCIOUSNESS','PHENOMENALITY')
     AND EXISTS (SELECT 1 FROM evidence e WHERE e.evidence_id=NEW.evidence_id AND e.oec IN ('1','2','3','4'))
     AND NOT EXISTS (
       SELECT 1 FROM evidence_measurements em
       JOIN measurements m ON m.measurement_id=em.measurement_id
       WHERE em.evidence_id=NEW.evidence_id AND m.consciousness_specificity='VALIDATED'
     ) THEN
    RAISE EXCEPTION 'R-009 ex vivo organizational evidence cannot promote consciousness measurement confidence without validated consciousness-sensitive measurement';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER claim_evidence_epistemic_gate
BEFORE INSERT OR UPDATE OF inference_strength,inference_target,result_polarity,component_scope_only,synthetic_experience_bridge_established,relationship ON claim_evidence
FOR EACH ROW EXECUTE FUNCTION enforce_epistemic_claim_evidence_rules();

-- R-007 gets a stable rule-prefixed failure contract.
CREATE OR REPLACE FUNCTION enforce_cmc_four_full_gate()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.cmc='4' THEN
    IF NEW.causal_manipulation<>'TRUE' THEN
      RAISE EXCEPTION 'R-007 CMC 4 requires causal manipulation';
    END IF;
    IF NEW.consciousness_sensitive_convergence IS NOT TRUE THEN
      RAISE EXCEPTION 'R-007 CMC 4 requires convergent consciousness-sensitive measurement';
    END IF;
    IF NEW.preregistered<>'TRUE' AND NEW.independent_replication<>'TRUE' THEN
      RAISE EXCEPTION 'R-007 CMC 4 requires preregistration or independent replication';
    END IF;
    IF NEW.causal_manipulation_scope<>'CONSCIOUSNESS_SENSITIVE_VARIABLE' THEN
      RAISE EXCEPTION 'R-007 CMC 4 requires causal manipulation of a consciousness-sensitive variable';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

INSERT INTO rules(rule_id,name,scope,severity,expression,rationale,specification_reference,active_from_version,human_review_fallback,exact_failure_message) VALUES
('R-001','correlation_is_not_causation','claim_evidence','BLOCK','claim_evidence_epistemic_gate:R-001','Correlational evidence cannot independently satisfy a causal claim.','Master Build Plan Phase 11','v1.1.1','Human review may classify causal scope when source-locked intervention status is unresolved.','R-001 correlation cannot be promoted to causal inference without qualifying causal manipulation'),
('R-002','contribution_is_not_necessity','claim_evidence','BLOCK','claim_evidence_epistemic_gate:R-002','Evidence of causal contribution cannot independently establish necessity.','Master Build Plan Phase 11','v1.1.1','Human review may document a separately established necessity intervention chain.','R-002 causal contribution cannot independently establish necessity'),
('R-003','necessity_is_not_sufficiency','claim_evidence','BLOCK','claim_evidence_epistemic_gate:R-003','Necessity evidence cannot independently establish sufficiency.','Master Build Plan Phase 11','v1.1.1','A separate sufficiency test must be represented explicitly.','R-003 necessity evidence cannot independently establish sufficiency'),
('R-004','cognition_is_not_phenomenality','claim_evidence','BLOCK','claim_evidence_epistemic_gate:R-004','General cognitive or perceptual evidence cannot independently promote a phenomenal claim.','Master Build Plan Phase 11','v1.1.1','Human review may bind a prospectively validated consciousness-sensitive measurement.','R-004 cognitive or organizational evidence cannot independently promote phenomenality without validated consciousness-sensitive measurement'),
('R-005','component_is_not_whole_theory','claim_evidence','BLOCK','claim_evidence_epistemic_gate:R-005','Evidence for one component cannot confirm the whole theory.','Master Build Plan Phase 11','v1.1.1','Whole-theory conclusions require explicit multi-claim synthesis and rival analysis.','R-005 component evidence cannot be promoted to confirmation of a whole theory'),
('R-006','source_required_for_score_increase','score_change','BLOCK','claims_score_change_provenance_gate','Score increase requires exact registered source and claim/evidence link.','Master Build Plan permanent checks','v1.1.1','Human review resolves source closure or claim-link ambiguity before approval.','R-006 score increase requires exact registered source and claim-evidence provenance'),
('R-007','cmc_four_requires_causal_triangulation','evidence','BLOCK','evidence_cmc_four_full_gate','CMC4 requires causal manipulation, consciousness-sensitive convergence, and preregistration or independent replication.','Master Build Plan Phase 11','v1.1.1','Human review may resolve ND fields but cannot waive missing hard-gate conditions.','R-007 CMC 4 hard-gate condition failed'),
('R-008','negative_active_task_asymmetry','claim_evidence','BLOCK','claim_evidence_epistemic_gate:R-008','Negative demanding active-task evidence has an absence-inference cap.','Master Build Plan Phase 11','v1.1.1','Human review may document independently established sensitivity and state-quality constraints in a future governed exception path.','R-008 negative active-test absence inference is capped at CMC 1 unless independent sensitivity and state-quality constraints are established'),
('R-009','oec_cmc_firewall','claim_evidence','BLOCK','claim_evidence_epistemic_gate:R-009','Organizational evidence confidence cannot automatically promote consciousness measurement confidence.','Master Build Plan Phase 11','v1.1.1','Human review may bind a prospectively validated consciousness-sensitive measure; OEC alone never suffices.','R-009 ex vivo organizational evidence cannot promote consciousness measurement confidence without validated consciousness-sensitive measurement'),
('R-010','organizational_complexity_not_consciousness','claim_evidence','BLOCK','claim_evidence_epistemic_gate:R-004','Organizational complexity cannot independently establish phenomenality.','Master Build Plan Phase 11','v1.1.1','Human review requires an explicit validated phenomenal bridge.','R-004 cognitive or organizational evidence cannot independently promote phenomenality without validated consciousness-sensitive measurement'),
('R-011','canonical_claim_role','claim taxonomy','ERROR','claim_version_theory_roles foreign-keyed canonical role','Views may not redefine canonical Theory Role.','Frozen v1.1.1 methodology','v1.1.1','Human correction requires a new reviewed claim version.','R-011 canonical claim role mismatch'),
('R-012','typed_null_semantics','typed scientific fields','ERROR','typed enums ND/NA and database constraints','ND and NA retain distinct scientific meanings.','Frozen v1.1.1 methodology','v1.1.1','Human review resolves whether a field is not applicable or not determined.','R-012 ND and NA may not be collapsed into database NULL'),
('R-013','no_ai_direct_commit','approval','BLOCK','approval_authority_gate','AI-assisted work cannot issue authoritative scientific approval.','Master Build Plan permanent checks','v1.1.1','A distinct authorized human must review and decide.','R-013 AI cannot issue authoritative scientific approval'),
('R-014','score_change_requires_audit','score_change','BLOCK','claims_score_change_audit_emit','Accepted score changes require immutable audit history.','Master Build Plan permanent checks','v1.1.1','Human approval is invalid if immutable audit/provenance emission fails.','R-014 accepted score change requires immutable audit provenance'),
('R-015','synthetic_mechanism_is_not_experience','claim_evidence','BLOCK','claim_evidence_epistemic_gate:R-015','Implementation of a mechanism in a synthetic system does not establish experience.','Master Build Plan Phase 11','v1.1.1','Human review may recognize only an explicitly validated synthetic-to-experience bridge.','R-015 synthetic mechanism implementation does not establish consciousness or experience without an explicit validated bridge')
ON CONFLICT (rule_id) DO UPDATE SET
  name=EXCLUDED.name,scope=EXCLUDED.scope,severity=EXCLUDED.severity,expression=EXCLUDED.expression,
  rationale=EXCLUDED.rationale,specification_reference=EXCLUDED.specification_reference,
  active_from_version=EXCLUDED.active_from_version,human_review_fallback=EXCLUDED.human_review_fallback,
  exact_failure_message=EXCLUDED.exact_failure_message;

GRANT SELECT ON rules TO cee_app_read,cee_ingest,cee_review,cee_approve,cee_release;
COMMIT;
