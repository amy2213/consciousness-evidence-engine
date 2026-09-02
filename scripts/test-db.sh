#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:=postgresql://cee:cee_dev_only@localhost:5432/consciousness_engine}"
PSQL=(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X)
cleanup_files=()
cleanup() { rm -f "${cleanup_files[@]}" 2>/dev/null || true; }
trap cleanup EXIT

run_zero_row_gate() {
  local label="$1" file="$2" tmp
  tmp="$(mktemp)"; cleanup_files+=("$tmp")
  if ! "${PSQL[@]}" -At -f "$file" >"$tmp"; then cat "$tmp"; exit 1; fi
  local violations
  violations="$(sed '/^[[:space:]]*$/d' "$tmp")"
  if [[ -n "$violations" ]]; then echo "$label violations detected:"; echo "$violations"; exit 1; fi
}

echo "[1/28] Resetting public schema"; "${PSQL[@]}" -c 'DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;'
echo "[2/28] Applying base schema"; "${PSQL[@]}" -f db/schema.sql
echo "[3/28] Applying migrations"; for migration in db/migrations/*.sql; do echo "  -> $migration"; "${PSQL[@]}" -f "$migration"; done
echo "[4/28] Loading controlled vocabularies"; "${PSQL[@]}" -f db/seed/controlled_vocabularies.sql
echo "[5/28] Loading v1.1.1 claim taxonomy"; "${PSQL[@]}" -f db/seed/v1_1_1_claim_taxonomy.sql
echo "[6/28] Loading v1.1.1 authoritative sources"; "${PSQL[@]}" -f db/seed/v1_1_1_sources.sql
echo "[7/28] Reconciling frozen v1.1.1 source registry"; run_zero_row_gate "Source reconciliation" db/tests/v1_1_1_sources.sql
echo "[8/28] Replaying frozen source seed to prove idempotency"; "${PSQL[@]}" -f db/seed/v1_1_1_sources.sql
echo "[9/28] Re-reconciling source registry after replay"; run_zero_row_gate "Source replay reconciliation" db/tests/v1_1_1_sources.sql
echo "[10/28] Loading normalized v1.1.1 bibliographic works"; "${PSQL[@]}" -f db/seed/v1_1_1_bibliographic_works.sql
echo "[11/28] Reconciling source-container/work model"; run_zero_row_gate "Source-model invariant" db/tests/source_model_invariants.sql
echo "[12/28] Loading frozen v1.1.1 canonical claims"; "${PSQL[@]}" -f db/seed/v1_1_1_claims.sql
echo "[13/28] Reconciling frozen v1.1.1 claim ledger"; run_zero_row_gate "Claim reconciliation" db/tests/v1_1_1_manifest.sql
echo "[14/28] Loading v1.1.1 claim-source provenance"; "${PSQL[@]}" -f db/seed/v1_1_1_claim_source_links.sql
echo "[15/28] Reconciling v1.1.1 claim-source provenance"; run_zero_row_gate "Claim-source reconciliation" db/tests/v1_1_1_claim_source_links.sql
echo "[16/28] Rechecking source model with claim-source links loaded"; run_zero_row_gate "Source-model invariant" db/tests/source_model_invariants.sql
echo "[17/28] Loading anesthesia + sleep atomic evidence"; "${PSQL[@]}" -f db/seed/v1_1_1_evidence_anesthesia_sleep.sql
echo "[18/28] Reconciling anesthesia + sleep atomic evidence"; run_zero_row_gate "Anesthesia/sleep evidence reconciliation" db/tests/v1_1_1_evidence_anesthesia_sleep.sql
echo "[19/28] Loading DoC/CMD atomic evidence"; "${PSQL[@]}" -f db/seed/v1_1_1_evidence_doc_cmd.sql
echo "[20/28] Reconciling DoC/CMD evidence + asymmetry"; run_zero_row_gate "DoC/CMD evidence reconciliation" db/tests/v1_1_1_evidence_doc_cmd.sql
echo "[21/28] Loading split-brain/hemispherectomy boundary evidence"; "${PSQL[@]}" -f db/seed/v1_1_1_evidence_split_brain.sql
echo "[22/28] Reconciling boundary evidence + unity ontology"; run_zero_row_gate "Split-brain boundary reconciliation" db/tests/v1_1_1_evidence_split_brain.sql
echo "[23/28] Loading isolated test fixtures"; "${PSQL[@]}" -f db/tests/fixtures.sql
echo "[24/28] Running positive acceptance fixtures"; "${PSQL[@]}" -f db/tests/positive.sql
echo "[25/28] Reconciling human-only approval architecture"; run_zero_row_gate "Approval architecture" db/tests/approval_architecture.sql
echo "[26/28] Reconciling database authorization architecture"; run_zero_row_gate "Privilege hardening" db/tests/privilege_hardening.sql
echo "[27/28] Running invariant and adversarial checks"; run_zero_row_gate "Invariant" db/tests/invariants.sql; "${PSQL[@]}" -f db/tests/adversarial.sql
echo "[28/28] Database migration gate complete"
echo "Database integrity, frozen baseline reconciliation, semantic firewalls, human-only approval, and least-privilege authorization suite passed."
