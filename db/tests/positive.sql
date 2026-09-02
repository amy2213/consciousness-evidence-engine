-- Positive fixtures prove that valid states are accepted, not merely that invalid states fail.

-- P1: CMC 4 is accepted when all structural hard-gate requirements are present,
-- including causal manipulation of a consciousness-sensitive variable.
INSERT INTO evidence (
    evidence_id, source_id, population_id, finding,
    causal_manipulation, causal_manipulation_scope, consciousness_sensitive_convergence,
    preregistered, independent_replication, cmc, oec, evidence_status
) VALUES (
    'TEST-CMC4-VALID', 'SRC-001', 'ANESTHESIA', 'Valid CMC4 fixture.',
    'TRUE', 'CONSCIOUSNESS_SENSITIVE_VARIABLE', TRUE, 'TRUE', 'FALSE', '4', 'NA', 'VALIDATED'
);

-- P2: An AI may propose a score change as long as it does not approve itself.
INSERT INTO score_change_proposals (
    score_change_id, claim_id, evidence_id, evaluation_version, dimension,
    old_value, proposed_value, rationale, proposed_by, proposed_by_type
) VALUES (
    '00000000-0000-0000-0000-000000000001',
    'GNW-1', 'TEST-BASE-EVIDENCE', 'test-positive', 'ED',
    3, 4, 'Fixture proposal only.', 'test-model', 'AI_MODEL'
);

-- P3: Semantic ND and NA are accepted and remain distinguishable.
INSERT INTO evidence (
    evidence_id, source_id, population_id, finding, causal_manipulation, causal_manipulation_scope, cmc, oec, evidence_status
) VALUES (
    'TEST-SEMANTIC-NULLS', 'SRC-001', 'ANESTHESIA',
    'Fixture preserving ND versus NA.', 'ND', 'UNRESOLVED', 'ND', 'NA', 'VALIDATED'
);
