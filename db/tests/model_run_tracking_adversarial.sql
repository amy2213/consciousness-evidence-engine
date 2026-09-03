-- Phase 15 hostile model-run tracking checks.
CREATE OR REPLACE FUNCTION model_run_expect_failure(label TEXT,sql_text TEXT,expected TEXT) RETURNS void LANGUAGE plpgsql AS $$
BEGIN EXECUTE sql_text; RAISE EXCEPTION 'EXPECTED FAILURE DID NOT OCCUR: %',label;
EXCEPTION WHEN OTHERS THEN IF SQLERRM LIKE 'EXPECTED FAILURE DID NOT OCCUR:%' THEN RAISE; END IF; IF position(expected in SQLERRM)=0 THEN RAISE EXCEPTION 'WRONG FAILURE %: %',label,SQLERRM; END IF; RAISE NOTICE 'PASS %: %',label,SQLERRM; END;$$;

INSERT INTO provenance_events(provenance_event_id,entity_type,entity_id,actor_type,actor_identity,action,metadata)
VALUES ('00000000-0000-0000-0000-000000000930','MODEL_RUN','00000000-0000-0000-0000-000000000931','HUMAN','model-run-reviewer','MODEL_RUN_DISPOSITION','{"fixture":true}');

INSERT INTO model_runs(model_run_id,actor_identity,actor_version,provider,model_name,model_version,task_type,specification_version_id,input_hash,output_hash,configuration_hash,prompt_or_protocol_id,run_disposition)
VALUES ('00000000-0000-0000-0000-000000000931','test-model','1','fixture-provider','fixture-model','1','EXTRACTION','test-positive','input-hash','output-hash','config-hash','fixture-protocol','PENDING_HUMAN_REVIEW');

-- Exact reason matters: model output cannot acquire a non-pending disposition unless a HUMAN provenance event matches the disposition actor.
SELECT model_run_expect_failure('MODEL_CANNOT_SELF_DISPOSE',
$$UPDATE model_runs SET run_disposition='ACCEPTED_AS_CANDIDATE',disposition_actor_type='AI_MODEL',disposition_actor_identity='test-model',disposition_rationale='self approval',disposition_provenance_event_id='00000000-0000-0000-0000-000000000930' WHERE model_run_id='00000000-0000-0000-0000-000000000931'$$,
'model-run disposition requires matching HUMAN provenance event');

SELECT model_run_expect_failure('AUTHORITATIVE_LINK_REQUIRES_HUMAN_DISPOSITION',
$$INSERT INTO authoritative_model_run_links(authoritative_model_run_link_id,model_run_id,entity_type,entity_id,relationship,human_disposition_provenance_event_id,rationale) VALUES ('00000000-0000-0000-0000-000000000932','00000000-0000-0000-0000-000000000931','EVIDENCE','TEST-BASE-EVIDENCE','INFORMED','00000000-0000-0000-0000-000000000930','hostile')$$,
'authoritative AI/model-run link requires explicit human disposition');

UPDATE model_runs SET run_disposition='ACCEPTED_AS_CANDIDATE',disposition_actor_type='HUMAN',disposition_actor_identity='model-run-reviewer',disposition_rationale='human reviewed model output',disposition_provenance_event_id='00000000-0000-0000-0000-000000000930' WHERE model_run_id='00000000-0000-0000-0000-000000000931';

INSERT INTO authoritative_model_run_links(authoritative_model_run_link_id,model_run_id,entity_type,entity_id,relationship,human_disposition_provenance_event_id,rationale)
VALUES ('00000000-0000-0000-0000-000000000933','00000000-0000-0000-0000-000000000931','EVIDENCE','TEST-BASE-EVIDENCE','INFORMED','00000000-0000-0000-0000-000000000930','Human disposition explicitly binds model-assisted candidate work to fixture evidence.');

SELECT model_run_expect_failure('MODEL_RUN_AUTHORITY_LINK_APPEND_ONLY',
$$DELETE FROM authoritative_model_run_links WHERE authoritative_model_run_link_id='00000000-0000-0000-0000-000000000933'$$,
'authoritative_model_run_links is append-only model-run history');

DROP FUNCTION model_run_expect_failure(TEXT,TEXT,TEXT);
