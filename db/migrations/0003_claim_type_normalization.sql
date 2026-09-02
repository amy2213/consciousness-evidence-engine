-- Normalize claim types before importing the v1.1.1 baseline.
-- The frozen ledger contains atomic claims with compound classifications such as S/C and C/P.
-- Storing a slash-delimited value would recreate the Word-era taxonomy drift in SQL.

BEGIN;

CREATE TABLE claim_types (
    claim_type claim_type_code PRIMARY KEY,
    label TEXT NOT NULL UNIQUE,
    question TEXT NOT NULL
);

CREATE TABLE claim_claim_types (
    claim_id TEXT NOT NULL REFERENCES claims(claim_id) ON DELETE CASCADE,
    claim_type claim_type_code NOT NULL REFERENCES claim_types(claim_type),
    ordinal SMALLINT NOT NULL DEFAULT 1 CHECK (ordinal > 0),
    PRIMARY KEY (claim_id, claim_type),
    UNIQUE (claim_id, ordinal)
);

-- Preserve the original scalar value for any rows that may already exist.
INSERT INTO claim_claim_types (claim_id, claim_type, ordinal)
SELECT claim_id, claim_type, 1
FROM claims;

ALTER TABLE claims DROP COLUMN claim_type;

COMMENT ON TABLE claim_claim_types IS
'Normalized claim-type membership. Display labels such as S/C or C/P are rendered from ordered rows and are never stored as taxonomy strings.';

COMMIT;
