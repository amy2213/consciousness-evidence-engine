-- Immutable source-of-record snapshots preserve what a frozen ledger version actually scored.
-- Operational claims may evolve later through reviewed score proposals, but the imported baseline must not.

BEGIN;

CREATE TABLE claim_baseline_snapshots (
    ledger_version TEXT NOT NULL,
    claim_id TEXT NOT NULL REFERENCES claims(claim_id) ON DELETE RESTRICT,
    ps SMALLINT NOT NULL CHECK (ps BETWEEN 0 AND 4),
    ed SMALLINT NOT NULL CHECK (ed BETWEEN 0 AND 4),
    ci SMALLINT NOT NULL CHECK (ci BETWEEN 0 AND 4),
    ir SMALLINT NOT NULL CHECK (ir BETWEEN 0 AND 4),
    rd SMALLINT NOT NULL CHECK (rd BETWEEN 0 AND 4),
    rr SMALLINT NOT NULL CHECK (rr BETWEEN 0 AND 4),
    esi SMALLINT GENERATED ALWAYS AS (ed + ci + ir + rd) STORED,
    sti SMALLINT GENERATED ALWAYS AS (ps + rr) STORED,
    rps SMALLINT GENERATED ALWAYS AS (ed + ci + ir + rd + ps + rr) STORED,
    cmc SMALLINT NOT NULL CHECK (cmc BETWEEN 0 AND 4),
    operational_feasibility SMALLINT NOT NULL CHECK (operational_feasibility BETWEEN 0 AND 4),
    source_artifact TEXT NOT NULL,
    imported_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (ledger_version, claim_id)
);

CREATE OR REPLACE FUNCTION prevent_baseline_snapshot_mutation()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'claim_baseline_snapshots is immutable; create a new ledger_version instead';
END;
$$;

CREATE TRIGGER claim_baseline_snapshots_no_update
BEFORE UPDATE OR DELETE ON claim_baseline_snapshots
FOR EACH ROW EXECUTE FUNCTION prevent_baseline_snapshot_mutation();

COMMIT;
