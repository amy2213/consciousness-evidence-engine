-- Phase 3: authoritative approval architecture.
-- Proposals are immutable facts. Decisions are separate append-only events.
-- AI/SYSTEM/IMPORT actors may assist or propose but may never issue authoritative decisions.

BEGIN;

CREATE TYPE approval_scope_code AS ENUM (
    'CANDIDATE_DISPOSITION',
    'EVIDENCE_PROMOTION',
    'SCORE_CHANGE',
    'SOURCE_CLOSURE',
    'CLAIM_REVISION',
    'RELEASE_CERTIFICATION'
);

ALTER TABLE approval_events
    ADD COLUMN approver_actor_type provenance_actor_type NOT NULL DEFAULT 'HUMAN',
    ADD COLUMN reviewer_role reviewer_role_code NOT NULL DEFAULT 'APPROVER',
    ADD COLUMN approval_scope approval_scope_code,
    ADD COLUMN score_change_id UUID REFERENCES score_change_proposals(score_change_id),
    ADD COLUMN entity_version TEXT,
    ADD COLUMN scope_hash TEXT;

-- Backfill legacy rows conservatively if any exist before enforcing exact scope fields.
UPDATE approval_events
SET approval_scope = CASE
        WHEN candidate_id IS NOT NULL THEN 'CANDIDATE_DISPOSITION'::approval_scope_code
        WHEN evidence_id IS NOT NULL THEN 'EVIDENCE_PROMOTION'::approval_scope_code
        ELSE 'CLAIM_REVISION'::approval_scope_code
    END,
    entity_version = COALESCE(entity_version, 'legacy-unversioned');

ALTER TABLE approval_events
    ALTER COLUMN approval_scope SET NOT NULL,
    ALTER COLUMN entity_version SET NOT NULL,
    ADD CONSTRAINT approval_human_actor_only CHECK (approver_actor_type = 'HUMAN'),
    ADD CONSTRAINT approval_reviewer_role_only CHECK (reviewer_role = 'APPROVER'),
    ADD CONSTRAINT approval_rationale_nonblank CHECK (btrim(rationale) <> ''),
    ADD CONSTRAINT approval_entity_version_nonblank CHECK (btrim(entity_version) <> ''),
    ADD CONSTRAINT approval_scope_target_check CHECK (
        (approval_scope = 'CANDIDATE_DISPOSITION' AND candidate_id IS NOT NULL AND evidence_id IS NULL AND score_change_id IS NULL)
        OR
        (approval_scope = 'EVIDENCE_PROMOTION' AND evidence_id IS NOT NULL AND candidate_id IS NULL AND score_change_id IS NULL)
        OR
        (approval_scope = 'SCORE_CHANGE' AND score_change_id IS NOT NULL AND candidate_id IS NULL)
        OR
        (approval_scope IN ('SOURCE_CLOSURE','CLAIM_REVISION','RELEASE_CERTIFICATION') AND candidate_id IS NULL AND score_change_id IS NULL)
    );

-- The proposal row must contain no authoritative decision state. A changed value requires a new proposal.
ALTER TABLE score_change_proposals
    ADD CONSTRAINT score_proposal_decision_state_forbidden CHECK (
        review_status = 'PENDING'
        AND approved_value IS NULL
        AND approved_by IS NULL
        AND approved_at IS NULL
    );

COMMENT ON TABLE score_change_proposals IS
'Immutable submitted score-change proposals. Authoritative decisions live only in approval_events.';
COMMENT ON COLUMN score_change_proposals.review_status IS
'Legacy field retained for migration compatibility; must remain PENDING. Decision state lives in approval_events.';
COMMENT ON COLUMN score_change_proposals.approved_value IS
'Deprecated decision field; must remain NULL. A modified value requires a new proposal and a separate approval_event.';
COMMENT ON TABLE approval_events IS
'Append-only authoritative human decision events. AI_MODEL, SYSTEM, and IMPORT actors cannot create authoritative approvals or rejections.';
COMMENT ON COLUMN approval_events.entity_version IS
'Exact specification/evaluation/entity version to which this decision applies.';
COMMENT ON COLUMN approval_events.scope_hash IS
'Optional immutable hash binding the decision to an exact reviewed payload or scope manifest.';

DROP TRIGGER IF EXISTS score_change_approval_actor_gate ON score_change_proposals;
DROP FUNCTION IF EXISTS enforce_score_change_approval_actor();

CREATE OR REPLACE FUNCTION prevent_score_proposal_mutation()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'score_change_proposals are immutable after submission';
END;
$$;

CREATE TRIGGER score_change_proposal_no_update_delete
BEFORE UPDATE OR DELETE ON score_change_proposals
FOR EACH ROW EXECUTE FUNCTION prevent_score_proposal_mutation();

CREATE OR REPLACE FUNCTION prevent_approval_event_mutation()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'approval_events are append-only';
END;
$$;

CREATE TRIGGER approval_event_no_update_delete
BEFORE UPDATE OR DELETE ON approval_events
FOR EACH ROW EXECUTE FUNCTION prevent_approval_event_mutation();

-- Enforce reviewer independence for score-change decisions and bind the decision to exact proposal scope.
CREATE OR REPLACE FUNCTION enforce_approval_authority()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    proposer_identity TEXT;
BEGIN
    IF NEW.approver_actor_type <> 'HUMAN' THEN
        RAISE EXCEPTION 'authoritative approval decisions require HUMAN actor type';
    END IF;
    IF NEW.reviewer_role <> 'APPROVER' THEN
        RAISE EXCEPTION 'authoritative approval decisions require APPROVER reviewer role';
    END IF;
    IF NEW.approval_scope = 'SCORE_CHANGE' THEN
        SELECT proposed_by INTO proposer_identity
        FROM score_change_proposals
        WHERE score_change_id = NEW.score_change_id;
        IF proposer_identity IS NULL THEN
            RAISE EXCEPTION 'score-change approval requires an existing immutable proposal';
        END IF;
        IF proposer_identity = NEW.approver_identity THEN
            RAISE EXCEPTION 'score-change proposer cannot approve their own proposal';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER approval_authority_gate
BEFORE INSERT ON approval_events
FOR EACH ROW EXECUTE FUNCTION enforce_approval_authority();

-- Authoritative claim score mutation now depends on a separate HUMAN approval_event,
-- never mutable state on the proposal row itself.
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
                JOIN approval_events ae ON ae.score_change_id = scp.score_change_id
                WHERE scp.claim_id = NEW.claim_id
                  AND scp.dimension::text = dim
                  AND scp.old_value = oldv
                  AND scp.proposed_value = newv
                  AND ae.approval_scope = 'SCORE_CHANGE'
                  AND ae.decision = 'APPROVE'
                  AND ae.approver_actor_type = 'HUMAN'
                  AND ae.entity_version = scp.evaluation_version
            ) THEN
                RAISE EXCEPTION 'Claim % dimension % cannot change from % to % without separate HUMAN approval_event for exact proposal version', NEW.claim_id, dim, oldv, newv;
            END IF;
        END IF;
    END LOOP;
    RETURN NEW;
END;
$$;

-- Evidence promotion requires a human, version-scoped evidence approval event.
CREATE OR REPLACE FUNCTION enforce_evidence_approval_event()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.evidence_status = 'APPROVED' THEN
        IF NOT EXISTS (
            SELECT 1 FROM approval_events ae
            WHERE ae.evidence_id = NEW.evidence_id
              AND ae.approval_scope = 'EVIDENCE_PROMOTION'
              AND ae.decision = 'APPROVE'
              AND ae.approver_actor_type = 'HUMAN'
              AND ae.entity_version = COALESCE(NEW.ledger_version, 'unversioned')
        ) THEN
            RAISE EXCEPTION 'APPROVED evidence requires separate HUMAN approval_event for exact evidence version';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE INDEX idx_approval_score_change ON approval_events(score_change_id);
CREATE INDEX idx_approval_scope_version ON approval_events(approval_scope, entity_version);

COMMIT;
