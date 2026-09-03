-- Phase 3 repair: evidence promotion must fail immediately without exact human approval provenance.
-- The earlier constraint trigger was DEFERRABLE and therefore too soft for hostile fail-closed testing.

BEGIN;

DROP TRIGGER IF EXISTS evidence_requires_approval_event ON evidence;

CREATE TRIGGER evidence_requires_approval_event
BEFORE INSERT OR UPDATE OF evidence_status ON evidence
FOR EACH ROW EXECUTE FUNCTION enforce_evidence_approval_event();

COMMIT;
