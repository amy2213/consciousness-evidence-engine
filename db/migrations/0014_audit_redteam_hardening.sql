-- Audit-derived hardening for already-built authority/provenance layers.
-- This migration does not yet implement the later Phase 10-12 semantic rule engine.

BEGIN;

-- R-006 tightening: a score proposal must point to the exact evaluated claim/evidence/version tuple.
ALTER TABLE score_change_proposals
    ADD CONSTRAINT scp_claim_evidence_fk
    FOREIGN KEY (claim_id, evidence_id, evaluation_version)
    REFERENCES claim_evidence (claim_id, evidence_id, evaluation_version);

-- Provenance history is immutable just like approval history.
CREATE OR REPLACE FUNCTION prevent_provenance_event_mutation()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'provenance_events are append-only';
END;
$$;

CREATE TRIGGER provenance_event_no_update_delete
BEFORE UPDATE OR DELETE ON provenance_events
FOR EACH ROW EXECUTE FUNCTION prevent_provenance_event_mutation();

-- Tighten score-change approval authority to exact scope and approved evidence.
CREATE OR REPLACE FUNCTION enforce_approval_authority()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    proposer_identity TEXT;
    prov_actor_type provenance_actor_type;
    prov_actor_identity TEXT;
    proposal_claim_id TEXT;
    proposal_evidence_id TEXT;
    proposal_version TEXT;
    linked_relationship claim_evidence_relationship;
    linked_evidence_status evidence_lifecycle_status;
BEGIN
    IF NEW.approver_actor_type <> 'HUMAN' THEN
        RAISE EXCEPTION 'authoritative approval decisions require HUMAN actor type';
    END IF;
    IF NEW.reviewer_role <> 'APPROVER' THEN
        RAISE EXCEPTION 'authoritative approval decisions require APPROVER reviewer role';
    END IF;

    SELECT actor_type, actor_identity
    INTO prov_actor_type, prov_actor_identity
    FROM provenance_events
    WHERE provenance_event_id = NEW.provenance_event_id;

    IF prov_actor_type IS NULL THEN
        RAISE EXCEPTION 'authoritative approval decisions require provenance_event';
    END IF;
    IF prov_actor_type <> 'HUMAN' OR prov_actor_identity <> NEW.approver_identity THEN
        RAISE EXCEPTION 'approval provenance must bind to the same HUMAN approver identity';
    END IF;

    IF NEW.approval_scope = 'SCORE_CHANGE' THEN
        SELECT proposed_by, claim_id, evidence_id, evaluation_version
        INTO proposer_identity, proposal_claim_id, proposal_evidence_id, proposal_version
        FROM score_change_proposals
        WHERE score_change_id = NEW.score_change_id;

        IF proposer_identity IS NULL THEN
            RAISE EXCEPTION 'score-change approval requires an existing immutable proposal';
        END IF;
        IF proposer_identity = NEW.approver_identity THEN
            RAISE EXCEPTION 'score-change proposer cannot approve their own proposal';
        END IF;
        IF NEW.claim_id IS DISTINCT FROM proposal_claim_id
           OR NEW.evidence_id IS DISTINCT FROM proposal_evidence_id
           OR NEW.entity_version IS DISTINCT FROM proposal_version THEN
            RAISE EXCEPTION 'score-change approval scope must exactly match proposal claim, evidence, and evaluation version';
        END IF;

        SELECT ce.relationship, e.evidence_status
        INTO linked_relationship, linked_evidence_status
        FROM claim_evidence ce
        JOIN evidence e ON e.evidence_id = ce.evidence_id
        WHERE ce.claim_id = proposal_claim_id
          AND ce.evidence_id = proposal_evidence_id
          AND ce.evaluation_version = proposal_version;

        IF linked_relationship IS NULL THEN
            RAISE EXCEPTION 'score-change approval requires exact claim_evidence linkage';
        END IF;
        IF linked_relationship NOT IN ('SUPPORT','PRESSURE') THEN
            RAISE EXCEPTION 'score-change approval requires SUPPORT or PRESSURE claim_evidence relationship';
        END IF;
        IF linked_evidence_status <> 'APPROVED' THEN
            RAISE EXCEPTION 'score-change approval requires APPROVED evidence';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

-- Emit a real immutable audit record for every approved dimension mutation.
CREATE OR REPLACE FUNCTION emit_claim_score_change_audit()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    dim TEXT;
    oldv SMALLINT;
    newv SMALLINT;
    chosen_score_change UUID;
    chosen_evidence TEXT;
    chosen_reason TEXT;
    chosen_actor TEXT;
BEGIN
    FOREACH dim IN ARRAY ARRAY['PS','ED','CI','IR','RD','RR'] LOOP
        EXECUTE format('SELECT ($1).%I, ($2).%I', lower(dim), lower(dim))
        INTO oldv, newv USING OLD, NEW;

        IF oldv IS DISTINCT FROM newv THEN
            SELECT scp.score_change_id, scp.evidence_id, scp.rationale, ae.approver_identity
            INTO chosen_score_change, chosen_evidence, chosen_reason, chosen_actor
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
            ORDER BY ae.created_at DESC
            LIMIT 1;

            IF chosen_score_change IS NULL THEN
                RAISE EXCEPTION 'approved score mutation lacks auditable approval provenance';
            END IF;

            INSERT INTO audit_log (
                entity_type, entity_id, action, old_value, new_value,
                reason, evidence_id, actor
            ) VALUES (
                'CLAIM_SCORE', NEW.claim_id || ':' || dim, 'APPROVED_SCORE_CHANGE',
                jsonb_build_object(dim, oldv), jsonb_build_object(dim, newv),
                chosen_reason, chosen_evidence, chosen_actor
            );
        END IF;
    END LOOP;
    RETURN NEW;
END;
$$;

CREATE TRIGGER claims_score_change_audit_emit
AFTER UPDATE OF ps, ed, ci, ir, rd, rr ON claims
FOR EACH ROW EXECUTE FUNCTION emit_claim_score_change_audit();

-- R-005 safety by design: theory-level aggregate truth/standing scores must not become stored columns.
CREATE OR REPLACE FUNCTION prevent_theory_score_columns()
RETURNS event_trigger LANGUAGE plpgsql AS $$
DECLARE
    forbidden_count INTEGER;
BEGIN
    SELECT count(*) INTO forbidden_count
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'theories'
      AND lower(column_name) IN ('rps','score','esi','sti','confidence');

    IF forbidden_count > 0 THEN
        RAISE EXCEPTION 'R-005: stored theory-level aggregate score columns are prohibited';
    END IF;
END;
$$;

CREATE EVENT TRIGGER theory_score_column_guard
ON ddl_command_end
WHEN TAG IN ('ALTER TABLE')
EXECUTE FUNCTION prevent_theory_score_columns();

COMMIT;
