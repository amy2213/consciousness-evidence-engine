-- Normalized bibliographic-work layer for the frozen v1.1.1 source registry.
--
-- Source IDs are authoritative ledger containers. Most containers identify one registry-level work;
-- SRC-066 is explicitly a two-work cluster; SRC-067 is explicitly an unresolved umbrella cluster.
-- Do not invent child works for SRC-067 until exact study-level identities are source-locked.

BEGIN;

-- One registry-level work for every non-cluster source object except SRC-066 and SRC-067.
-- The frozen registry citation string is retained intact as title when the parent ledger did not
-- separately preserve author/title fields. Identifiers are extracted only when present in the
-- authoritative closure text.
INSERT INTO bibliographic_works (
    work_id,
    authors,
    title,
    venue,
    year,
    doi,
    pmid,
    bibliographic_status,
    notes
)
SELECT
    'WORK-' || right(s.source_id, 3),
    NULL,
    s.title,
    s.venue,
    CASE
        WHEN substring(s.venue from '(18[0-9]{2}|19[0-9]{2}|20[0-9]{2}|21[0-9]{2})') IS NULL THEN NULL
        ELSE substring(s.venue from '(18[0-9]{2}|19[0-9]{2}|20[0-9]{2}|21[0-9]{2})')::smallint
    END,
    substring(s.notes from '(?i)DOI[s]?\s*:?[ ]*([^; ,]+)'),
    substring(s.notes from '(?i)PMID\s*:?[ ]*([0-9]+)'),
    CASE
        WHEN s.closure_status = 'CLOSED' THEN 'CLOSED'::source_closure_status
        WHEN s.closure_status = 'PARTIAL' THEN 'PARTIAL'::source_closure_status
        ELSE 'OPEN'::source_closure_status
    END,
    'Registry-faithful normalized work derived from ' || s.source_id || '. Parent Source ID remains authoritative.'
FROM sources s
WHERE s.source_id BETWEEN 'SRC-001' AND 'SRC-078'
  AND s.source_id NOT IN ('SRC-066','SRC-067')
ON CONFLICT (work_id) DO NOTHING;

INSERT INTO source_works (source_id, work_id, ordinal, relationship)
SELECT
    s.source_id,
    'WORK-' || right(s.source_id, 3),
    1,
    'REGISTRY_WORK'
FROM sources s
WHERE s.source_id BETWEEN 'SRC-001' AND 'SRC-078'
  AND s.source_id NOT IN ('SRC-066','SRC-067')
ON CONFLICT (source_id, work_id) DO NOTHING;

-- SRC-066 is not one paper. The frozen ledger explicitly names two 2003 Sneddon/Braithwaite/Gentle
-- works and preserves both DOIs. These work-level metadata were verified against PubMed records
-- using the DOI identities already present in the frozen ledger. This does not change the scientific
-- interpretation or score state; it closes the bibliographic membership of the paired source cluster.
INSERT INTO bibliographic_works (
    work_id, authors, title, venue, year, doi, pmid, pmcid, bibliographic_status, notes
) VALUES
(
    'WORK-066',
    'Lynne U. Sneddon; Victoria A. Braithwaite; Michael J. Gentle',
    'Do fishes have nociceptors? Evidence for the evolution of a vertebrate sensory system',
    'Proceedings of the Royal Society B: Biological Sciences',
    2003,
    '10.1098/rspb.2003.2349',
    '12816648',
    'PMC1691351',
    'CLOSED',
    'First member of frozen SRC-066 paired source cluster.'
),
(
    'WORK-079',
    'Lynne U. Sneddon; Victoria A. Braithwaite; Michael J. Gentle',
    'Novel object test: examining nociception and fear in the rainbow trout',
    'The Journal of Pain',
    2003,
    '10.1067/S1526-5900(03)00717-X',
    '14622663',
    NULL,
    'CLOSED',
    'Second member of frozen SRC-066 paired source cluster.'
)
ON CONFLICT (work_id) DO NOTHING;

INSERT INTO source_works (source_id, work_id, ordinal, relationship) VALUES
('SRC-066','WORK-066',1,'PAIRED_MEMBER'),
('SRC-066','WORK-079',2,'PAIRED_MEMBER')
ON CONFLICT (source_id, work_id) DO NOTHING;

-- SRC-067 intentionally receives no child work rows. The parent ledger labels it PARTIAL and
-- explicitly requires exact study-level source IDs before any score promotion. Absence here is
-- preserved uncertainty, not missing migration work.

COMMIT;
