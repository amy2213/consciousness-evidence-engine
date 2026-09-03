-- Phase 14 structural invariants. Zero rows = pass.

SELECT 'CANDIDATE_PIPELINE_TABLE_MISSING' AS violation,v.table_name AS detail
FROM (VALUES ('candidate_stage_events'),('candidate_validations'),('candidate_duplicate_checks'),('candidate_evidence_proposals'),('candidate_score_proposals'),('candidate_rule_evaluations'),('candidate_adversarial_reviews'),('candidate_authoritative_commits')) v(table_name)
WHERE to_regclass('public.'||v.table_name) IS NULL;

SELECT 'AI_AUTHORITATIVE_CANDIDATE_COMMIT' AS violation,cac.candidate_id::text AS detail
FROM candidate_authoritative_commits cac
JOIN approval_events ae ON ae.approval_event_id=cac.approval_event_id
WHERE ae.approver_actor_type<>'HUMAN' OR ae.approval_scope<>'CANDIDATE_PROMOTION' OR ae.decision<>'APPROVE';

SELECT 'COMMITTED_WITHOUT_CANONICAL_EVIDENCE' AS violation,c.candidate_id::text AS detail
FROM candidate_records c
WHERE c.current_stage='COMMITTED' AND (c.committed_evidence_id IS NULL OR NOT EXISTS (SELECT 1 FROM evidence e WHERE e.evidence_id=c.committed_evidence_id));

SELECT 'CANDIDATE_PIPELINE_STAGE_DRIFT' AS violation,c.candidate_id::text AS detail
FROM candidate_records c
WHERE c.current_stage='COMMITTED' AND NOT EXISTS (SELECT 1 FROM candidate_authoritative_commits cac WHERE cac.candidate_id=c.candidate_id);
