-- Consciousness Evidence Engine
-- Physical schema v0.1
-- PostgreSQL 16+

BEGIN;

CREATE TYPE theory_status AS ENUM ('ACTIVE','HISTORICAL','DEPRECATED');
CREATE TYPE claim_type_code AS ENUM ('M','N','S','C','B','P');
CREATE TYPE theory_role_code AS ENUM ('SUB','GEN','INT','ACC','META','BND','PHEN');
CREATE TYPE source_closure_status AS ENUM ('CLOSED','PARTIAL','OPEN');
CREATE TYPE evidence_lifecycle_status AS ENUM ('INGESTED','EXTRACTED','VALIDATED','SCORED','ADVERSARIAL_REVIEW','APPROVED','REJECTED','NEEDS_RESOLUTION');
CREATE TYPE claim_evidence_relationship AS ENUM ('SUPPORT','PRESSURE','CONTRADICTION','COMPATIBILITY','NONE','UNRESOLVED');
CREATE TYPE score_effect_code AS ENUM ('NONE','SUPPORT','PRESSURE','DOWNGRADE','CLOSURE_REQUIRED');
CREATE TYPE review_status_code AS ENUM ('PENDING','APPROVED','REJECTED','NEEDS_RESOLUTION');
CREATE TYPE reviewer_role_code AS ENUM ('EXTRACTOR','SCORER','ADVERSARIAL_REVIEWER','APPROVER');
CREATE TYPE rule_severity_code AS ENUM ('ERROR','BLOCK','WARNING','INFO');
CREATE TYPE tri_state_code AS ENUM ('TRUE','FALSE','ND');
CREATE TYPE scored_or_semantic_code AS ENUM ('0','1','2','3','4','ND','NA');

CREATE TABLE theories (
    theory_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    version_label TEXT,
    description TEXT,
    status theory_status NOT NULL DEFAULT 'ACTIVE'
);

CREATE TABLE target_relevance (
    target_relevance_id TEXT PRIMARY KEY,
    label TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL
);

CREATE TABLE claims (
    claim_id TEXT PRIMARY KEY,
    theory_id TEXT NOT NULL REFERENCES theories(theory_id),
    claim_type claim_type_code NOT NULL,
    target_relevance_id TEXT NOT NULL REFERENCES target_relevance(target_relevance_id),
    claim_text TEXT NOT NULL,
    logical_falsifier TEXT,
    operational_test TEXT,
    operational_feasibility SMALLINT CHECK (operational_feasibility BETWEEN 0 AND 4),
    ps SMALLINT NOT NULL CHECK (ps BETWEEN 0 AND 4),
    ed SMALLINT NOT NULL CHECK (ed BETWEEN 0 AND 4),
    ci SMALLINT NOT NULL CHECK (ci BETWEEN 0 AND 4),
    ir SMALLINT NOT NULL CHECK (ir BETWEEN 0 AND 4),
    rd SMALLINT NOT NULL CHECK (rd BETWEEN 0 AND 4),
    rr SMALLINT NOT NULL CHECK (rr BETWEEN 0 AND 4),
    esi SMALLINT GENERATED ALWAYS AS (ed + ci + ir + rd) STORED,
    sti SMALLINT GENERATED ALWAYS AS (ps + rr) STORED,
    rps SMALLINT GENERATED ALWAYS AS (ed + ci + ir + rd + ps + rr) STORED,
    status theory_status NOT NULL DEFAULT 'ACTIVE'
);

CREATE TABLE claim_theory_roles (
    claim_id TEXT NOT NULL REFERENCES claims(claim_id) ON DELETE CASCADE,
    theory_role theory_role_code NOT NULL,
    PRIMARY KEY (claim_id, theory_role)
);

CREATE TABLE sources (
    source_id TEXT PRIMARY KEY CHECK (source_id ~ '^SRC-[0-9]{3}$'),
    authors TEXT,
    title TEXT NOT NULL,
    venue TEXT,
    year SMALLINT CHECK (year BETWEEN 1800 AND 2200),
    doi TEXT,
    pmid TEXT,
    pmcid TEXT,
    source_class TEXT,
    closure_status source_closure_status NOT NULL DEFAULT 'OPEN',
    notes TEXT
);

CREATE TABLE populations (
    population_id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    translation_framework TEXT
);

CREATE TABLE evidence (
    evidence_id TEXT PRIMARY KEY,
    source_id TEXT NOT NULL REFERENCES sources(source_id),
    population_id TEXT REFERENCES populations(population_id),
    design_class TEXT,
    intervention TEXT,
    sample_or_system TEXT,
    measured_variable TEXT,
    finding TEXT NOT NULL,
    operational_class TEXT,
    causal_manipulation BOOLEAN NOT NULL DEFAULT FALSE,
    preregistered tri_state_code NOT NULL DEFAULT 'ND',
    independent_replication tri_state_code NOT NULL DEFAULT 'ND',
    cmc scored_or_semantic_code NOT NULL DEFAULT 'ND',
    oec scored_or_semantic_code NOT NULL DEFAULT 'NA',
    evidence_status evidence_lifecycle_status NOT NULL DEFAULT 'INGESTED',
    provenance JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE claim_evidence (
    claim_id TEXT NOT NULL REFERENCES claims(claim_id) ON DELETE CASCADE,
    evidence_id TEXT NOT NULL REFERENCES evidence(evidence_id) ON DELETE CASCADE,
    evaluation_version TEXT NOT NULL,
    relationship claim_evidence_relationship NOT NULL,
    target_match BOOLEAN,
    interpretation TEXT NOT NULL,
    score_effect score_effect_code NOT NULL DEFAULT 'NONE',
    proposed_score_change JSONB,
    approved_score_change JSONB,
    review_status review_status_code NOT NULL DEFAULT 'PENDING',
    PRIMARY KEY (claim_id, evidence_id, evaluation_version)
);

CREATE TABLE candidate_records (
    candidate_id UUID PRIMARY KEY,
    source_id TEXT REFERENCES sources(source_id),
    raw_payload JSONB NOT NULL,
    extractor_identity TEXT NOT NULL,
    extractor_version TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    validation_status review_status_code NOT NULL DEFAULT 'PENDING',
    review_status review_status_code NOT NULL DEFAULT 'PENDING'
);

CREATE TABLE review_events (
    review_event_id UUID PRIMARY KEY,
    candidate_id UUID NOT NULL REFERENCES candidate_records(candidate_id) ON DELETE CASCADE,
    reviewer_identity TEXT NOT NULL,
    reviewer_role reviewer_role_code NOT NULL,
    decision review_status_code NOT NULL,
    rationale TEXT NOT NULL,
    structured_scores JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE rules (
    rule_id TEXT PRIMARY KEY CHECK (rule_id ~ '^R-[0-9]{3}$'),
    name TEXT NOT NULL UNIQUE,
    scope TEXT NOT NULL,
    severity rule_severity_code NOT NULL,
    expression TEXT NOT NULL,
    rationale TEXT NOT NULL,
    specification_reference TEXT,
    active_from_version TEXT NOT NULL
);

CREATE TABLE audit_log (
    audit_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    action TEXT NOT NULL,
    old_value JSONB,
    new_value JSONB,
    reason TEXT NOT NULL,
    evidence_id TEXT REFERENCES evidence(evidence_id),
    rule_id TEXT REFERENCES rules(rule_id),
    actor TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Append-only audit log. No UPDATE or DELETE operations are permitted.
CREATE OR REPLACE FUNCTION prevent_audit_mutation()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'audit_log is append-only';
END;
$$;

CREATE TRIGGER audit_log_no_update
BEFORE UPDATE OR DELETE ON audit_log
FOR EACH ROW EXECUTE FUNCTION prevent_audit_mutation();

-- CMC 4 hard gate: causal manipulation is mandatory at the database layer.
CREATE OR REPLACE FUNCTION enforce_cmc_four_causal_gate()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.cmc = '4' AND NEW.causal_manipulation IS NOT TRUE THEN
        RAISE EXCEPTION 'CMC 4 requires causal_manipulation = true';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER evidence_cmc_four_gate
BEFORE INSERT OR UPDATE OF cmc, causal_manipulation ON evidence
FOR EACH ROW EXECUTE FUNCTION enforce_cmc_four_causal_gate();

-- Approved score changes require an approved review state.
CREATE OR REPLACE FUNCTION enforce_approved_score_change_review()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.approved_score_change IS NOT NULL AND NEW.review_status <> 'APPROVED' THEN
        RAISE EXCEPTION 'approved_score_change requires review_status APPROVED';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER claim_evidence_score_change_gate
BEFORE INSERT OR UPDATE OF approved_score_change, review_status ON claim_evidence
FOR EACH ROW EXECUTE FUNCTION enforce_approved_score_change_review();

CREATE INDEX idx_claims_theory ON claims(theory_id);
CREATE INDEX idx_sources_doi ON sources(doi);
CREATE INDEX idx_evidence_source ON evidence(source_id);
CREATE INDEX idx_evidence_population ON evidence(population_id);
CREATE INDEX idx_claim_evidence_evidence ON claim_evidence(evidence_id);
CREATE INDEX idx_audit_entity ON audit_log(entity_type, entity_id);

COMMIT;
