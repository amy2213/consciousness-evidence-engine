-- Normalize claim types before importing the v1.1.1 baseline.
-- The frozen ledger contains atomic claims with compound classifications such as S/C and C/P.
-- Storing a slash-delimited value would recreate the Word-era taxonomy drift in SQL.
--
-- Upgrade-safety rule: populate the referenced lookup before migrating any pre-existing claims.

BEGIN;

CREATE TABLE claim_types (
    claim_type claim_type_code PRIMARY KEY,
    label TEXT NOT NULL UNIQUE,
    question TEXT NOT NULL
);

-- Seed the complete canonical lookup inside the migration so populated databases can be upgraded
-- before the separate baseline taxonomy seed is applied.
INSERT INTO claim_types (claim_type, label, question) VALUES
('M','Mechanism','Does the proposed process occur and do the claimed operation?'),
('N','Necessity','Can the target conscious property persist without it?'),
('S','Sufficiency','Does selectively producing it create the target property?'),
('C','Content','Does it predict which experience occurs?'),
('B','Boundary','Does it identify which subsystem is the conscious subject?'),
('P','Phenomenal','Does it explain why the process is experienced at all?')
ON CONFLICT (claim_type) DO UPDATE SET
    label = EXCLUDED.label,
    question = EXCLUDED.question;

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
