-- Phase 5: formal specification and release entities.
-- Released scientific state is versioned, hashable, supersedable, and immutable after certification.

BEGIN;

CREATE TYPE specification_status_code AS ENUM ('DRAFT','FROZEN','SUPERSEDED');
CREATE TYPE dataset_release_status_code AS ENUM ('DRAFT','CERTIFIED','PUBLISHED','SUPERSEDED');
CREATE TYPE release_member_type_code AS ENUM (
    'CLAIM','SOURCE','BIBLIOGRAPHIC_WORK','EVIDENCE','CLAIM_EVIDENCE','RULE','OTHER'
);
CREATE TYPE erratum_status_code AS ENUM ('OPEN','RESOLVED','SUPERSEDED');

CREATE TABLE specification_versions (
    specification_version_id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    status specification_status_code NOT NULL,
    source_artifact TEXT NOT NULL,
    source_artifact_hash TEXT,
    parent_specification_version_id TEXT REFERENCES specification_versions(specification_version_id),
    rationale TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    frozen_at TIMESTAMPTZ,
    CHECK ((status='FROZEN' AND frozen_at IS NOT NULL) OR (status<>'FROZEN'))
);

CREATE TABLE dataset_releases (
    release_id TEXT PRIMARY KEY,
    specification_version_id TEXT NOT NULL REFERENCES specification_versions(specification_version_id),
    status dataset_release_status_code NOT NULL DEFAULT 'DRAFT',
    manifest_hash TEXT,
    git_commit_sha TEXT,
    supersedes_release_id TEXT REFERENCES dataset_releases(release_id),
    rationale TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    certified_at TIMESTAMPTZ,
    published_at TIMESTAMPTZ,
    CHECK ((status IN ('CERTIFIED','PUBLISHED','SUPERSEDED') AND manifest_hash IS NOT NULL AND certified_at IS NOT NULL)
        OR status='DRAFT'),
    CHECK ((status='PUBLISHED' AND published_at IS NOT NULL) OR status<>'PUBLISHED'),
    CHECK (supersedes_release_id IS NULL OR supersedes_release_id <> release_id)
);

CREATE TABLE release_membership (
    release_id TEXT NOT NULL REFERENCES dataset_releases(release_id) ON DELETE RESTRICT,
    member_type release_member_type_code NOT NULL,
    member_id TEXT NOT NULL,
    member_version TEXT NOT NULL,
    content_hash TEXT NOT NULL,
    ordinal INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (release_id, member_type, member_id, member_version),
    CHECK (btrim(member_id) <> ''),
    CHECK (btrim(member_version) <> ''),
    CHECK (btrim(content_hash) <> '')
);

CREATE TABLE release_errata (
    erratum_id UUID PRIMARY KEY,
    release_id TEXT NOT NULL REFERENCES dataset_releases(release_id) ON DELETE RESTRICT,
    member_type release_member_type_code,
    member_id TEXT,
    description TEXT NOT NULL,
    rationale TEXT NOT NULL,
    status erratum_status_code NOT NULL DEFAULT 'OPEN',
    superseded_by_erratum_id UUID REFERENCES release_errata(erratum_id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at TIMESTAMPTZ,
    CHECK (btrim(description) <> ''),
    CHECK (btrim(rationale) <> ''),
    CHECK ((status='RESOLVED' AND resolved_at IS NOT NULL) OR status<>'RESOLVED')
);

-- Bind release certification approval to an exact release.
ALTER TABLE approval_events ADD COLUMN release_id TEXT REFERENCES dataset_releases(release_id);

ALTER TABLE approval_events DROP CONSTRAINT approval_scope_target_check;
ALTER TABLE approval_events ADD CONSTRAINT approval_scope_target_check CHECK (
    (approval_scope = 'CANDIDATE_DISPOSITION' AND candidate_id IS NOT NULL AND evidence_id IS NULL AND score_change_id IS NULL AND release_id IS NULL)
    OR
    (approval_scope = 'EVIDENCE_PROMOTION' AND evidence_id IS NOT NULL AND candidate_id IS NULL AND score_change_id IS NULL AND release_id IS NULL)
    OR
    (approval_scope = 'SCORE_CHANGE' AND score_change_id IS NOT NULL AND candidate_id IS NULL AND release_id IS NULL)
    OR
    (approval_scope = 'RELEASE_CERTIFICATION' AND release_id IS NOT NULL AND candidate_id IS NULL AND score_change_id IS NULL)
    OR
    (approval_scope IN ('SOURCE_CLOSURE','CLAIM_REVISION') AND candidate_id IS NULL AND score_change_id IS NULL AND release_id IS NULL)
);

CREATE OR REPLACE FUNCTION prevent_frozen_specification_mutation()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.status IN ('FROZEN','SUPERSEDED') THEN
        RAISE EXCEPTION 'frozen specification versions are immutable';
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER specification_versions_freeze
BEFORE UPDATE OR DELETE ON specification_versions
FOR EACH ROW EXECUTE FUNCTION prevent_frozen_specification_mutation();

CREATE OR REPLACE FUNCTION guard_release_membership_mutation()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    target_release TEXT;
    target_status dataset_release_status_code;
BEGIN
    target_release := COALESCE(NEW.release_id, OLD.release_id);
    SELECT status INTO target_status FROM dataset_releases WHERE release_id=target_release;
    IF target_status IS DISTINCT FROM 'DRAFT' THEN
        RAISE EXCEPTION 'release membership is immutable after certification';
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$;
CREATE TRIGGER release_membership_mutation_gate
BEFORE INSERT OR UPDATE OR DELETE ON release_membership
FOR EACH ROW EXECUTE FUNCTION guard_release_membership_mutation();

CREATE OR REPLACE FUNCTION enforce_release_status_transition()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP='DELETE' THEN
        IF OLD.status <> 'DRAFT' THEN
            RAISE EXCEPTION 'certified release history is immutable';
        END IF;
        RETURN OLD;
    END IF;

    IF OLD.status IN ('CERTIFIED','PUBLISHED','SUPERSEDED') THEN
        -- Post-certification only monotonic lifecycle transitions are legal.
        IF OLD.status='CERTIFIED' AND NEW.status NOT IN ('CERTIFIED','PUBLISHED','SUPERSEDED') THEN
            RAISE EXCEPTION 'certified release cannot return to draft';
        ELSIF OLD.status='PUBLISHED' AND NEW.status NOT IN ('PUBLISHED','SUPERSEDED') THEN
            RAISE EXCEPTION 'published release cannot regress';
        ELSIF OLD.status='SUPERSEDED' AND NEW IS DISTINCT FROM OLD THEN
            RAISE EXCEPTION 'superseded release is immutable';
        END IF;

        IF NEW.specification_version_id IS DISTINCT FROM OLD.specification_version_id
           OR NEW.manifest_hash IS DISTINCT FROM OLD.manifest_hash
           OR NEW.git_commit_sha IS DISTINCT FROM OLD.git_commit_sha
           OR NEW.supersedes_release_id IS DISTINCT FROM OLD.supersedes_release_id
           OR NEW.rationale IS DISTINCT FROM OLD.rationale
           OR NEW.created_at IS DISTINCT FROM OLD.created_at
           OR NEW.certified_at IS DISTINCT FROM OLD.certified_at THEN
            RAISE EXCEPTION 'certified release scientific identity is immutable';
        END IF;
    END IF;

    IF OLD.status='DRAFT' AND NEW.status IN ('CERTIFIED','PUBLISHED','SUPERSEDED') THEN
        IF NEW.manifest_hash IS NULL OR btrim(NEW.manifest_hash)='' THEN
            RAISE EXCEPTION 'release certification requires manifest_hash';
        END IF;
        IF NOT EXISTS (
            SELECT 1 FROM approval_events ae
            WHERE ae.release_id=NEW.release_id
              AND ae.approval_scope='RELEASE_CERTIFICATION'
              AND ae.decision='APPROVE'
              AND ae.approver_actor_type='HUMAN'
              AND ae.entity_version=NEW.specification_version_id
        ) THEN
            RAISE EXCEPTION 'release certification requires exact HUMAN RELEASE_CERTIFICATION approval';
        END IF;
        NEW.certified_at := COALESCE(NEW.certified_at, now());
    END IF;

    RETURN NEW;
END;
$$;
CREATE TRIGGER dataset_release_status_gate
BEFORE UPDATE OR DELETE ON dataset_releases
FOR EACH ROW EXECUTE FUNCTION enforce_release_status_transition();

-- Extend approval authority with exact release/version binding.
CREATE OR REPLACE FUNCTION enforce_release_approval_scope()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    spec_id TEXT;
BEGIN
    IF NEW.approval_scope='RELEASE_CERTIFICATION' THEN
        SELECT specification_version_id INTO spec_id
        FROM dataset_releases WHERE release_id=NEW.release_id;
        IF spec_id IS NULL THEN
            RAISE EXCEPTION 'release certification approval requires existing release';
        END IF;
        IF NEW.entity_version IS DISTINCT FROM spec_id THEN
            RAISE EXCEPTION 'release certification approval version must match release specification version';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER release_approval_scope_gate
BEFORE INSERT ON approval_events
FOR EACH ROW EXECUTE FUNCTION enforce_release_approval_scope();

-- Freeze the source specification baseline. This is not yet a certified dataset release.
INSERT INTO specification_versions (
    specification_version_id,title,status,source_artifact,rationale,frozen_at
) VALUES (
    'v1.1.1','Consciousness Evidence Map: Claim Ledger v1.1.1','FROZEN',
    'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx',
    'Frozen human-readable scientific specification baseline.', now()
);

-- Release manager can construct draft releases; human approver remains separate authority.
GRANT INSERT ON dataset_releases, release_membership, release_errata TO cee_release;
GRANT UPDATE (status, manifest_hash, git_commit_sha, supersedes_release_id, rationale, published_at) ON dataset_releases TO cee_release;
GRANT UPDATE (status, superseded_by_erratum_id, resolved_at) ON release_errata TO cee_release;
GRANT SELECT ON specification_versions, dataset_releases, release_membership, release_errata TO cee_app_read, cee_ingest, cee_review, cee_approve, cee_release;

CREATE INDEX idx_release_specification ON dataset_releases(specification_version_id);
CREATE INDEX idx_release_membership_release ON release_membership(release_id);
CREATE INDEX idx_release_errata_release ON release_errata(release_id);
CREATE INDEX idx_approval_release ON approval_events(release_id);

COMMIT;
