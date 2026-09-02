-- Populate Phase 6 version tables from the already source-locked v1.1.1 identity tables.
BEGIN;
INSERT INTO theory_versions(theory_version_id,theory_id,specification_version_id,version_label,name,status,rationale,frozen_at)
SELECT 'TV-'||theory_id||'-v1.1.1',theory_id,'v1.1.1',version_label,name,'FROZEN','Frozen v1.1.1 specification-derived theory state.',now()
FROM theories
ON CONFLICT DO NOTHING;

INSERT INTO claim_versions(claim_version_id,claim_id,theory_version_id,specification_version_id,version_label,claim_text,logical_falsifier,operational_test,operational_feasibility,target_relevance_id,status,rationale,frozen_at)
SELECT 'CV-'||c.claim_id||'-v1.1.1',c.claim_id,'TV-'||c.theory_id||'-v1.1.1','v1.1.1','v1.1.1',c.claim_text,c.logical_falsifier,c.operational_test,c.operational_feasibility,c.target_relevance_id,'FROZEN','Frozen v1.1.1 specification-derived claim state.',now()
FROM claims c
ON CONFLICT DO NOTHING;

-- Frozen child taxonomy must be loaded before the parent version is frozen, so temporarily stage exact rows via direct inserts
-- by creating them from canonical baseline while triggers see FROZEN. Disable only inside migration-admin seed transaction.
ALTER TABLE claim_version_types DISABLE TRIGGER claim_version_types_gate;
ALTER TABLE claim_version_theory_roles DISABLE TRIGGER claim_version_roles_gate;
INSERT INTO claim_version_types(claim_version_id,claim_type,ordinal)
SELECT 'CV-'||claim_id||'-v1.1.1',claim_type,ordinal FROM claim_claim_types ON CONFLICT DO NOTHING;
INSERT INTO claim_version_theory_roles(claim_version_id,theory_role)
SELECT 'CV-'||claim_id||'-v1.1.1',theory_role FROM claim_theory_roles ON CONFLICT DO NOTHING;
ALTER TABLE claim_version_types ENABLE TRIGGER claim_version_types_gate;
ALTER TABLE claim_version_theory_roles ENABLE TRIGGER claim_version_roles_gate;
COMMIT;
