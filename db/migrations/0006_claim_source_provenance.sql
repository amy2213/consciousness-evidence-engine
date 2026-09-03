-- Preserve two historically distinct relationships:
-- 1. sources cited in the canonical claim definition; and
-- 2. sources accumulated later through population/state deep dives.

BEGIN;

CREATE TYPE claim_source_link_kind AS ENUM ('BASELINE_CITATION','ACCUMULATED_EVIDENCE_LINK');

CREATE TABLE claim_source_links (
    claim_source_link_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ledger_version TEXT NOT NULL,
    claim_id TEXT NOT NULL REFERENCES claims(claim_id) ON DELETE RESTRICT,
    source_id TEXT NOT NULL REFERENCES sources(source_id) ON DELETE RESTRICT,
    link_kind claim_source_link_kind NOT NULL,
    population_id TEXT REFERENCES populations(population_id),
    interpretation TEXT,
    source_artifact TEXT NOT NULL DEFAULT 'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT baseline_citation_has_no_population CHECK (
        link_kind <> 'BASELINE_CITATION' OR population_id IS NULL
    )
);

-- A baseline citation is unique by ledger/claim/source and intentionally has no
-- population because it comes from the canonical Section 4 claim definition.
CREATE UNIQUE INDEX uq_claim_source_baseline
ON claim_source_links (ledger_version, claim_id, source_id)
WHERE link_kind = 'BASELINE_CITATION';

-- Later accumulated links may be population-specific or population-unresolved.
-- PostgreSQL 16 NULLS NOT DISTINCT prevents duplicate unresolved links.
CREATE UNIQUE INDEX uq_claim_source_accumulated
ON claim_source_links (ledger_version, claim_id, source_id, population_id) NULLS NOT DISTINCT
WHERE link_kind = 'ACCUMULATED_EVIDENCE_LINK';

COMMENT ON TABLE claim_source_links IS
'Historical claim-to-source provenance. Baseline Section 4 citations are never conflated with later Section 5.1 accumulated evidence links.';

COMMIT;
