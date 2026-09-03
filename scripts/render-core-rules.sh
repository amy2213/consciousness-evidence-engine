#!/usr/bin/env bash
set -euo pipefail
: "${DATABASE_URL:=postgresql://cee:cee_dev_only@localhost:5432/consciousness_engine}"
PSQL=(psql "$DATABASE_URL" -X -At -v ON_ERROR_STOP=1)
cat <<'EOF'
# GENERATED FILE. DO NOT EDIT BY HAND.
# Canonical source: public.rules after all migrations.
version: 1.0
rules:
EOF
"${PSQL[@]}" -F $'\t' -c "SELECT rule_id,name,severity,enforcement_kind,enforcement_artifact,rationale FROM rules ORDER BY rule_id" |
while IFS=$'\t' read -r id name severity kind artifact statement; do
  printf '  - id: %s\n' "$id"
  printf '    name: %s\n' "$name"
  printf '    severity: %s\n' "$severity"
  printf '    enforcement_kind: %s\n' "$kind"
  printf '    enforcement_artifact: %s\n' "$artifact"
  printf '    statement: %s\n\n' "$statement"
done
