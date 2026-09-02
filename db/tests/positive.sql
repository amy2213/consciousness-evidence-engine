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

-- P2: AI may propose a score change. Proposal submission itself carries no authority.
INSERT INTO score_change_proposals (
    score_change_id, claim_id, evidence_id, evaluation_version, dimension,
    old_value, proposed_value, rationale, proposed_by, proposed_by_type
) VALUES (
    '00000000-0000-0000-0000-000000000001',
    'GNW-1', 'TEST-BASE-EVIDENCE', 'test-positive', 'ED',
    3, 4, 'Fixture proposal only.', 'test-model', 'AI_MODEL'
);

-- P3: The human decision has an independently queryable provenance event.
INSERT INTO provenance_events (
    provenance_event_id, entity_type, entity_id, actor_type, actor_identity,
    action, metadata
) VALUES (
    '00000000-0000-0000-0000-000000000201',
    'SCORE_CHANGE_PROPOSAL', '00000000-0000-0000-0000-000000000001',
    'HUMAN', 'human-reviewer-1', 'APPROVAL_REVIEW',
    '{"fixture":true}'::jsonb
);

-- P4: A distinct human approver may approve that exact immutable proposal/version.
INSERT INTO approval_events (
    approval_event_id, claim_id, evidence_id, score_change_id, decision,
    approver_identity, approver_actor_type, reviewer_role, approval_scope,
    entity_version, rationale, provenance_event_id
) VALUES (
    '00000000-0000-0000-0000-000000000101',
    'GNW-1', 'TEST-BASE-EVIDENCE', '00000000-0000-0000-0000-000000000001', 'APPROVE',
    'human-reviewer-1', 'HUMAN', 'APPROVER', 'SCORE_CHANGE',
    'test-positive', 'Human fixture approval of exact proposal version.',
    '00000000-0000-0000-0000-000000000201'
);

-- P5: The approved exact proposal can authorize the corresponding canonical score mutation.
UPDATE claims SET ed = 4 WHERE claim_id = 'GNW-1';

-- P6: Semantic ND and NA are accepted and remain distinguishable.
INSERT INTO evidence (
    evidence_id, source_id, population_id, finding, causal_manipulation, causal_manipulation_scope, cmc, oec, evidence_status
) VALUES (
    'TEST-SEMANTIC-NULLS', 'SRC-001', 'ANESTHESIA',
    'Fixture preserving ND versus NA.', 'ND', 'UNRESOLVED', 'ND', 'NA', 'VALIDATED'
);
