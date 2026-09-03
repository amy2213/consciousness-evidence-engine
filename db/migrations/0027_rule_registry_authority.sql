-- Governance checkpoint: make public.rules the canonical rule registry.
-- rules/core-rules.yaml is a generated projection and must reconcile exactly in CI.
BEGIN;

CREATE TYPE rule_enforcement_kind_code AS ENUM (
  'TRIGGER_FUNCTION',
  'RELATIONAL_CONSTRAINT',
  'RECONCILIATION_TEST'
);

ALTER TABLE rules
  ADD COLUMN enforcement_kind rule_enforcement_kind_code,
  ADD COLUMN enforcement_artifact TEXT;

UPDATE rules SET enforcement_kind='TRIGGER_FUNCTION', enforcement_artifact='claim_evidence_epistemic_gate:R-001' WHERE rule_id='R-001';
UPDATE rules SET enforcement_kind='TRIGGER_FUNCTION', enforcement_artifact='claim_evidence_epistemic_gate:R-002' WHERE rule_id='R-002';
UPDATE rules SET enforcement_kind='TRIGGER_FUNCTION', enforcement_artifact='claim_evidence_epistemic_gate:R-003' WHERE rule_id='R-003';
UPDATE rules SET enforcement_kind='TRIGGER_FUNCTION', enforcement_artifact='claim_evidence_epistemic_gate:R-004' WHERE rule_id='R-004';
UPDATE rules SET enforcement_kind='TRIGGER_FUNCTION', enforcement_artifact='claim_evidence_epistemic_gate:R-005' WHERE rule_id='R-005';
UPDATE rules SET enforcement_kind='TRIGGER_FUNCTION', enforcement_artifact='claims_score_change_provenance_gate' WHERE rule_id='R-006';
UPDATE rules SET enforcement_kind='TRIGGER_FUNCTION', enforcement_artifact='evidence_cmc_four_full_gate' WHERE rule_id='R-007';
UPDATE rules SET enforcement_kind='TRIGGER_FUNCTION', enforcement_artifact='claim_evidence_epistemic_gate:R-008' WHERE rule_id='R-008';
UPDATE rules SET enforcement_kind='TRIGGER_FUNCTION', enforcement_artifact='claim_evidence_epistemic_gate:R-009' WHERE rule_id='R-009';
UPDATE rules SET enforcement_kind='TRIGGER_FUNCTION', enforcement_artifact='claim_evidence_epistemic_gate:R-004' WHERE rule_id='R-010';
UPDATE rules SET enforcement_kind='RELATIONAL_CONSTRAINT', enforcement_artifact='claim_version_theory_roles+claim_theory_roles canonical role constraints' WHERE rule_id='R-011';
UPDATE rules SET enforcement_kind='RELATIONAL_CONSTRAINT', enforcement_artifact='tri_state_code+scored_or_semantic_code typed domain constraints' WHERE rule_id='R-012';
UPDATE rules SET enforcement_kind='TRIGGER_FUNCTION', enforcement_artifact='approval_authority_gate' WHERE rule_id='R-013';
UPDATE rules SET enforcement_kind='TRIGGER_FUNCTION', enforcement_artifact='claims_score_change_audit_emit' WHERE rule_id='R-014';
UPDATE rules SET enforcement_kind='TRIGGER_FUNCTION', enforcement_artifact='claim_evidence_epistemic_gate:R-015' WHERE rule_id='R-015';

ALTER TABLE rules
  ALTER COLUMN enforcement_kind SET NOT NULL,
  ALTER COLUMN enforcement_artifact SET NOT NULL,
  ADD CONSTRAINT rule_enforcement_artifact_nonblank CHECK (btrim(enforcement_artifact)<>'');

-- Retire the overloaded prose-like expression values for R-011/R-012.
-- expression remains for backwards compatibility but now points to the named enforcement artifact for every rule.
UPDATE rules SET expression=enforcement_artifact;

COMMENT ON TABLE rules IS 'Canonical executable/declarative epistemic rule registry. Human-readable rule artifacts are generated from this table.';
COMMENT ON COLUMN rules.expression IS 'Compatibility alias for enforcement_artifact. New code should use enforcement_kind + enforcement_artifact.';
COMMENT ON COLUMN rules.enforcement_kind IS 'How the rule is enforced: trigger/function, relational constraint, or reconciliation test.';
COMMENT ON COLUMN rules.enforcement_artifact IS 'Named database/test artifact responsible for enforcement. Never free-form scientific rationale.';

COMMIT;
