-- Authoritative v1.1.1 Source-ID registry.
-- Registry wording is preserved in registry_text. Normalized bibliographic works are a separate layer.
-- Frozen baseline rows are insert-once: reruns may confirm identity but may never rewrite history.

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
ON CONFLICT (source_id) DO NOTHING;

-- Idempotency is permitted; drift is not. If an existing frozen row differs from the import,
-- abort instead of silently mutating the canonical baseline.
DO $$
DECLARE
    drift_count integer;
BEGIN
    SELECT count(*) INTO drift_count
    FROM v111_source_import i
    JOIN sources s USING (source_id)
    WHERE s.authors IS NOT NULL
       OR s.title IS DISTINCT FROM i.source_text
       OR s.venue IS DISTINCT FROM i.venue_year
       OR s.year IS NOT NULL
       OR s.source_class IS DISTINCT FROM 'V1.1.1_LEDGER_SOURCE'
       OR s.closure_status IS DISTINCT FROM (CASE WHEN i.closure_text ILIKE 'PARTIAL%' THEN 'PARTIAL'::source_closure_status ELSE 'CLOSED'::source_closure_status END)
       OR s.notes IS DISTINCT FROM i.closure_text
       OR s.source_kind IS DISTINCT FROM i.source_kind
       OR s.primary_use IS DISTINCT FROM i.primary_use
       OR s.registry_text IS DISTINCT FROM concat_ws(' | ', i.source_text, i.venue_year, i.primary_use, i.closure_text)
       OR s.source_artifact IS DISTINCT FROM 'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx';

    IF drift_count <> 0 THEN
        RAISE EXCEPTION 'Frozen v1.1.1 source registry drift detected in % row(s); baseline mutation refused', drift_count;
    END IF;
END $$;

COMMIT;
