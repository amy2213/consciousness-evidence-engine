-- Phase 3 approval architecture reconciliation. Zero rows = pass.

SELECT 'NON_HUMAN_APPROVAL_EVENT' AS violation, approval_event_id::text AS detail
FROM approval_events WHERE approver_actor_type <> 'HUMAN';

SELECT 'INVALID_APPROVAL_ROLE_OR_VERSION' AS violation, approval_event_id::text AS detail
FROM approval_events WHERE reviewer_role <> 'APPROVER' OR btrim(entity_version) = '';

SELECT 'MUTABLE_DECISION_STATE_ON_PROPOSAL' AS violation, score_change_id::text AS detail
FROM score_change_proposals
WHERE review_status <> 'PENDING' OR approved_value IS NOT NULL OR approved_by IS NOT NULL OR approved_at IS NOT NULL;

SELECT 'SCORE_APPROVAL_SCOPE_DRIFT' AS violation, ae.approval_event_id::text AS detail
FROM approval_events ae
JOIN score_change_proposals scp ON scp.score_change_id = ae.score_change_id
WHERE ae.approval_scope='SCORE_CHANGE'
  AND (ae.entity_version <> scp.evaluation_version
       OR ae.claim_id IS DISTINCT FROM scp.claim_id
       OR ae.evidence_id IS DISTINCT FROM scp.evidence_id);

SELECT 'SCORE_SELF_APPROVAL' AS violation, ae.approval_event_id::text AS detail
FROM approval_events ae
JOIN score_change_proposals scp ON scp.score_change_id = ae.score_change_id
WHERE ae.approval_scope='SCORE_CHANGE' AND ae.approver_identity = scp.proposed_by;

SELECT 'SCORE_PROPOSAL_WITHOUT_EXACT_LINK' AS violation, scp.score_change_id::text AS detail
FROM score_change_proposals scp
LEFT JOIN claim_evidence ce
  ON ce.claim_id=scp.claim_id AND ce.evidence_id=scp.evidence_id AND ce.evaluation_version=scp.evaluation_version
WHERE ce.claim_id IS NULL;

SELECT 'APPROVED_SCORE_WITH_UNAPPROVED_EVIDENCE' AS violation, ae.approval_event_id::text AS detail
FROM approval_events ae
JOIN score_change_proposals scp ON scp.score_change_id=ae.score_change_id
JOIN evidence e ON e.evidence_id=scp.evidence_id
WHERE ae.approval_scope='SCORE_CHANGE' AND ae.decision='APPROVE' AND e.evidence_status <> 'APPROVED';

SELECT 'APPROVED_SCORE_WITH_NON_DIRECTIONAL_LINK' AS violation, ae.approval_event_id::text AS detail
FROM approval_events ae
JOIN score_change_proposals scp ON scp.score_change_id=ae.score_change_id
JOIN claim_evidence ce
  ON ce.claim_id=scp.claim_id AND ce.evidence_id=scp.evidence_id AND ce.evaluation_version=scp.evaluation_version
WHERE ae.approval_scope='SCORE_CHANGE' AND ae.decision='APPROVE' AND ce.relationship NOT IN ('SUPPORT','PRESSURE');

SELECT 'APPROVED_EVIDENCE_WITHOUT_HUMAN_EVENT' AS violation, e.evidence_id AS detail
FROM evidence e
WHERE e.evidence_status='APPROVED'
  AND NOT EXISTS (
      SELECT 1 FROM approval_events ae
      WHERE ae.evidence_id=e.evidence_id AND ae.approval_scope='EVIDENCE_PROMOTION'
        AND ae.decision='APPROVE' AND ae.approver_actor_type='HUMAN'
        AND ae.entity_version=COALESCE(e.ledger_version,'unversioned')
  );

SELECT 'APPROVAL_PROVENANCE_ACTOR_DRIFT' AS violation, ae.approval_event_id::text AS detail
FROM approval_events ae
JOIN provenance_events pe ON pe.provenance_event_id=ae.provenance_event_id
WHERE pe.actor_type <> 'HUMAN' OR pe.actor_identity <> ae.approver_identity;

SELECT 'APPROVED_SCORE_WITHOUT_AUDIT' AS violation, ae.approval_event_id::text AS detail
FROM approval_events ae
JOIN score_change_proposals scp ON scp.score_change_id=ae.score_change_id
WHERE ae.approval_scope='SCORE_CHANGE' AND ae.decision='APPROVE'
  AND NOT EXISTS (
      SELECT 1 FROM audit_log al
      WHERE al.entity_type='CLAIM_SCORE'
        AND al.entity_id=scp.claim_id || ':' || scp.dimension::text
        AND al.evidence_id=scp.evidence_id
        AND al.actor=ae.approver_identity
  );
