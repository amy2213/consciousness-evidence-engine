BEGIN;

INSERT INTO theories (theory_id, name, version_label, description) VALUES
('GNWT', 'Global Neuronal Workspace Theory', 'baseline', 'Minimal fixture theory for database tests.');

INSERT INTO target_relevance (target_relevance_id, label, description) VALUES
('DIRECT_CONSCIOUSNESS', 'Direct consciousness claim', 'Direct consciousness target.'),
('CONSCIOUSNESS_ADJACENT', 'Consciousness-adjacent mechanism', 'Consciousness-adjacent target.'),
('GENERAL_COGNITIVE', 'General cognitive/perceptual mechanism', 'General cognition target.'),
('SUBSTRATE_ENABLING', 'Substrate-enabling mechanism', 'Substrate target.')
ON CONFLICT (target_relevance_id) DO NOTHING;

INSERT INTO populations (population_id, name, description, translation_framework) VALUES
('ANESTHESIA', 'Anesthesia and emergence', 'Test population.', 'state-transition')
ON CONFLICT (population_id) DO NOTHING;

INSERT INTO claims (
    claim_id, theory_id, claim_type, target_relevance_id, claim_text,
    operational_feasibility, ps, ed, ci, ir, rd, rr
) VALUES (
    'GNW-1', 'GNWT', 'M', 'CONSCIOUSNESS_ADJACENT',
    'Fixture claim preserving v1.1.1 score components for GNW-1.',
    3, 3, 3, 2, 3, 2, 1
);

INSERT INTO claim_theory_roles (claim_id, theory_role) VALUES
('GNW-1', 'ACC');

INSERT INTO sources (
    source_id, authors, title, venue, year, closure_status
) VALUES (
    'SRC-001', 'Fixture', 'Fixture source representing registered source existence', 'Test', 2025, 'CLOSED'
);

INSERT INTO evidence (
    evidence_id, source_id, population_id, finding, causal_manipulation,
    consciousness_sensitive_convergence, preregistered, independent_replication,
    cmc, oec, evidence_status
) VALUES (
    'TEST-BASE-EVIDENCE', 'SRC-001', 'ANESTHESIA', 'Baseline fixture evidence.',
    FALSE, FALSE, 'ND', 'ND', '3', 'NA', 'VALIDATED'
);

COMMIT;
