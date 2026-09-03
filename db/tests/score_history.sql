-- Phase 7 score-history invariants. Zero rows = pass.
SELECT 'BASELINE_SCORE_HISTORY_COUNT' AS violation,count(*)::text AS detail
FROM claim_score_snapshots WHERE specification_version_id='v1.1.1' AND snapshot_kind='BASELINE_IMPORT'
HAVING count(*)<>27;

SELECT 'BASELINE_SCORE_HISTORY_DRIFT' AS violation,cbs.claim_id AS detail
FROM claim_baseline_snapshots cbs
JOIN claim_score_snapshots css ON css.claim_id=cbs.claim_id AND css.revision=1
WHERE cbs.ledger_version='v1.1.1'
AND (css.ps,css.ed,css.ci,css.ir,css.rd,css.rr,css.esi,css.sti,css.rps)
 IS DISTINCT FROM
    (cbs.ps,cbs.ed,cbs.ci,cbs.ir,cbs.rd,cbs.rr,cbs.esi,cbs.sti,cbs.rps);

SELECT 'SCORE_HISTORY_WRONG_CLAIM_VERSION' AS violation,css.claim_id AS detail
FROM claim_score_snapshots css JOIN claim_versions cv ON cv.claim_version_id=css.claim_version_id
WHERE cv.claim_id<>css.claim_id OR cv.specification_version_id<>css.specification_version_id;

SELECT 'APPROVED_HISTORY_WITHOUT_EXACT_APPROVAL' AS violation,css.score_snapshot_id::text AS detail
FROM claim_score_snapshots css
LEFT JOIN score_change_proposals scp ON scp.score_change_id=css.score_change_id
LEFT JOIN approval_events ae ON ae.approval_event_id=css.approval_event_id
WHERE css.snapshot_kind='APPROVED_CHANGE'
AND (scp.score_change_id IS NULL OR ae.approval_event_id IS NULL OR ae.score_change_id<>scp.score_change_id
 OR ae.decision<>'APPROVE' OR ae.approver_actor_type<>'HUMAN'
 OR css.evidence_id<>scp.evidence_id OR css.claim_id<>scp.claim_id);

SELECT 'CURRENT_SCORE_VIEW_NOT_LATEST' AS violation,c.claim_id AS detail
FROM claims c
JOIN claim_versions cv ON cv.claim_id=c.claim_id
JOIN current_claim_scores cs ON cs.claim_version_id=cv.claim_version_id
WHERE cv.specification_version_id='v1.1.1'
AND (c.ps,c.ed,c.ci,c.ir,c.rd,c.rr) IS DISTINCT FROM (cs.ps,cs.ed,cs.ci,cs.ir,cs.rd,cs.rr);
