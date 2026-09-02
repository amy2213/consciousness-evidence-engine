#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:=postgresql://cee:cee_dev_only@localhost:5432/consciousness_engine}"

PSQL=(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X)

echo "[1/7] Resetting public schema"
"${PSQL[@]}" -c 'DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;'

echo "[2/7] Applying base schema"
"${PSQL[@]}" -f db/schema.sql

echo "[3/7] Applying migrations"
for migration in db/migrations/*.sql; do
  echo "  -> $migration"
  "${PSQL[@]}" -f "$migration"
done

echo "[4/7] Loading controlled vocabularies"
"${PSQL[@]}" -f db/seed/controlled_vocabularies.sql

echo "[5/7] Loading minimal fixtures"
"${PSQL[@]}" -f db/tests/fixtures.sql

echo "[6/7] Running invariant checks"
violations="$(${PSQL[@]} -At -f db/tests/invariants.sql | sed '/^[[:space:]]*$/d' || true)"
if [[ -n "$violations" ]]; then
  echo "Invariant violations detected:"
  echo "$violations"
  exit 1
fi

echo "[7/7] Running adversarial corruption tests"
"${PSQL[@]}" -f db/tests/adversarial.sql

echo "Database integrity suite passed."
