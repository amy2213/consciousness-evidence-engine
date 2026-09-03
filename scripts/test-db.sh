#!/usr/bin/env bash
set -euo pipefail
: "${DATABASE_URL:=postgresql://cee:cee_dev_only@localhost:5432/consciousness_engine}"
PSQL=(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X)
cleanup_files=(); cleanup(){ rm -f "${cleanup_files[@]}" 2>/dev/null || true; }; trap cleanup EXIT
run_zero_row_gate(){ local label="$1" file="$2" tmp; tmp="$(mktemp)"; cleanup_files+=("$tmp"); if ! "${PSQL[@]}" -At -f "$file" >"$tmp"; then cat "$tmp"; exit 1; fi; local violations; violations="$(sed '/^[[:space:]]*$/d' "$tmp")"; if [[ -n "$violations" ]]; then echo "$label violations detected:"; echo "$violations"; exit 1; fi; }
echo "[1/35] Resetting public schema"; "${PSQL[@]}" -c 'DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;'
echo "[2/35] Applying base schema"; "${PSQL[@]}" -f db/schema.sql
echo "[3/35] Applying migrations"; for migration in db/migrations/*.sql; do echo "  -> $migration"; "${PSQL[@]}" -f "$migration"; done
echo "[4/35] Loading controlled vocabularies"; "${PSQL[@]}" -f db/seed/controlled_vocabularies.sql
echo "[5/35] Loading v1.1.1 claim taxonomy"; "${PSQL[@]}" -f db/seed/v1_1_1_claim_taxonomy.sql
echo "[6/35] Loading v1.1.1 authoritative sources"; "${PSQL[@]}" -f db/seed/v1_1_1_sources.sql
echo "[7/35] Reconciling frozen v1.1.1 source registry"; run_zero_row_gate "Source reconciliation" db/tests/v1_1_1_sources.sql
echo "[8/35] Replaying frozen source seed"; "${PSQL[@]}" -f db/seed/v1_1_1_sources.sql
echo "[9/35] Re-reconciling source registry"; run_zero_row_gate "Source replay reconciliation" db/tests/v1_1_1_sources.sql
echo "[10/35] Loading normalized bibliographic works"; "${PSQL[@]}" -f db/seed/v1_1_1_bibliographic_works.sql
echo "[11/35] Reconciling source-container/work model"; run_zero_row_gate "Source-model invariant" db/tests/source_model_invariants.sql
echo "[12/35] Loading frozen canonical claims"; "${PSQL[@]}" -f db/seed/v1_1_1_claims.sql
echo "[13/35] Reconciling frozen claim ledger"; run_zero_row_gate "Claim reconciliation" db/tests/v1_1_1_manifest.sql
echo "[14/35] Loading frozen scientific versions"; "${PSQL[@]}" -f db/seed/v1_1_1_scientific_versions.sql
echo "[15/35] Reconciling theory and claim versions"; run_zero_row_gate "Scientific versioning" db/tests/scientific_versioning.sql
echo "[16/35] Loading frozen score history"; "${PSQL[@]}" -f db/seed/v1_1_1_score_history.sql
echo "[17/35] Loading claim-source provenance"; "${PSQL[@]}" -f db/seed/v1_1_1_claim_source_links.sql
echo "[18/35] Reconciling claim-source provenance"; run_zero_row_gate "Claim-source reconciliation" db/tests/v1_1_1_claim_source_links.sql
echo "[19/35] Rechecking source model"; run_zero_row_gate "Source-model invariant" db/tests/source_model_invariants.sql
echo "[20/35] Loading anesthesia + sleep evidence"; "${PSQL[@]}" -f db/seed/v1_1_1_evidence_anesthesia_sleep.sql
echo "[21/35] Reconciling anesthesia + sleep evidence"; run_zero_row_gate "Anesthesia/sleep evidence reconciliation" db/tests/v1_1_1_evidence_anesthesia_sleep.sql
echo "[22/35] Loading DoC/CMD evidence"; "${PSQL[@]}" -f db/seed/v1_1_1_evidence_doc_cmd.sql
echo "[23/35] Reconciling DoC/CMD evidence"; run_zero_row_gate "DoC/CMD evidence reconciliation" db/tests/v1_1_1_evidence_doc_cmd.sql
echo "[24/35] Loading split-brain evidence"; "${PSQL[@]}" -f db/seed/v1_1_1_evidence_split_brain.sql
echo "[25/35] Reconciling boundary evidence"; run_zero_row_gate "Split-brain boundary reconciliation" db/tests/v1_1_1_evidence_split_brain.sql
echo "[26/35] Loading isolated test fixtures"; "${PSQL[@]}" -f db/tests/fixtures.sql
echo "[27/35] Running positive acceptance fixtures"; "${PSQL[@]}" -f db/tests/positive.sql
echo "[28/35] Reconciling score history"; run_zero_row_gate "Score history" db/tests/score_history.sql
echo "[29/35] Attacking score history immutability"; "${PSQL[@]}" -f db/tests/score_history_adversarial.sql
echo "[30/35] Reconciling canonical relational model"; run_zero_row_gate "Canonical relational model" db/tests/canonical_relational_model.sql
echo "[31/35] Reconciling approval architecture"; run_zero_row_gate "Approval architecture" db/tests/approval_architecture.sql
echo "[32/35] Reconciling authorization architecture"; run_zero_row_gate "Privilege hardening" db/tests/privilege_hardening.sql
echo "[33/35] Reconciling release architecture"; run_zero_row_gate "Release architecture" db/tests/release_entities.sql
echo "[34/35] Running invariant and adversarial checks"; run_zero_row_gate "Invariant" db/tests/invariants.sql; "${PSQL[@]}" -f db/tests/adversarial.sql
echo "[35/35] Database migration gate complete"
echo "Database integrity, frozen baseline reconciliation, scientific versioning, immutable score history, canonical relational structure, semantic firewalls, approval, authorization, and release architecture suite passed."
