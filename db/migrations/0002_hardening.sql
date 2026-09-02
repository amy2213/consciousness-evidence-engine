-- Consciousness Evidence Engine
-- Migration 0002: hostile-schema hardening
-- PostgreSQL 16+

BEGIN;

CREATE TYPE score_dimension_code AS ENUM ('PS','ED','CI','IR','RD','RR');
CREATE TYPE provenance_actor_type AS ENUM ('HUMAN','AI_MODEL','IMPORT','SYSTEM');
CREATE TYPE approval_decision_code AS ENUM ('APPROVE','REJECT','RETURN_FOR_RESOLUTION');

-- Normalize score changes. JSON may describe context, but it may not carry the authoritative delta.
CREATE TABLE score_change_proposals (
    score_change_id UUID PRIMARY KEY,
    claim_id TEXT NOT NULL REFERENCES claims(claim_id) ON DELETE CASCADE,
    evidence_id TEXT NOT NULL REFERENCES evidence(evidence_id) ON DELETE CASCADE,
    evaluation_version TEXT NOT NULL,
    dimension score_dimension_code NOT NULL,
    old_value SMALLINT NOT NULL CHECK (old_value BETWEEN 0 AND 4),
    proposed_value SMALLINT NOT NULL CHECK (proposed_value BETWEEN 0 AND 4),
    rationale TEXT NOT NULL,
    proposed_by TEXT NOT NULL,
    proposed_by_type provenance_actor_type NOT NULL,
    review_status review_status_code NOT NULL DEFAULT 'PENDING',
    approved_value SMALLINT CHECK (approved_value BETWEEN 0 AND 4),
    approved_by TEXT,
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (claim_id, evidence_id, evaluation_version, dimension),
    CHECK (proposed_value <> old_value),
    CHECK (
        (review_status = 'APPROVED' AND approved_value IS NOT NULL AND approved_by IS NOT NULL AND approved_at IS NOT NULL)
        OR
        (review_status <> 'APPROVED' AND approved_value IS NULL AND approved_by IS NULL AND approved_at IS NULL)
    )
);

-- Explicit provenance events. The raw candidate payload remains available, but provenance is queryable.
CREATE TABLE provenance_events (
    provenance_event_id UUID PRIMARY KEY,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    actor_type provenance_actor_type NOT NULL,
    actor_identity TEXT NOT NULL,
    actor_version TEXT,
    action TEXT NOT NULL,
    source_uri TEXT,
    source_locator TEXT,
    content_hash TEXT,
    parent_event_id UUID REFERENCES provenance_events(provenance_event_id),
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Approval decisions are first-class events, not a mutable flag with no explanation.
CREATE TABLE approval_events (
    approval_event_id UUID PRIMARY KEY,
    candidate_id UUID REFERENCES candidate_records(candidate_id) ON DELETE CASCADE,
    claim_id TEXT REFERENCES claims(claim_id),
    evidence_id TEXT REFERENCES evidence(evidence_id),
    decision approval_decision_code NOT NULL,
    approver_identity TEXT NOT NULL,
    rationale TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (candidate_id IS NOT NULL OR evidence_id IS NOT NULL)
);

-- The old JSON score fields are now explicitly non-authoritative and may not be used for approved changes.
ALTER TABLE claim_evidence
    ADD COLUMN score_change_summary TEXT;

COMMENT ON COLUMN claim_evidence.proposed_score_change IS
'Legacy/non-authoritative context only. Authoritative dimension changes live in score_change_proposals.';
COMMENT ON COLUMN claim_evidence.approved_score_change IS
'Deprecated. Must remain NULL. Authoritative approved changes live in score_change_proposals.';

ALTER TABLE claim_evidence
    ADD CONSTRAINT approved_score_change_json_must_be_null
    CHECK (approved_score_change IS NULL);

-- AI can propose changes but cannot approve them.
CREATE OR REPLACE FUNCTION enforce_score_change_approval_actor()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.review_status = 'APPROVED' THEN
        IF NEW.proposed_by_type = 'AI_MODEL' AND NEW.approved_by = NEW.proposed_by THEN
            RAISE EXCEPTION 'AI proposer cannot self-approve a score change';
        END IF;
        IF NEW.approved_value IS DISTINCT FROM NEW.proposed_value AND NEW.rationale IS NULL THEN
            RAISE EXCEPTION 'modified approval requires rationale';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER score_change_approval_actor_gate
BEFORE INSERT OR UPDATE ON score_change_proposals
FOR EACH ROW EXECUTE FUNCTION enforce_score_change_approval_actor();

-- Full CMC 4 hard gate: causal manipulation plus convergence and preregistration/replication.
ALTER TABLE evidence
    ADD COLUMN consciousness_sensitive_convergence BOOLEAN NOT NULL DEFAULT FALSE;

CREATE OR REPLACE FUNCTION enforce_cmc_four_full_gate()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.cmc = '4' THEN
        IF NEW.causal_manipulation IS NOT TRUE THEN
            RAISE EXCEPTION 'CMC 4 requires causal manipulation';
        END IF;
        IF NEW.consciousness_sensitive_convergence IS NOT TRUE THEN
            RAISE EXCEPTION 'CMC 4 requires convergent consciousness-sensitive measurement';
        END IF;
        IF NEW.preregistered <> 'TRUE' AND NEW.independent_replication <> 'TRUE' THEN
            RAISE EXCEPTION 'CMC 4 requires preregistration or independent replication';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS evidence_cmc_four_gate ON evidence;
DROP FUNCTION IF EXISTS enforce_cmc_four_causal_gate();

CREATE TRIGGER evidence_cmc_four_full_gate
BEFORE INSERT OR UPDATE OF cmc, causal_manipulation, consciousness_sensitive_convergence, preregistered, independent_replication ON evidence
FOR EACH ROW EXECUTE FUNCTION enforce_cmc_four_full_gate();

-- Approved canonical evidence must have at least one approval event.
CREATE OR REPLACE FUNCTION enforce_evidence_approval_event()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.evidence_status = 'APPROVED' THEN
        IF NOT EXISTS (
            SELECT 1 FROM approval_events ae
            WHERE ae.evidence_id = NEW.evidence_id
              AND ae.decision = 'APPROVE'
        ) THEN
            RAISE EXCEPTION 'APPROVED evidence requires an approval_event';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE CONSTRAINT TRIGGER evidence_requires_approval_event
AFTER INSERT OR UPDATE OF evidence_status ON evidence
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION enforce_evidence_approval_event();

-- No direct dimension change may occur without a matching approved score-change proposal.
CREATE OR REPLACE FUNCTION enforce_claim_score_change_provenance()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    dim TEXT;
    oldv SMALLINT;
    newv SMALLINT;
BEGIN
    FOREACH dim IN ARRAY ARRAY['PS','ED','CI','IR','RD','RR'] LOOP
        EXECUTE format('SELECT ($1).%I, ($2).%I', lower(dim), lower(dim)) INTO oldv, newv USING OLD, NEW;
        IF oldv IS DISTINCT FROM newv THEN
            IF NOT EXISTS (
                SELECT 1
                FROM score_change_proposals scp
                WHERE scp.claim_id = NEW.claim_id
                  AND scp.dimension::text = dim
                  AND scp.old_value = oldv
                  AND scp.approved_value = newv
                  AND scp.review_status = 'APPROVED'
            ) THEN
                RAISE EXCEPTION 'Claim % dimension % cannot change from % to % without approved score_change_proposal', NEW.claim_id, dim, oldv, newv;
            END IF;
        END IF;
    END LOOP;
    RETURN NEW;
END;
$$;

CREATE TRIGGER claims_score_change_provenance_gate
BEFORE UPDATE OF ps, ed, ci, ir, rd, rr ON claims
FOR EACH ROW EXECUTE FUNCTION enforce_claim_score_change_provenance();

CREATE INDEX idx_score_change_claim ON score_change_proposals(claim_id);
CREATE INDEX idx_score_change_evidence ON score_change_proposals(evidence_id);
CREATE INDEX idx_provenance_entity ON provenance_events(entity_type, entity_id);
CREATE INDEX idx_approval_evidence ON approval_events(evidence_id);

COMMIT;
