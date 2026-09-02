BEGIN;

-- Canonical theory, target-relevance, population, and source rows are loaded before this
-- fixture. This file creates only the minimal claim/evidence records needed by the
-- generic positive and adversarial integrity tests.

INSERT INTO claims (
    claim_id, theory_id, target_relevance_id, claim_text,
    operational_feasibility, ps, ed, ci, ir, rd, rr
) VALUES (
    'GNW-1', 'GNWT', 'TR-CA-MECH',
    'Fixture claim preserving v1.1.1 score components for GNW-1.',
    3, 3, 3, 2, 3, 2, 1
);

INSERT INTO claim_claim_types (claim_id, claim_type, ordinal) VALUES
('GNW-1', 'M', 1);

INSERT INTO claim_theory_roles (claim_id, theory_role) VALUES
('GNW-1', 'ACC');

INSERT INTO evidence (
    evidence_id, source_id, population_id, finding, causal_manipulation,
    consciousness_sensitive_convergence, preregistered, independent_replication,
    cmc, oec, evidence_status
) VALUES (
    'TEST-BASE-EVIDENCE', 'SRC-001', 'ANESTHESIA', 'Baseline fixture evidence.',
    FALSE, FALSE, 'ND', 'ND', '3', 'NA', 'VALIDATED'
);

COMMIT;
