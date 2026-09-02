-- Phase 3 approval architecture reconciliation. Zero rows = pass.

-- No authoritative approval event may have a non-human actor.
SELECT 'NON_HUMAN_APPROVAL_EVENT' AS violation, approval_event_id::text AS detail
FROM approval_events
WHERE approver_actor_type <> 'HUMAN';

-- Every authoritative approval event must use the approver role and carry a version.
SELECT 'INVALID_APPROVAL_ROLE_OR_VERSION' AS violation, approval_event_id::text AS detail
FROM approval_events
WHERE reviewer_role <> 'APPROVER' OR btrim(entity_version) = '';

-- Proposal rows must remain proposal-only.
SELECT 'MUTABLE_DECISION_STATE_ON_PROPOSAL' AS violation, score_change_id::text AS detail
FROM score_change_proposals
WHERE review_status <> 'PENDING'
   OR approved_value IS NOT NULL
   OR approved_by IS NOT NULL
   OR approved_at IS NOT NULL;

-- Score approvals must bind to a real proposal and its exact evaluation version.
SELECT 'SCORE_APPROVAL_VERSION_DRIFT' AS violation, ae.approval_event_id::text AS detail
FROM approval_events ae
JOIN score_change_proposals scp ON scp.score_change_id = ae.score_change_id
WHERE ae.approval_scope='SCORE_CHANGE'
  AND ae.entity_version <> scp.evaluation_version;

-- Reviewer independence: proposer cannot be authoritative approver of the same proposal.
SELECT 'SCORE_SELF_APPROVAL' AS violation, ae.approval_event_id::text AS detail
FROM approval_events ae
JOIN score_change_proposals scp ON scp.score_change_id = ae.score_change_id
WHERE ae.approval_scope='SCORE_CHANGE'
  AND ae.approver_identity = scp.proposed_by;

-- Approved evidence must have an exact-version human approval event.
SELECT 'APPROVED_EVIDENCE_WITHOUT_HUMAN_EVENT' AS violation, e.evidence_id AS detail
FROM evidence e
WHERE e.evidence_status='APPROVED'
  AND NOT EXISTS (
      SELECT 1 FROM approval_events ae
      WHERE ae.evidence_id=e.evidence_id
        AND ae.approval_scope='EVIDENCE_PROMOTION'
        AND ae.decision='APPROVE'
        AND ae.approver_actor_type='HUMAN'
        AND ae.entity_version=COALESCE(e.ledger_version,'unversioned')
  );
