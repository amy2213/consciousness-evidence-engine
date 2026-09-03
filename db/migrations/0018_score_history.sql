-- Phase 7: immutable score history tied to claim versions and approval provenance.
BEGIN;

CREATE TYPE score_snapshot_kind_code AS ENUM ('BASELINE_IMPORT','APPROVED_CHANGE');

CREATE TABLE claim_score_snapshots (
    score_snapshot_id UUID PRIMARY KEY,
    claim_id TEXT NOT NULL REFERENCES claims(claim_id) ON DELETE RESTRICT,
    claim_version_id TEXT NOT NULL REFERENCES claim_versions(claim_version_id) ON DELETE RESTRICT,
    specification_version_id TEXT NOT NULL REFERENCES specification_versions(specification_version_id) ON DELETE RESTRICT,
    revision INTEGER NOT NULL CHECK (revision > 0),
    snapshot_kind score_snapshot_kind_code NOT NULL,
    ps SMALLINT NOT NULL CHECK (ps BETWEEN 0 AND 4),
    ed SMALLINT NOT NULL CHECK (ed BETWEEN 0 AND 4),
    ci SMALLINT NOT NULL CHECK (ci BETWEEN 0 AND 4),
    ir SMALLINT NOT NULL CHECK (ir BETWEEN 0 AND 4),
    rd SMALLINT NOT NULL CHECK (rd BETWEEN 0 AND 4),
    rr SMALLINT NOT NULL CHECK (rr BETWEEN 0 AND 4),
    esi SMALLINT GENERATED ALWAYS AS (ed + ci + ir + rd) STORED,
    sti SMALLINT GENERATED ALWAYS AS (ps + rr) STORED,
    rps SMALLINT GENERATED ALWAYS AS (ed + ci + ir + rd + ps + rr) STORED,
    evidence_id TEXT REFERENCES evidence(evidence_id) ON DELETE RESTRICT,
    score_change_id UUID REFERENCES score_change_proposals(score_change_id) ON DELETE RESTRICT,
    approval_event_id UUID REFERENCES approval_events(approval_event_id) ON DELETE RESTRICT,
    evaluator_identity TEXT NOT NULL,
    evaluator_actor_type provenance_actor_type NOT NULL,
    rationale TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (claim_version_id, revision),
    CHECK (btrim(evaluator_identity) <> ''),
    CHECK (btrim(rationale) <> ''),
    CHECK (
      (snapshot_kind='BASELINE_IMPORT' AND evidence_id IS NULL AND score_change_id IS NULL AND approval_event_id IS NULL)
      OR
      (snapshot_kind='APPROVED_CHANGE' AND evidence_id IS NOT NULL AND score_change_id IS NOT NULL AND approval_event_id IS NOT NULL)
    )
);

CREATE OR REPLACE FUNCTION prevent_score_snapshot_mutation()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'claim_score_snapshots is append-only';
END;
$$;
CREATE TRIGGER claim_score_snapshots_no_update_delete
BEFORE UPDATE OR DELETE ON claim_score_snapshots
FOR EACH ROW EXECUTE FUNCTION prevent_score_snapshot_mutation();

CREATE OR REPLACE FUNCTION record_approved_claim_score_snapshot()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    dim TEXT;
    oldv SMALLINT;
    newv SMALLINT;
    chosen_score_change UUID;
    chosen_evidence TEXT;
    chosen_approval UUID;
    chosen_approver TEXT;
    chosen_reason TEXT;
    chosen_eval_version TEXT;
    chosen_claim_version TEXT;
    chosen_spec TEXT;
    next_revision INTEGER;
BEGIN
    -- One UPDATE may change more than one dimension. Existing authority gates require each delta separately.
    -- Create one snapshot after the row reaches its complete approved state, using the newest matching approval.
    IF ROW(OLD.ps,OLD.ed,OLD.ci,OLD.ir,OLD.rd,OLD.rr)
       IS NOT DISTINCT FROM ROW(NEW.ps,NEW.ed,NEW.ci,NEW.ir,NEW.rd,NEW.rr) THEN
        RETURN NEW;
    END IF;

    FOREACH dim IN ARRAY ARRAY['PS','ED','CI','IR','RD','RR'] LOOP
        EXECUTE format('SELECT ($1).%I, ($2).%I', lower(dim), lower(dim))
        INTO oldv,newv USING OLD,NEW;
        IF oldv IS DISTINCT FROM newv THEN
            SELECT scp.score_change_id,scp.evidence_id,ae.approval_event_id,ae.approver_identity,scp.rationale,scp.evaluation_version
            INTO chosen_score_change,chosen_evidence,chosen_approval,chosen_approver,chosen_reason,chosen_eval_version
            FROM score_change_proposals scp
            JOIN approval_events ae ON ae.score_change_id=scp.score_change_id
            WHERE scp.claim_id=NEW.claim_id
              AND scp.dimension::text=dim
              AND scp.old_value=oldv
              AND scp.proposed_value=newv
              AND ae.approval_scope='SCORE_CHANGE'
              AND ae.decision='APPROVE'
              AND ae.approver_actor_type='HUMAN'
              AND ae.entity_version=scp.evaluation_version
            ORDER BY ae.created_at DESC LIMIT 1;
            EXIT;
        END IF;
    END LOOP;

    IF chosen_score_change IS NULL THEN
        RAISE EXCEPTION 'approved score state cannot be historized without exact approved proposal';
    END IF;

    SELECT cv.claim_version_id,cv.specification_version_id
    INTO chosen_claim_version,chosen_spec
    FROM claim_versions cv
    WHERE cv.claim_id=NEW.claim_id
    ORDER BY (cv.status='FROZEN') DESC, cv.created_at DESC
    LIMIT 1;

    IF chosen_claim_version IS NULL THEN
        RAISE EXCEPTION 'approved score state requires a claim_version';
    END IF;

    SELECT COALESCE(MAX(revision),0)+1 INTO next_revision
    FROM claim_score_snapshots WHERE claim_version_id=chosen_claim_version;

    INSERT INTO claim_score_snapshots(
      score_snapshot_id,claim_id,claim_version_id,specification_version_id,revision,snapshot_kind,
      ps,ed,ci,ir,rd,rr,evidence_id,score_change_id,approval_event_id,
      evaluator_identity,evaluator_actor_type,rationale
    ) VALUES (
      gen_random_uuid(),NEW.claim_id,chosen_claim_version,chosen_spec,next_revision,'APPROVED_CHANGE',
      NEW.ps,NEW.ed,NEW.ci,NEW.ir,NEW.rd,NEW.rr,chosen_evidence,chosen_score_change,chosen_approval,
      chosen_approver,'HUMAN',chosen_reason
    );
    RETURN NEW;
END;
$$;

CREATE TRIGGER claims_score_history_emit
AFTER UPDATE OF ps,ed,ci,ir,rd,rr ON claims
FOR EACH ROW EXECUTE FUNCTION record_approved_claim_score_snapshot();

CREATE VIEW current_claim_scores AS
SELECT DISTINCT ON (claim_version_id)
    score_snapshot_id,claim_id,claim_version_id,specification_version_id,revision,
    ps,ed,ci,ir,rd,rr,esi,sti,rps,evidence_id,score_change_id,approval_event_id,
    evaluator_identity,evaluator_actor_type,rationale,created_at
FROM claim_score_snapshots
ORDER BY claim_version_id,revision DESC;

GRANT SELECT ON claim_score_snapshots,current_claim_scores TO cee_app_read,cee_ingest,cee_review,cee_approve,cee_release;
CREATE INDEX idx_score_snapshots_claim_version ON claim_score_snapshots(claim_version_id,revision DESC);
CREATE INDEX idx_score_snapshots_proposal ON claim_score_snapshots(score_change_id);
COMMIT;
