-- Phase 15 structural/reproducibility invariants. Zero rows = pass.

SELECT 'MODEL_RUN_TASK_MISSING' AS violation,v.task AS detail
FROM (VALUES ('EXTRACTION'),('CLASSIFICATION'),('SCORING'),('CONTRADICTION_SCAN'),('SYNTHESIS')) v(task)
WHERE NOT EXISTS (SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid=e.enumtypid WHERE t.typname='model_run_task_code' AND e.enumlabel=v.task);

SELECT 'MODEL_RUN_COLUMN_MISSING' AS violation,v.col AS detail
FROM (VALUES ('provider'),('model_name'),('model_version'),('configuration_hash'),('prompt_or_protocol_id'),('specification_version_id'),('input_hash'),('output_hash'),('run_disposition'),('disposition_provenance_event_id')) v(col)
WHERE NOT EXISTS (SELECT 1 FROM information_schema.columns c WHERE c.table_schema='public' AND c.table_name='model_runs' AND c.column_name=v.col);

SELECT 'MODEL_RUN_TABLE_MISSING' AS violation,v.tbl AS detail
FROM (VALUES ('model_run_references'),('model_run_artifacts'),('authoritative_model_run_links')) v(tbl)
WHERE to_regclass('public.'||v.tbl) IS NULL;

SELECT 'MODEL_RUN_VIEW_MISSING' AS violation,'model_run_trace' AS detail
WHERE to_regclass('public.model_run_trace') IS NULL;

SELECT 'AI_AUTHORITATIVE_LINK_WITHOUT_HUMAN_DISPOSITION' AS violation,aml.authoritative_model_run_link_id::text AS detail
FROM authoritative_model_run_links aml JOIN model_runs mr ON mr.model_run_id=aml.model_run_id
WHERE mr.run_disposition NOT IN ('ACCEPTED_AS_CANDIDATE','REVISED_BY_HUMAN') OR mr.disposition_actor_type IS DISTINCT FROM 'HUMAN';

SELECT 'MODEL_RUN_DISPOSITION_WITHOUT_HUMAN_PROVENANCE' AS violation,mr.model_run_id::text AS detail
FROM model_runs mr LEFT JOIN provenance_events pe ON pe.provenance_event_id=mr.disposition_provenance_event_id
WHERE mr.run_disposition<>'PENDING_HUMAN_REVIEW'
AND (pe.provenance_event_id IS NULL OR pe.actor_type<>'HUMAN' OR pe.actor_identity IS DISTINCT FROM mr.disposition_actor_identity);
