#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:=postgresql://cee:cee_dev_only@localhost:5432/consciousness_engine}"
PSQL=(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X)
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

echo "[upgrade-0003 1/5] Resetting public schema"
"${PSQL[@]}" -c 'DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;'

echo "[upgrade-0003 2/5] Applying pre-0003 schema state"
"${PSQL[@]}" -f db/schema.sql
"${PSQL[@]}" -f db/migrations/0002_hardening.sql

echo "[upgrade-0003 3/5] Seeding dependencies and pre-existing scalar claims"
"${PSQL[@]}" <<'SQL'
INSERT INTO theories(theory_id, name, status)
VALUES ('TEST-UPGRADE','Upgrade Fixture Theory','ACTIVE');

INSERT INTO target_relevance(target_relevance_id, label, description)
VALUES ('TEST-UPGRADE-TR','Upgrade fixture relevance','Upgrade-path fixture only.');

INSERT INTO claims(
    claim_id, theory_id, claim_type, target_relevance_id, claim_text,
    ps, ed, ci, ir, rd, rr
) VALUES
('TEST-UPGRADE-M','TEST-UPGRADE','M','TEST-UPGRADE-TR','Pre-0003 mechanism fixture.',1,1,1,1,1,1),
('TEST-UPGRADE-P','TEST-UPGRADE','P','TEST-UPGRADE-TR','Pre-0003 phenomenal fixture.',1,1,1,1,1,1);
SQL

echo "[upgrade-0003 4/5] Applying claim-type normalization to populated database"
"${PSQL[@]}" -f db/migrations/0003_claim_type_normalization.sql

echo "[upgrade-0003 5/5] Verifying preserved normalized memberships"
"${PSQL[@]}" -At -f db/tests/upgrade_0003_populated.sql >"$tmp"
violations="$(sed '/^[[:space:]]*$/d' "$tmp")"
if [[ -n "$violations" ]]; then
  echo "Populated 0003 upgrade violations detected:"
  echo "$violations"
  exit 1
fi

echo "Populated migration 0003 upgrade path passed."
