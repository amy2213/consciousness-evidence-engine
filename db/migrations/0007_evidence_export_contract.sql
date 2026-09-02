-- Align the physical EVIDENCE object with the v1.1.1 canonical export contract.
-- Preserve the ledger's exact score-effect language separately from the normalized
-- score_effect_code so normalization never overwrites source wording.

BEGIN;

ALTER TABLE evidence
    ADD COLUMN ledger_score_effect_text TEXT,
    ADD COLUMN ledger_interpretation TEXT,
    ADD COLUMN ledger_version TEXT,
    ADD COLUMN source_artifact TEXT,
    ADD COLUMN source_locator TEXT;

ALTER TABLE evidence
    ADD COLUMN score_effect score_effect_code NOT NULL DEFAULT 'NONE';

COMMENT ON COLUMN evidence.ledger_score_effect_text IS
'Verbatim or minimally normalized score-effect wording from the controlling ledger view. Never inferred from the normalized score_effect code.';

COMMENT ON COLUMN evidence.ledger_interpretation IS
'Ledger interpretation for this atomic evidence record. Source-derived, not a replacement for finding.';

COMMENT ON COLUMN evidence.score_effect IS
'Normalized engine value. The source wording remains in ledger_score_effect_text.';

COMMENT ON COLUMN evidence.source_locator IS
'Human-readable source location in the controlling artifact, such as Section 15.1 or Section 19.1.';

CREATE INDEX idx_evidence_ledger_version ON evidence(ledger_version);

COMMIT;
