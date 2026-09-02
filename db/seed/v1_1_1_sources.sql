-- Authoritative v1.1.1 Source-ID registry.
-- Registry wording is preserved in registry_text. Normalized bibliographic works are a separate layer.

BEGIN;

CREATE TEMP TABLE v111_source_import (
    source_id TEXT,
    source_text TEXT,
    venue_year TEXT,
    primary_use TEXT,
    closure_text TEXT,
    source_kind ledger_source_kind
);

\copy v111_source_import FROM 'data/baseline/v1.1.1/sources_registry.csv' WITH (FORMAT csv, HEADER true)

INSERT INTO sources (
    source_id, authors, title, venue, year, source_class, closure_status,
    notes, source_kind, primary_use, registry_text, source_artifact
)
SELECT
    source_id,
    NULL,
    source_text,
    venue_year,
    NULL,
    'V1.1.1_LEDGER_SOURCE',
    CASE WHEN closure_text ILIKE 'PARTIAL%' THEN 'PARTIAL'::source_closure_status ELSE 'CLOSED'::source_closure_status END,
    closure_text,
    source_kind,
    primary_use,
    concat_ws(' | ', source_text, venue_year, primary_use, closure_text),
    'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx'
FROM v111_source_import
ON CONFLICT (source_id) DO UPDATE SET
    title = EXCLUDED.title,
    venue = EXCLUDED.venue,
    source_class = EXCLUDED.source_class,
    closure_status = EXCLUDED.closure_status,
    notes = EXCLUDED.notes,
    source_kind = EXCLUDED.source_kind,
    primary_use = EXCLUDED.primary_use,
    registry_text = EXCLUDED.registry_text,
    source_artifact = EXCLUDED.source_artifact;

COMMIT;
