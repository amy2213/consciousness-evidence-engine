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
  if ! "${PSQL[@]}" -At -f "$file" >"$tmp"; then
    cat "$tmp"; exit 1
  fi
  local violations
  violations="$(sed '/^[[:space:]]*$/d' "$tmp")"
  if [[ -n "$violations" ]]; then
    echo "$label violations detected:"
    echo "$violations"
    exit 1
  fi
}

echo "[1/20] Resetting public schema"
"${PSQL[@]}" -c 'DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;'

echo "[2/20] Applying base schema"
"${PSQL[@]}" -f db/schema.sql

echo "[3/20] Applying migrations"
for migration in db/migrations/*.sql; do
  echo "  -> $migration"
  "${PSQL[@]}" -f "$migration"
done

echo "[4/20] Loading controlled vocabularies"
"${PSQL[@]}" -f db/seed/controlled_vocabularies.sql

echo "[5/20] Loading v1.1.1 claim taxonomy"
"${PSQL[@]}" -f db/seed/v1_1_1_claim_taxonomy.sql

echo "[6/20] Loading v1.1.1 authoritative sources"
"${PSQL[@]}" -f db/seed/v1_1_1_sources.sql

echo "[7/20] Reconciling frozen v1.1.1 source registry"
run_zero_row_gate "Source reconciliation" db/tests/v1_1_1_sources.sql

echo "[8/20] Loading frozen v1.1.1 canonical claims"
"${PSQL[@]}" -f db/seed/v1_1_1_claims.sql

echo "[9/20] Reconciling frozen v1.1.1 claim ledger"
run_zero_row_gate "Claim reconciliation" db/tests/v1_1_1_manifest.sql

echo "[10/20] Loading v1.1.1 claim-source provenance"
"${PSQL[@]}" -f db/seed/v1_1_1_claim_source_links.sql

echo "[11/20] Reconciling v1.1.1 claim-source provenance"
run_zero_row_gate "Claim-source reconciliation" db/tests/v1_1_1_claim_source_links.sql

echo "[12/20] Loading anesthesia + sleep atomic evidence"
"${PSQL[@]}" -f db/seed/v1_1_1_evidence_anesthesia_sleep.sql

echo "[13/20] Reconciling anesthesia + sleep atomic evidence"
run_zero_row_gate "Anesthesia/sleep evidence reconciliation" db/tests/v1_1_1_evidence_anesthesia_sleep.sql

echo "[14/20] Loading DoC/CMD atomic evidence"
"${PSQL[@]}" -f db/seed/v1_1_1_evidence_doc_cmd.sql

echo "[15/20] Reconciling DoC/CMD evidence + asymmetry"
run_zero_row_gate "DoC/CMD evidence reconciliation" db/tests/v1_1_1_evidence_doc_cmd.sql

echo "[16/20] Loading isolated test fixtures"
"${PSQL[@]}" -f db/tests/fixtures.sql

echo "[17/20] Running positive acceptance fixtures"
"${PSQL[@]}" -f db/tests/positive.sql

echo "[18/20] Running invariant checks"
run_zero_row_gate "Invariant" db/tests/invariants.sql

echo "[19/20] Running adversarial corruption tests"
"${PSQL[@]}" -f db/tests/adversarial.sql

echo "[20/20] Database migration gate complete"
echo "Database integrity plus v1.1.1 source/claim/provenance/anesthesia/sleep/DoC evidence reconciliation suite passed."
