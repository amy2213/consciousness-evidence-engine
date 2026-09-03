-- Phase 10 measurement invariants. Zero rows = pass.

-- Every frozen atomic evidence record currently migrated must have a canonical measurement link.
SELECT 'MISSING_BASELINE_MEASUREMENT' AS violation,e.evidence_id AS detail
FROM evidence e
WHERE e.ledger_version='v1.1.1'
AND NOT EXISTS (
 SELECT 1 FROM evidence_measurements em WHERE em.evidence_id=e.evidence_id
);

-- Frozen measured-variable wording must survive the migration exactly where present.
SELECT 'MEASURED_VARIABLE_DRIFT' AS violation,e.evidence_id AS detail
FROM evidence e
JOIN evidence_measurements em ON em.evidence_id=e.evidence_id AND em.ordinal=1
WHERE e.ledger_version='v1.1.1'
AND em.measured_variable IS DISTINCT FROM e.measured_variable;

-- A validated consciousness-specific measure must carry explicit validation context and rationale.
SELECT 'UNSUPPORTED_VALIDATED_CONSCIOUSNESS_MEASURE' AS violation,measurement_id AS detail
FROM measurements
WHERE consciousness_specificity='VALIDATED'
AND (validation_context_id IS NULL OR btrim(consciousness_specificity_rationale)='');

-- Substrate-only AN-006 must never be represented as a consciousness measurement.
SELECT 'AN006_MEASUREMENT_OVERCLAIM' AS violation,measurement_id AS detail
FROM measurements
WHERE measurement_id='MEAS-AN-006'
AND (operational_target<>'SUBSTRATE_MECHANISM' OR consciousness_specificity<>'NONE');

-- DoC active paradigms are task-dependent access measurements, not automatic phenomenal measures.
SELECT 'DOC_ACTIVE_TASK_SEMANTIC_DRIFT' AS violation,m.measurement_id AS detail
FROM measurements m
JOIN evidence_measurements em ON em.measurement_id=m.measurement_id
JOIN evidence e ON e.evidence_id=em.evidence_id
WHERE e.population_id='DOC_CMD' AND e.asymmetry_role='ACTIVE_TEST'
AND (m.task_report_dependence<>'ACTIVE_TASK' OR m.operational_target<>'ACCESS');

-- No measurement may claim phenomenal/consciousness specificity merely from being neural/behavioral.
SELECT 'MEASUREMENT_INTERPRETATION_COLLAPSE' AS violation,measurement_id AS detail
FROM measurements
WHERE consciousness_specificity='VALIDATED'
AND operational_target IN ('GENERAL_COGNITION','SUBSTRATE_MECHANISM');

-- Every canonical measurement link must state the interpretation boundary.
SELECT 'MISSING_MEASUREMENT_BOUNDARY' AS violation,evidence_id||':'||measurement_id AS detail
FROM evidence_measurements
WHERE btrim(COALESCE(interpretation_boundary,''))='';
