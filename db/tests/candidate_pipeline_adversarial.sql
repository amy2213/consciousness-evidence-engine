-- Phase 14 adversarial checks: AI proposals remain quarantined and canonical gates cannot be skipped.

CREATE OR REPLACE FUNCTION candidate_expect_failure(label text,sql_text text,expected_message text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE msg text; BEGIN
 BEGIN EXECUTE sql_text; EXCEPTION WHEN OTHERS THEN GET STACKED DIAGNOSTICS msg=MESSAGE_TEXT;
  IF position(expected_message in msg)=0 THEN RAISE EXCEPTION 'candidate pipeline % failed for wrong reason: %',label,msg; END IF;
  RAISE NOTICE 'PASS %: %',label,msg; RETURN;
 END;
 RAISE EXCEPTION 'candidate pipeline % unexpectedly succeeded',label;
END;$$;

INSERT INTO provenance_events(provenance_event_id,entity_type,entity_id,actor_type,actor_identity,action,metadata)
VALUES ('00000000-0000-0000-0000-000000001401','CANDIDATE','00000000-0000-0000-0000-000000001410','AI_MODEL','test-ai-extractor','EXTRACT','{"phase":14}'::jsonb);
INSERT INTO candidate_records(candidate_id,source_id,raw_payload,extractor_identity,extractor_version,candidate_hash,parent_source_hash,provenance_event_id)
VALUES ('00000000-0000-0000-0000-000000001410','SRC-999','{"finding":"candidate"}'::jsonb,'test-ai-extractor','test-model','candidate-hash','source-hash','00000000-0000-0000-0000-000000001401');

SELECT candidate_expect_failure('CANNOT_SKIP_STRUCTURAL_GATE',
$q$INSERT INTO candidate_stage_events(candidate_stage_event_id,candidate_id,from_stage,to_stage,actor_type,actor_identity,rationale,provenance_event_id) VALUES ('00000000-0000-0000-0000-000000001411','00000000-0000-0000-0000-000000001410','EXTRACTED','PROVENANCE_VALIDATED','AI_MODEL','test-ai-extractor','hostile skip','00000000-0000-0000-0000-000000001401')$q$,
'candidate stage transition cannot skip canonical ingestion gates');

SELECT candidate_expect_failure('STRUCTURAL_PASS_REQUIRED',
$q$INSERT INTO candidate_stage_events(candidate_stage_event_id,candidate_id,from_stage,to_stage,actor_type,actor_identity,rationale,provenance_event_id) VALUES ('00000000-0000-0000-0000-000000001412','00000000-0000-0000-0000-000000001410','EXTRACTED','STRUCTURALLY_VALIDATED','AI_MODEL','test-ai-extractor','hostile no validation','00000000-0000-0000-0000-000000001401')$q$,
'structural validation PASS required');

SELECT candidate_expect_failure('AI_CANNOT_APPROVE_CANDIDATE',
$q$INSERT INTO approval_events(approval_event_id,candidate_id,decision,approver_identity,approver_actor_type,reviewer_role,approval_scope,entity_version,scope_hash,rationale,provenance_event_id) VALUES ('00000000-0000-0000-0000-000000001413','00000000-0000-0000-0000-000000001410','APPROVE','test-ai-extractor','AI_MODEL','APPROVER','CANDIDATE_PROMOTION','test-positive','x','hostile AI approval','00000000-0000-0000-0000-000000001401')$q$,
'authoritative approval decisions require HUMAN actor type');

SELECT candidate_expect_failure('AI_CANNOT_DIRECTLY_INSERT_EVIDENCE',
$q$SET LOCAL ROLE cee_ingest; INSERT INTO evidence(evidence_id,source_id,finding,cmc,oec,evidence_status) VALUES ('RC-AI-EVIDENCE','SRC-999','hostile direct canonical write','0','NA','INGESTED')$q$,
'permission denied');

SELECT candidate_expect_failure('AI_CANNOT_DIRECTLY_INSERT_APPROVAL',
$q$SET LOCAL ROLE cee_ingest; INSERT INTO approval_events(approval_event_id,candidate_id,decision,approver_identity,approval_scope,entity_version,rationale,provenance_event_id) VALUES ('00000000-0000-0000-0000-000000001414','00000000-0000-0000-0000-000000001410','APPROVE','fake-human','CANDIDATE_DISPOSITION','test','bad','00000000-0000-0000-0000-000000001401')$q$,
'permission denied');

DROP FUNCTION candidate_expect_failure(text,text,text);
