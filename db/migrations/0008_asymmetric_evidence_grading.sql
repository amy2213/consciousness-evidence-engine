-- Encode the v1.1.1 DoC/CMD asymmetric evidence rule.
-- Positive active-paradigm findings can carry CMC 3-4 under the ledger rules;
-- absence-directed inference from a negative active test is capped at CMC 1
-- unless exceptional independent sensitivity/state-quality criteria are established.

BEGIN;

ALTER TABLE evidence
    ADD COLUMN asymmetric_inference BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN negative_inference_cmc_cap SMALLINT CHECK (negative_inference_cmc_cap BETWEEN 0 AND 4),
    ADD COLUMN asymmetry_rationale TEXT;

ALTER TABLE evidence
    ADD CONSTRAINT asymmetric_evidence_requires_cap CHECK (
        asymmetric_inference IS FALSE OR negative_inference_cmc_cap IS NOT NULL
    ),
    ADD CONSTRAINT nonasymmetric_evidence_has_no_cap CHECK (
        asymmetric_inference IS TRUE OR negative_inference_cmc_cap IS NULL
    );

COMMENT ON COLUMN evidence.asymmetric_inference IS
'True when positive and negative results from the same paradigm have different permitted consciousness inferences under the ledger.';

COMMENT ON COLUMN evidence.negative_inference_cmc_cap IS
'Maximum CMC permitted for an absence-of-consciousness inference from a negative result in this evidence paradigm. This does not cap the CMC of positive findings.';

COMMENT ON COLUMN evidence.asymmetry_rationale IS
'Source-locked rationale for treating positive and negative results asymmetrically.';

COMMIT;
