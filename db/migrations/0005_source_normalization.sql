-- v1.1.1 source normalization
-- A ledger Source ID may represent one publication, a paired source cluster, an umbrella literature cluster,
-- or a deliberately partial bibliographic record. Preserve that distinction explicitly.

BEGIN;

CREATE TYPE ledger_source_kind AS ENUM ('SINGLE_WORK','PAIRED_CLUSTER','UMBRELLA_CLUSTER','CONSENSUS','REVIEW_REPORT','PARTIAL_RECORD');

ALTER TABLE sources
    ADD COLUMN source_kind ledger_source_kind NOT NULL DEFAULT 'SINGLE_WORK',
    ADD COLUMN primary_use TEXT,
    ADD COLUMN registry_text TEXT,
    ADD COLUMN source_artifact TEXT NOT NULL DEFAULT 'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx';

CREATE TABLE bibliographic_works (
    work_id TEXT PRIMARY KEY CHECK (work_id ~ '^WORK-[0-9]{3,4}$'),
    authors TEXT,
    title TEXT NOT NULL,
    venue TEXT,
    year SMALLINT CHECK (year BETWEEN 1800 AND 2200),
    doi TEXT,
    pmid TEXT,
    pmcid TEXT,
    bibliographic_status source_closure_status NOT NULL DEFAULT 'OPEN',
    notes TEXT
);

CREATE TABLE source_works (
    source_id TEXT NOT NULL REFERENCES sources(source_id) ON DELETE CASCADE,
    work_id TEXT NOT NULL REFERENCES bibliographic_works(work_id) ON DELETE RESTRICT,
    ordinal SMALLINT NOT NULL CHECK (ordinal > 0),
    relationship TEXT NOT NULL DEFAULT 'MEMBER',
    PRIMARY KEY (source_id, work_id),
    UNIQUE (source_id, ordinal)
);

COMMENT ON TABLE sources IS
'Authoritative ledger Source IDs. One row always corresponds to exactly one SRC-### object in the frozen ledger, not necessarily one publication.';
COMMENT ON TABLE bibliographic_works IS
'Normalized publication/report/statement records that may be members of one or more ledger Source IDs.';
COMMENT ON TABLE source_works IS
'Membership bridge preserving source clusters without inventing a fictitious single bibliographic work.';

COMMIT;
