-- Phase 6: stable identities plus immutable versioned scientific state.
BEGIN;
CREATE TYPE scientific_version_status_code AS ENUM ('DRAFT','FROZEN','SUPERSEDED');
CREATE TABLE theory_versions (
 theory_version_id TEXT PRIMARY KEY,
 theory_id TEXT NOT NULL REFERENCES theories(theory_id),
 specification_version_id TEXT NOT NULL REFERENCES specification_versions(specification_version_id),
 version_label TEXT,
 name TEXT NOT NULL,
 status scientific_version_status_code NOT NULL,
 parent_theory_version_id TEXT REFERENCES theory_versions(theory_version_id),
 rationale TEXT NOT NULL,
 created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
 frozen_at TIMESTAMPTZ,
 UNIQUE(theory_id,specification_version_id),
 CHECK ((status='FROZEN' AND frozen_at IS NOT NULL) OR status<>'FROZEN')
);
CREATE TABLE claim_versions (
 claim_version_id TEXT PRIMARY KEY,
 claim_id TEXT NOT NULL REFERENCES claims(claim_id),
 theory_version_id TEXT NOT NULL REFERENCES theory_versions(theory_version_id),
 specification_version_id TEXT NOT NULL REFERENCES specification_versions(specification_version_id),
 version_label TEXT NOT NULL,
 claim_text TEXT NOT NULL,
 logical_falsifier TEXT NOT NULL,
 operational_test TEXT NOT NULL,
 operational_feasibility SMALLINT NOT NULL CHECK(operational_feasibility BETWEEN 0 AND 4),
 target_relevance_id TEXT NOT NULL REFERENCES target_relevance(target_relevance_id),
 status scientific_version_status_code NOT NULL,
 parent_claim_version_id TEXT REFERENCES claim_versions(claim_version_id),
 rationale TEXT NOT NULL,
 created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
 frozen_at TIMESTAMPTZ,
 UNIQUE(claim_id,specification_version_id),
 CHECK ((status='FROZEN' AND frozen_at IS NOT NULL) OR status<>'FROZEN')
);
CREATE TABLE claim_version_types (
 claim_version_id TEXT NOT NULL REFERENCES claim_versions(claim_version_id),
 claim_type claim_type_code NOT NULL,
 ordinal SMALLINT NOT NULL CHECK(ordinal>0),
 PRIMARY KEY(claim_version_id,claim_type), UNIQUE(claim_version_id,ordinal)
);
CREATE TABLE claim_version_theory_roles (
 claim_version_id TEXT NOT NULL REFERENCES claim_versions(claim_version_id),
 theory_role theory_role_code NOT NULL,
 PRIMARY KEY(claim_version_id,theory_role)
);
CREATE OR REPLACE FUNCTION prevent_frozen_scientific_version_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF OLD.status IN ('FROZEN','SUPERSEDED') THEN RAISE EXCEPTION 'frozen scientific versions are immutable'; END IF;
 RETURN NEW;
END; $$;
CREATE TRIGGER theory_versions_freeze BEFORE UPDATE OR DELETE ON theory_versions FOR EACH ROW EXECUTE FUNCTION prevent_frozen_scientific_version_mutation();
CREATE TRIGGER claim_versions_freeze BEFORE UPDATE OR DELETE ON claim_versions FOR EACH ROW EXECUTE FUNCTION prevent_frozen_scientific_version_mutation();
CREATE OR REPLACE FUNCTION guard_claim_version_child_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE cv TEXT; s scientific_version_status_code;
BEGIN
 cv:=COALESCE(NEW.claim_version_id,OLD.claim_version_id); SELECT status INTO s FROM claim_versions WHERE claim_version_id=cv;
 IF s IS DISTINCT FROM 'DRAFT' THEN RAISE EXCEPTION 'frozen claim-version taxonomy is immutable'; END IF;
 RETURN COALESCE(NEW,OLD);
END; $$;
CREATE TRIGGER claim_version_types_gate BEFORE INSERT OR UPDATE OR DELETE ON claim_version_types FOR EACH ROW EXECUTE FUNCTION guard_claim_version_child_mutation();
CREATE TRIGGER claim_version_roles_gate BEFORE INSERT OR UPDATE OR DELETE ON claim_version_theory_roles FOR EACH ROW EXECUTE FUNCTION guard_claim_version_child_mutation();
CREATE INDEX idx_theory_versions_family ON theory_versions(theory_id);
CREATE INDEX idx_claim_versions_claim ON claim_versions(claim_id);
CREATE INDEX idx_claim_versions_theory ON claim_versions(theory_version_id);
GRANT SELECT ON theory_versions,claim_versions,claim_version_types,claim_version_theory_roles TO cee_app_read,cee_ingest,cee_review,cee_approve,cee_release;
COMMIT;
