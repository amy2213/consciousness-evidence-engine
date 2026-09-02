-- Preserve two historically distinct relationships:
-- 1. sources cited in the canonical claim definition; and
-- 2. sources accumulated later through population/state deep dives.

BEGIN;

CREATE TYPE claim_source_link_kind AS ENUM ('BASELINE_CITATION','ACCUMULATED_EVIDENCE_LINK');

CREATE TABLE claim_source_links (
    ledger_version TEXT NOT NULL,
    claim_id TEXT NOT NULL REFERENCES claims(claim_id) ON DELETE RESTRICT,
    source_id TEXT NOT NULL REFERENCES sources(source_id) ON DELETE RESTRICT,
    link_kind claim_source_link_kind NOT NULL,
    population_id TEXT REFERENCES populations(population_id),
    interpretation TEXT,
    source_artifact TEXT NOT NULL DEFAULT 'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (ledger_version, claim_id, source_id, link_kind, population_id)
);

COMMENT ON TABLE claim_source_links IS
'Historical claim-to-source provenance. Baseline citations are never conflated with later deep-dive evidence links.';

COMMIT;
