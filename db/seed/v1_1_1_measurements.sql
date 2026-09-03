-- Phase 10: conservative measurement migration from frozen v1.1.1 evidence.
-- One baseline measurement row is created per atomic evidence record. Source wording is preserved.
BEGIN;

INSERT INTO measurements(
 measurement_id,measurement_type,label,description,measurement_type_code,operational_target,
 acquisition_modality,timing,task_report_dependence,state_sensitive,content_sensitive,
 validation_context_id,consciousness_specificity,consciousness_specificity_rationale,
 causal_status,replication_status,legacy_operational_class
)
SELECT
 'MEAS-'||e.evidence_id,
 COALESCE(e.operational_class,'Unspecified'),
 COALESCE(e.measured_variable,'Measurement not separately specified in frozen ledger'),
 'Measurement representation migrated from frozen v1.1.1 evidence record '||e.evidence_id||'.',
 CASE
   WHEN lower(COALESCE(e.measured_variable,'')) LIKE '%pci%' OR lower(COALESCE(e.measured_variable,'')) LIKE '%perturbational complexity%' OR lower(COALESCE(e.operational_class,'')) LIKE '%tms-eeg%' THEN 'PERTURBATIONAL_COMPLEXITY'::measurement_type_code
   WHEN lower(COALESCE(e.measured_variable,'')) LIKE '%connect%' OR lower(COALESCE(e.measured_variable,'')) LIKE '%transfer%' THEN 'CONNECTIVITY'::measurement_type_code
   WHEN lower(COALESCE(e.measured_variable,'')) LIKE '%report%' THEN 'IMMEDIATE_REPORT'::measurement_type_code
   WHEN lower(COALESCE(e.measured_variable,'')) LIKE '%fMRI%' OR lower(COALESCE(e.measured_variable,'')) LIKE '%eeg%' OR lower(COALESCE(e.operational_class,'')) LIKE '%fmri%' OR lower(COALESCE(e.operational_class,'')) LIKE '%eeg%' THEN 'PHYSIOLOGICAL_SIGNAL'::measurement_type_code
   WHEN lower(COALESCE(e.operational_class,'')) LIKE '%behavior%' OR lower(COALESCE(e.measured_variable,'')) LIKE '%behavior%' OR lower(COALESCE(e.measured_variable,'')) LIKE '%verbal%' OR lower(COALESCE(e.measured_variable,'')) LIKE '%manual%' THEN 'BEHAVIORAL_RESPONSIVENESS'::measurement_type_code
   WHEN lower(COALESCE(e.operational_class,'')) LIKE '%model%' THEN 'MODEL_DERIVED'::measurement_type_code
   ELSE 'OTHER'::measurement_type_code
 END,
 CASE
   WHEN e.population_id='DOC_CMD' THEN 'ACCESS'::operational_target_code
   WHEN e.population_id='SPLIT_BRAIN' THEN 'BOUNDARY'::operational_target_code
   WHEN e.evidence_id='AN-006' THEN 'SUBSTRATE_MECHANISM'::operational_target_code
   WHEN lower(COALESCE(e.measured_variable,'')) LIKE '%dream%' OR lower(COALESCE(e.measured_variable,'')) LIKE '%content%' THEN 'CONSCIOUS_CONTENT'::operational_target_code
   WHEN lower(COALESCE(e.operational_class,'')) LIKE '%pci%' OR lower(COALESCE(e.measured_variable,'')) LIKE '%complexity%' THEN 'CAUSAL_INTEGRATION'::operational_target_code
   ELSE 'UNRESOLVED'::operational_target_code
 END,
 e.operational_class,
 NULL,
 CASE
   WHEN e.population_id='DOC_CMD' AND e.asymmetry_role='ACTIVE_TEST' THEN 'ACTIVE_TASK'::task_report_dependence_code
   WHEN lower(COALESCE(e.operational_class,'')) LIKE '%report%' THEN 'IMMEDIATE_REPORT'::task_report_dependence_code
   ELSE 'UNRESOLVED'::task_report_dependence_code
 END,
 CASE WHEN e.population_id IN ('ANESTHESIA','SLEEP','DOC_CMD') THEN 'TRUE'::tri_state_code ELSE 'ND'::tri_state_code END,
 CASE WHEN lower(COALESCE(e.measured_variable,'')) LIKE '%content%' OR lower(COALESCE(e.measured_variable,'')) LIKE '%dream%' THEN 'TRUE'::tri_state_code ELSE 'ND'::tri_state_code END,
 NULL,
 CASE
   WHEN e.evidence_id IN ('AN-001','SL-001','SL-002','SL-005','SL-006') THEN 'CANDIDATE'::consciousness_specificity_code
   WHEN e.evidence_id='AN-006' THEN 'NONE'::consciousness_specificity_code
   ELSE 'INDIRECT'::consciousness_specificity_code
 END,
 CASE
   WHEN e.evidence_id IN ('AN-001','SL-001','SL-002','SL-005','SL-006') THEN 'Frozen ledger explicitly links this measurement to experience reports or conscious benchmark states, but does not establish a theory-neutral consciousness criterion.'
   WHEN e.evidence_id='AN-006' THEN 'Frozen ledger explicitly states that no consciousness-dependent variable was measured.'
   ELSE 'Frozen ledger supports an indirect or consciousness-adjacent interpretation only; no direct consciousness measurement is asserted.'
 END,
 CASE
   WHEN e.asymmetry_role='METHODOLOGICAL_RULE' THEN 'METHODOLOGICAL'::measurement_causal_status_code
   WHEN e.causal_manipulation='TRUE' THEN 'PERTURBATIONAL'::measurement_causal_status_code
   WHEN e.causal_manipulation='FALSE' THEN 'OBSERVATIONAL'::measurement_causal_status_code
   ELSE 'UNRESOLVED'::measurement_causal_status_code
 END,
 CASE
   WHEN e.preregistered='TRUE' AND e.independent_replication='TRUE' THEN 'BOTH'::measurement_replication_status_code
   WHEN e.preregistered='TRUE' THEN 'PREREGISTERED'::measurement_replication_status_code
   WHEN e.independent_replication='TRUE' THEN 'INDEPENDENT_REPLICATION'::measurement_replication_status_code
   WHEN e.preregistered='ND' OR e.independent_replication='ND' THEN 'ND'::measurement_replication_status_code
   ELSE 'NONE_REPORTED'::measurement_replication_status_code
 END,
 e.operational_class
FROM evidence e
WHERE e.ledger_version='v1.1.1'
ON CONFLICT (measurement_id) DO NOTHING;

INSERT INTO evidence_measurements(evidence_id,measurement_id,measured_variable,finding_locator,interpretation_boundary,ordinal)
SELECT e.evidence_id,'MEAS-'||e.evidence_id,e.measured_variable,e.source_locator,
       'Measurement and finding are preserved separately from claim interpretation; this link does not itself establish consciousness.',1
FROM evidence e
WHERE e.ledger_version='v1.1.1'
ON CONFLICT (evidence_id,measurement_id) DO NOTHING;

COMMIT;
