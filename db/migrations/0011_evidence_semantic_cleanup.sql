-- Phase 2 semantic cleanup.
-- Distinguish active-test asymmetry from methodological rules about asymmetry,
-- and distinguish causal intervention presence from the scientific scope of that intervention.

BEGIN;

CREATE TYPE evidence_asymmetry_role AS ENUM (
    'NONE',
    'ACTIVE_TEST',
    'METHODOLOGICAL_RULE'
);

CREATE TYPE causal_manipulation_scope AS ENUM (
    'NONE',
    'SUBSTRATE_MECHANISM_ONLY',
    'CONSCIOUSNESS_LINKED_SYSTEM',
    'CONSCIOUSNESS_SENSITIVE_VARIABLE',
    'UNRESOLVED'
);

ALTER TABLE evidence
    ADD COLUMN asymmetry_role evidence_asymmetry_role NOT NULL DEFAULT 'NONE',
    ADD COLUMN governed_negative_inference_cmc_cap SMALLINT CHECK (governed_negative_inference_cmc_cap BETWEEN 0 AND 4),
    ADD COLUMN causal_manipulation_scope causal_manipulation_scope NOT NULL DEFAULT 'NONE';

-- Preserve any pre-existing asymmetric rows as active tests by default, then apply the
-- source-locked semantic correction for the two methodological records if already present.
UPDATE evidence
SET asymmetry_role = 'ACTIVE_TEST'
WHERE asymmetric_inference IS TRUE;

UPDATE evidence
SET asymmetry_role = 'METHODOLOGICAL_RULE',
    governed_negative_inference_cmc_cap = negative_inference_cmc_cap,
    negative_inference_cmc_cap = NULL
WHERE evidence_id IN ('DC-007','DC-008')
  AND asymmetric_inference IS TRUE;

-- Existing causal TRUE rows are not silently assigned a stronger scientific meaning.
UPDATE evidence
SET causal_manipulation_scope = 'UNRESOLVED'
WHERE causal_manipulation = 'TRUE';

-- AN-006 is explicitly a substrate assay: intervention exists, but no consciousness-sensitive
-- dependent variable is manipulated or causally isolated.
UPDATE evidence
SET causal_manipulation_scope = 'SUBSTRATE_MECHANISM_ONLY'
WHERE evidence_id = 'AN-006';

ALTER TABLE evidence
    DROP CONSTRAINT IF EXISTS asymmetric_evidence_requires_cap,
    DROP CONSTRAINT IF EXISTS nonasymmetric_evidence_has_no_cap,
    DROP COLUMN asymmetric_inference;

ALTER TABLE evidence
    ADD CONSTRAINT active_test_asymmetry_requires_cap CHECK (
        asymmetry_role <> 'ACTIVE_TEST' OR
        (negative_inference_cmc_cap IS NOT NULL AND governed_negative_inference_cmc_cap IS NULL)
    ),
    ADD CONSTRAINT methodological_asymmetry_requires_governed_cap CHECK (
        asymmetry_role <> 'METHODOLOGICAL_RULE' OR
        (governed_negative_inference_cmc_cap IS NOT NULL AND negative_inference_cmc_cap IS NULL)
    ),
    ADD CONSTRAINT no_asymmetry_has_no_caps CHECK (
        asymmetry_role <> 'NONE' OR
        (negative_inference_cmc_cap IS NULL AND governed_negative_inference_cmc_cap IS NULL)
    ),
    ADD CONSTRAINT causal_scope_matches_presence CHECK (
        (causal_manipulation = 'FALSE' AND causal_manipulation_scope = 'NONE') OR
        (causal_manipulation = 'ND' AND causal_manipulation_scope IN ('NONE','UNRESOLVED')) OR
        (causal_manipulation = 'TRUE' AND causal_manipulation_scope <> 'NONE')
    );

COMMENT ON COLUMN evidence.asymmetry_role IS
'NONE = no asymmetric inference rule encoded; ACTIVE_TEST = this evidence item itself is a paradigm whose positive and negative results license different inferences; METHODOLOGICAL_RULE = this evidence item establishes a rule governing asymmetric inference but is not itself the active test.';

COMMENT ON COLUMN evidence.negative_inference_cmc_cap IS
'Maximum CMC permitted for an absence-of-consciousness inference from a negative result of this ACTIVE_TEST evidence paradigm.';

COMMENT ON COLUMN evidence.governed_negative_inference_cmc_cap IS
'Maximum negative-inference CMC established by a METHODOLOGICAL_RULE evidence item for paradigms it governs; it is not a cap on a negative result of the methodological record itself.';

COMMENT ON COLUMN evidence.causal_manipulation_scope IS
'Scientific scope of a causal intervention, separate from whether an intervention occurred. SUBSTRATE_MECHANISM_ONLY cannot satisfy a consciousness-sensitive causal bridge.';

-- CMC4 keeps all prior hard gates and now also requires the causal intervention to reach a
-- consciousness-sensitive variable rather than merely perturbing an upstream substrate.
CREATE OR REPLACE FUNCTION enforce_cmc_four_full_gate()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.cmc = '4' THEN
        IF NEW.causal_manipulation <> 'TRUE' THEN
            RAISE EXCEPTION 'CMC 4 requires causal manipulation';
        END IF;
        IF NEW.consciousness_sensitive_convergence IS NOT TRUE THEN
            RAISE EXCEPTION 'CMC 4 requires convergent consciousness-sensitive measurement';
        END IF;
        IF NEW.preregistered <> 'TRUE' AND NEW.independent_replication <> 'TRUE' THEN
            RAISE EXCEPTION 'CMC 4 requires preregistration or independent replication';
        END IF;
        IF NEW.causal_manipulation_scope <> 'CONSCIOUSNESS_SENSITIVE_VARIABLE' THEN
            RAISE EXCEPTION 'CMC 4 requires causal manipulation of a consciousness-sensitive variable';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS evidence_cmc_four_full_gate ON evidence;
CREATE TRIGGER evidence_cmc_four_full_gate
BEFORE INSERT OR UPDATE OF cmc, causal_manipulation, causal_manipulation_scope,
    consciousness_sensitive_convergence, preregistered, independent_replication ON evidence
FOR EACH ROW EXECUTE FUNCTION enforce_cmc_four_full_gate();

COMMIT;
