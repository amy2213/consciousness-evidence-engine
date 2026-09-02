#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:=postgresql://cee:cee_dev_only@localhost:5432/consciousness_engine}"

PSQL=(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X)

echo "[1/11] Resetting public schema"
"${PSQL[@]}" -c 'DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;'

echo "[2/11] Applying base schema"
"${PSQL[@]}" -f db/schema.sql

echo "[3/11] Applying migrations"
for migration in db/migrations/*.sql; do
  echo "  -> $migration"
  "${PSQL[@]}" -f "$migration"
done

echo "[4/11] Loading controlled vocabularies"
"${PSQL[@]}" -f db/seed/controlled_vocabularies.sql

echo "[5/11] Loading minimal fixtures"
"${PSQL[@]}" -f db/tests/fixtures.sql

echo "[6/11] Loading v1.1.1 claim taxonomy"
"${PSQL[@]}" -f db/seed/v1_1_1_claim_taxonomy.sql

echo "[7/11] Loading v1.1.1 authoritative sources"
"${PSQL[@]}" -f db/seed/v1_1_1_sources.sql

echo "[8/11] Running positive acceptance fixtures"
"${PSQL[@]}" -f db/tests/positive.sql

echo "[9/11] Running invariant and source reconciliation checks"
violations="$({ "${PSQL[@]}" -At -f db/tests/invariants.sql; "${PSQL[@]}" -At -f db/tests/v1_1_1_sources.sql; } | sed '/^[[:space:]]*$/d' || true)"
if [[ -n "$violations" ]]; then
  echo "Invariant violations detected:"
  echo "$violations"
  exit 1
fi

echo "[10/11] Running adversarial corruption tests"
"${PSQL[@]}" -f db/tests/adversarial.sql

echo "[11/11] Source migration gate complete"
echo "Database integrity and v1.1.1 source reconciliation suite passed."
