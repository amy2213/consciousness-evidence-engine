-- Normalize causal_manipulation from Boolean to the engine tri-state vocabulary.
-- FALSE means explicitly determined absent; ND means applicable but not determined.

BEGIN;

DROP TRIGGER IF EXISTS evidence_cmc_four_full_gate ON evidence;

ALTER TABLE evidence
    ALTER COLUMN causal_manipulation DROP DEFAULT;

ALTER TABLE evidence
    ALTER COLUMN causal_manipulation TYPE tri_state_code
    USING (CASE
        WHEN causal_manipulation IS TRUE THEN 'TRUE'::tri_state_code
        WHEN causal_manipulation IS FALSE THEN 'FALSE'::tri_state_code
        ELSE 'ND'::tri_state_code
    END);

ALTER TABLE evidence
    ALTER COLUMN causal_manipulation SET DEFAULT 'FALSE'::tri_state_code,
    ALTER COLUMN causal_manipulation SET NOT NULL;

COMMENT ON COLUMN evidence.causal_manipulation IS
'Tri-state causal-manipulation status. TRUE = explicitly present; FALSE = explicitly absent; ND = applicable but not determined from the source-locked record.';

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
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER evidence_cmc_four_full_gate
BEFORE INSERT OR UPDATE OF cmc, causal_manipulation, consciousness_sensitive_convergence, preregistered, independent_replication ON evidence
FOR EACH ROW EXECUTE FUNCTION enforce_cmc_four_full_gate();

COMMIT;
