-- Phase 12 hardening: logical inference strength requires explicit design qualification.
BEGIN;

ALTER TABLE claim_evidence
  ADD COLUMN necessity_design_established BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN sufficiency_design_established BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE claim_evidence
  ADD CONSTRAINT necessity_design_requires_rationale CHECK (
    necessity_design_established IS FALSE OR btrim(COALESCE(epistemic_rationale,'')) <> ''
  ),
  ADD CONSTRAINT sufficiency_design_requires_rationale CHECK (
    sufficiency_design_established IS FALSE OR btrim(COALESCE(epistemic_rationale,'')) <> ''
  );

CREATE OR REPLACE FUNCTION enforce_epistemic_claim_evidence_rules()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  has_phen_role BOOLEAN;
  is_ex_vivo BOOLEAN;
  is_synthetic BOOLEAN;
BEGIN
  IF NEW.inference_strength IN ('CAUSAL_CONTRIBUTION','NECESSITY','SUFFICIENCY','IDENTITY')
     AND NOT EXISTS (
       SELECT 1 FROM evidence e
       WHERE e.evidence_id=NEW.evidence_id
         AND e.causal_manipulation='TRUE'
         AND e.causal_manipulation_scope IN ('CONSCIOUSNESS_LINKED_SYSTEM','CONSCIOUSNESS_SENSITIVE_VARIABLE')
     ) THEN
    RAISE EXCEPTION 'R-001 correlation cannot be promoted to causal inference without qualifying causal manipulation';
  END IF;

  IF NEW.inference_strength='NECESSITY' AND NEW.necessity_design_established IS NOT TRUE THEN
    RAISE EXCEPTION 'R-002 causal contribution cannot independently establish necessity';
  END IF;

  IF NEW.inference_strength='SUFFICIENCY' AND NEW.sufficiency_design_established IS NOT TRUE THEN
    RAISE EXCEPTION 'R-003 necessity evidence cannot independently establish sufficiency';
  END IF;

  SELECT EXISTS(
    SELECT 1 FROM claim_theory_roles ctr WHERE ctr.claim_id=NEW.claim_id AND ctr.theory_role='PHEN'
  ) INTO has_phen_role;

  IF NEW.relationship='SUPPORT'
     AND NEW.inference_strength<>'UNRESOLVED'
     AND (has_phen_role OR NEW.inference_target='PHENOMENALITY')
     AND NOT EXISTS (
       SELECT 1 FROM evidence_measurements em
       JOIN measurements m ON m.measurement_id=em.measurement_id
       WHERE em.evidence_id=NEW.evidence_id AND m.consciousness_specificity='VALIDATED'
     ) THEN
    RAISE EXCEPTION 'R-004 cognitive or organizational evidence cannot independently promote phenomenality without validated consciousness-sensitive measurement';
  END IF;

  IF NEW.inference_target='WHOLE_THEORY' OR NEW.component_scope_only IS FALSE THEN
    RAISE EXCEPTION 'R-005 component evidence cannot be promoted to confirmation of a whole theory';
  END IF;

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

DROP TRIGGER IF EXISTS claim_evidence_epistemic_gate ON claim_evidence;
CREATE TRIGGER claim_evidence_epistemic_gate
BEFORE INSERT OR UPDATE OF inference_strength,inference_target,result_polarity,component_scope_only,synthetic_experience_bridge_established,necessity_design_established,sufficiency_design_established,relationship ON claim_evidence
FOR EACH ROW EXECUTE FUNCTION enforce_epistemic_claim_evidence_rules();

COMMENT ON COLUMN claim_evidence.necessity_design_established IS
'True only when the exact evidence/claim relation includes a source-supported design capable of testing necessity. Causal contribution alone is insufficient.';
COMMENT ON COLUMN claim_evidence.sufficiency_design_established IS
'True only when the exact evidence/claim relation includes a source-supported design capable of testing sufficiency. Necessity evidence alone is insufficient.';

COMMIT;
