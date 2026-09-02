#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:=postgresql://cee:cee_dev_only@localhost:5432/consciousness_engine}"

PSQL=(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X)

echo "[1/8] Resetting public schema"
"${PSQL[@]}" -c 'DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;'

echo "[2/8] Applying base schema"
"${PSQL[@]}" -f db/schema.sql

echo "[3/8] Applying migrations"
for migration in db/migrations/*.sql; do
  echo "  -> $migration"
  "${PSQL[@]}" -f "$migration"
done

echo "[4/8] Loading controlled vocabularies"
"${PSQL[@]}" -f db/seed/controlled_vocabularies.sql

echo "[5/8] Loading minimal fixtures"
"${PSQL[@]}" -f db/tests/fixtures.sql

echo "[6/8] Running positive acceptance fixtures"
"${PSQL[@]}" -f db/tests/positive.sql

echo "[7/8] Running invariant checks"
violations="$(${PSQL[@]} -At -f db/tests/invariants.sql | sed '/^[[:space:]]*$/d' || true)"
if [[ -n "$violations" ]]; then
  echo "Invariant violations detected:"
  echo "$violations"
  exit 1
fi

echo "[8/8] Running adversarial corruption tests"
"${PSQL[@]}" -f db/tests/adversarial.sql

echo "Database integrity suite passed."
