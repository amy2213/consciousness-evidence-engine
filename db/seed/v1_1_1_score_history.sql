-- Phase 7 baseline score history derived exactly from immutable v1.1.1 snapshots.
BEGIN;
INSERT INTO claim_score_snapshots(
 score_snapshot_id,claim_id,claim_version_id,specification_version_id,revision,snapshot_kind,
 ps,ed,ci,ir,rd,rr,evaluator_identity,evaluator_actor_type,rationale
)
SELECT
 md5('v1.1.1-score:'||cbs.claim_id)::uuid,
 cbs.claim_id,'CV-'||cbs.claim_id||'-v1.1.1','v1.1.1',1,'BASELINE_IMPORT',
 cbs.ps,cbs.ed,cbs.ci,cbs.ir,cbs.rd,cbs.rr,
 'v1.1.1 frozen ledger import','IMPORT','Exact score state imported from immutable v1.1.1 baseline snapshot.'
FROM claim_baseline_snapshots cbs
WHERE cbs.ledger_version='v1.1.1'
ON CONFLICT DO NOTHING;
COMMIT;
