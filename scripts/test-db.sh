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

echo "[1/22] Resetting public schema"
"${PSQL[@]}" -c 'DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;'

echo "[2/22] Applying base schema"
"${PSQL[@]}" -f db/schema.sql

echo "[3/22] Applying migrations"
for migration in db/migrations/*.sql; do
  echo "  -> $migration"
  "${PSQL[@]}" -f "$migration"
done

echo "[4/22] Loading controlled vocabularies"
"${PSQL[@]}" -f db/seed/controlled_vocabularies.sql

echo "[5/22] Loading v1.1.1 claim taxonomy"
"${PSQL[@]}" -f db/seed/v1_1_1_claim_taxonomy.sql

echo "[6/22] Loading v1.1.1 authoritative sources"
"${PSQL[@]}" -f db/seed/v1_1_1_sources.sql

echo "[7/22] Reconciling frozen v1.1.1 source registry"
run_zero_row_gate "Source reconciliation" db/tests/v1_1_1_sources.sql

echo "[8/22] Loading frozen v1.1.1 canonical claims"
"${PSQL[@]}" -f db/seed/v1_1_1_claims.sql

echo "[9/22] Reconciling frozen v1.1.1 claim ledger"
run_zero_row_gate "Claim reconciliation" db/tests/v1_1_1_manifest.sql

echo "[10/22] Loading v1.1.1 claim-source provenance"
"${PSQL[@]}" -f db/seed/v1_1_1_claim_source_links.sql

echo "[11/22] Reconciling v1.1.1 claim-source provenance"
run_zero_row_gate "Claim-source reconciliation" db/tests/v1_1_1_claim_source_links.sql

echo "[12/22] Loading anesthesia + sleep atomic evidence"
"${PSQL[@]}" -f db/seed/v1_1_1_evidence_anesthesia_sleep.sql

echo "[13/22] Reconciling anesthesia + sleep atomic evidence"
run_zero_row_gate "Anesthesia/sleep evidence reconciliation" db/tests/v1_1_1_evidence_anesthesia_sleep.sql

echo "[14/22] Loading DoC/CMD atomic evidence"
"${PSQL[@]}" -f db/seed/v1_1_1_evidence_doc_cmd.sql

echo "[15/22] Reconciling DoC/CMD evidence + asymmetry"
run_zero_row_gate "DoC/CMD evidence reconciliation" db/tests/v1_1_1_evidence_doc_cmd.sql

echo "[16/22] Loading split-brain/hemispherectomy boundary evidence"
"${PSQL[@]}" -f db/seed/v1_1_1_evidence_split_brain.sql

echo "[17/22] Reconciling boundary evidence + unity ontology"
run_zero_row_gate "Split-brain boundary reconciliation" db/tests/v1_1_1_evidence_split_brain.sql

echo "[18/22] Loading isolated test fixtures"
"${PSQL[@]}" -f db/tests/fixtures.sql

echo "[19/22] Running positive acceptance fixtures"
"${PSQL[@]}" -f db/tests/positive.sql

echo "[20/22] Running invariant checks"
run_zero_row_gate "Invariant" db/tests/invariants.sql

echo "[21/22] Running adversarial corruption tests"
"${PSQL[@]}" -f db/tests/adversarial.sql

echo "[22/22] Database migration gate complete"
echo "Database integrity plus v1.1.1 source/claim/provenance/anesthesia/sleep/DoC/split-brain evidence reconciliation suite passed."
