BEGIN;

-- Test-only objects must never reuse frozen canonical claim/source identities.
INSERT INTO theories (theory_id, name, status) VALUES
('TEST-THEORY', 'Test Theory', 'ACTIVE');

INSERT INTO target_relevance (target_relevance_id, label, description) VALUES
('TR-TEST', 'Test-only relevance', 'Disposable CI fixture target relevance.');

INSERT INTO claims (
    claim_id, theory_id, target_relevance_id, claim_text,
    operational_feasibility, ps, ed, ci, ir, rd, rr
) VALUES (
    'TEST-CLAIM', 'TEST-THEORY', 'TR-TEST',
    'Disposable fixture claim for database integrity tests.',
    3, 3, 3, 2, 3, 2, 1
);

INSERT INTO claim_claim_types (claim_id, claim_type, ordinal) VALUES
('TEST-CLAIM', 'M', 1);

INSERT INTO claim_theory_roles (claim_id, theory_role) VALUES
('TEST-CLAIM', 'ACC');

INSERT INTO sources (
    source_id, title, source_class, closure_status, source_kind,
    primary_use, registry_text, source_artifact
) VALUES (
    'SRC-999', 'Disposable CI fixture source', 'TEST', 'CLOSED', 'SINGLE_WORK',
    'Database integrity testing only', 'Test-only source; not part of v1.1.1.', 'CI fixture'
);

INSERT INTO evidence (
    evidence_id, source_id, population_id, finding, causal_manipulation,
    consciousness_sensitive_convergence, preregistered, independent_replication,
    cmc, oec, evidence_status, ledger_version
) VALUES (
    'TEST-BASE-EVIDENCE', 'SRC-999', 'ANESTHESIA', 'Baseline fixture evidence.',
    'FALSE', FALSE, 'ND', 'ND', '3', 'NA', 'VALIDATED', 'test-positive'
);

INSERT INTO claim_evidence (
    claim_id, evidence_id, evaluation_version, relationship,
    interpretation, score_effect, review_status
) VALUES (
    'TEST-CLAIM', 'TEST-BASE-EVIDENCE', 'test-positive', 'SUPPORT',
    'Disposable exact claim/evidence/version link for authority tests.', 'SUPPORT', 'PENDING'
);

COMMIT;
