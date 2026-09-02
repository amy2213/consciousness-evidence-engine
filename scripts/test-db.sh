#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:=postgresql://cee:cee_dev_only@localhost:5432/consciousness_engine}"

PSQL=(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X)

echo "[1/12] Resetting public schema"
"${PSQL[@]}" -c 'DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;'

echo "[2/12] Applying base schema"
"${PSQL[@]}" -f db/schema.sql

echo "[3/12] Applying migrations"
for migration in db/migrations/*.sql; do
  echo "  -> $migration"
  "${PSQL[@]}" -f "$migration"
done

echo "[4/12] Loading controlled vocabularies"
"${PSQL[@]}" -f db/seed/controlled_vocabularies.sql

echo "[5/12] Loading v1.1.1 claim taxonomy"
"${PSQL[@]}" -f db/seed/v1_1_1_claim_taxonomy.sql

echo "[6/12] Loading v1.1.1 authoritative sources"
"${PSQL[@]}" -f db/seed/v1_1_1_sources.sql

echo "[7/12] Reconciling frozen v1.1.1 source registry before test fixtures"
source_tmp="$(mktemp)"
trap 'rm -f "$source_tmp" "${inv_tmp:-}"' EXIT
if ! "${PSQL[@]}" -At -f db/tests/v1_1_1_sources.sql >"$source_tmp"; then
  cat "$source_tmp"
  exit 1
fi
source_violations="$(sed '/^[[:space:]]*$/d' "$source_tmp")"
if [[ -n "$source_violations" ]]; then
  echo "Source reconciliation violations detected:"
  echo "$source_violations"
  exit 1
fi

echo "[8/12] Loading minimal test fixtures"
"${PSQL[@]}" -f db/tests/fixtures.sql

echo "[9/12] Running positive acceptance fixtures"
"${PSQL[@]}" -f db/tests/positive.sql

echo "[10/12] Running invariant checks"
inv_tmp="$(mktemp)"
if ! "${PSQL[@]}" -At -f db/tests/invariants.sql >"$inv_tmp"; then
  cat "$inv_tmp"
  exit 1
fi
violations="$(sed '/^[[:space:]]*$/d' "$inv_tmp")"
if [[ -n "$violations" ]]; then
  echo "Invariant violations detected:"
  echo "$violations"
  exit 1
fi

echo "[11/12] Running adversarial corruption tests"
"${PSQL[@]}" -f db/tests/adversarial.sql

echo "[12/12] Database migration gate complete"
echo "Database integrity and v1.1.1 reconciliation suite passed."
