-- Phase 4: database privilege hardening.
-- Application identities receive least privilege. Authoritative scientific tables are not directly writable.

BEGIN;

-- Group roles are NOLOGIN by design. Deployment-specific login identities may be granted one role each.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='cee_app_read') THEN CREATE ROLE cee_app_read NOLOGIN; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='cee_ingest') THEN CREATE ROLE cee_ingest NOLOGIN; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='cee_review') THEN CREATE ROLE cee_review NOLOGIN; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='cee_approve') THEN CREATE ROLE cee_approve NOLOGIN; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='cee_release') THEN CREATE ROLE cee_release NOLOGIN; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='cee_migration_admin') THEN CREATE ROLE cee_migration_admin NOLOGIN; END IF;
END
$$;

REVOKE CREATE ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC;
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;

GRANT USAGE ON SCHEMA public TO cee_app_read, cee_ingest, cee_review, cee_approve, cee_release, cee_migration_admin;

-- Read access is broad because the project is public and review requires context.
GRANT SELECT ON ALL TABLES IN SCHEMA public TO cee_app_read, cee_ingest, cee_review, cee_approve, cee_release;

-- Candidate ingestion can create candidates only. It cannot write canonical evidence, claims, scores, approvals, or history.
GRANT INSERT ON candidate_records TO cee_ingest;

-- Review can append review events, but cannot approve or mutate authoritative scientific state.
GRANT INSERT ON review_events TO cee_review;

-- Approval identities may append the provenance record and approval decision needed by the human-only authority gate.
-- They still cannot UPDATE claims/evidence directly; score/evidence transitions occur through controlled application paths later.
GRANT INSERT ON provenance_events, approval_events TO cee_approve;

-- Release role is intentionally read-only until formal release entities land in Phase 5.
-- Privileges for those future tables must be granted explicitly in the migration that creates them.

-- Migration administration owns schema evolution. This role is never an application identity.
GRANT CREATE ON SCHEMA public TO cee_migration_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO cee_migration_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO cee_migration_admin;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO cee_migration_admin;

-- Future objects fail closed: PUBLIC gets nothing and ordinary roles do not silently inherit write access.
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON SEQUENCES FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

COMMENT ON ROLE cee_app_read IS 'Read-only application role.';
COMMENT ON ROLE cee_ingest IS 'Candidate-ingestion role; may append candidate_records only.';
COMMENT ON ROLE cee_review IS 'Scientific review role; may append review_events only.';
COMMENT ON ROLE cee_approve IS 'Human approval role; may append provenance_events and approval_events only.';
COMMENT ON ROLE cee_release IS 'Release-management role; read-only until formal release entities exist.';
COMMENT ON ROLE cee_migration_admin IS 'Schema/migration administration role; never assigned to application or AI identities.';

COMMIT;
