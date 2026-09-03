#!/usr/bin/env bash
set -euo pipefail
: "${DATABASE_URL:=postgresql://cee:cee_dev_only@localhost:5432/consciousness_engine}"
PSQL=(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X)
cleanup_files=(); cleanup(){ rm -f "${cleanup_files[@]}" 2>/dev/null || true; }; trap cleanup EXIT
run_zero_row_gate(){ local label="$1" file="$2" tmp; tmp="$(mktemp)"; cleanup_files+=("$tmp"); if ! "${PSQL[@]}" -At -f "$file" >"$tmp"; then cat "$tmp"; exit 1; fi; local violations; violations="$(sed '/^[[:space:]]*$/d' "$tmp")"; if [[ -n "$violations" ]]; then echo "$label violations detected:"; echo "$violations"; exit 1; fi; }
echo "[1/33] Resetting public schema"; "${PSQL[@]}" -c 'DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;'
echo "[2/33] Applying base schema"; "${PSQL[@]}" -f db/schema.sql
echo "[3/33] Applying migrations"; for migration in db/migrations/*.sql; do echo "  -> $migration"; "${PSQL[@]}" -f "$migration"; done
echo "[4/33] Loading controlled vocabularies"; "${PSQL[@]}" -f db/seed/controlled_vocabularies.sql
echo "[5/33] Loading v1.1.1 claim taxonomy"; "${PSQL[@]}" -f db/seed/v1_1_1_claim_taxonomy.sql
echo "[6/33] Loading v1.1.1 authoritative sources"; "${PSQL[@]}" -f db/seed/v1_1_1_sources.sql
echo "[7/33] Reconciling frozen v1.1.1 source registry"; run_zero_row_gate "Source reconciliation" db/tests/v1_1_1_sources.sql
echo "[8/33] Replaying frozen source seed"; "${PSQL[@]}" -f db/seed/v1_1_1_sources.sql
echo "[9/33] Re-reconciling source registry"; run_zero_row_gate "Source replay reconciliation" db/tests/v1_1_1_sources.sql
echo "[10/33] Loading normalized bibliographic works"; "${PSQL[@]}" -f db/seed/v1_1_1_bibliographic_works.sql
echo "[11/33] Reconciling source-container/work model"; run_zero_row_gate "Source-model invariant" db/tests/source_model_invariants.sql
echo "[12/33] Loading frozen canonical claims"; "${PSQL[@]}" -f db/seed/v1_1_1_claims.sql
echo "[13/33] Reconciling frozen claim ledger"; run_zero_row_gate "Claim reconciliation" db/tests/v1_1_1_manifest.sql
echo "[14/33] Loading frozen scientific versions"; "${PSQL[@]}" -f db/seed/v1_1_1_scientific_versions.sql
echo "[15/33] Reconciling theory and claim versions"; run_zero_row_gate "Scientific versioning" db/tests/scientific_versioning.sql
echo "[16/33] Loading frozen score history"; "${PSQL[@]}" -f db/seed/v1_1_1_score_history.sql
echo "[17/33] Loading claim-source provenance"; "${PSQL[@]}" -f db/seed/v1_1_1_claim_source_links.sql
echo "[18/33] Reconciling claim-source provenance"; run_zero_row_gate "Claim-source reconciliation" db/tests/v1_1_1_claim_source_links.sql
echo "[19/33] Rechecking source model"; run_zero_row_gate "Source-model invariant" db/tests/source_model_invariants.sql
echo "[20/33] Loading anesthesia + sleep evidence"; "${PSQL[@]}" -f db/seed/v1_1_1_evidence_anesthesia_sleep.sql
echo "[21/33] Reconciling anesthesia + sleep evidence"; run_zero_row_gate "Anesthesia/sleep evidence reconciliation" db/tests/v1_1_1_evidence_anesthesia_sleep.sql
echo "[22/33] Loading DoC/CMD evidence"; "${PSQL[@]}" -f db/seed/v1_1_1_evidence_doc_cmd.sql
echo "[23/33] Reconciling DoC/CMD evidence"; run_zero_row_gate "DoC/CMD evidence reconciliation" db/tests/v1_1_1_evidence_doc_cmd.sql
echo "[24/33] Loading split-brain evidence"; "${PSQL[@]}" -f db/seed/v1_1_1_evidence_split_brain.sql
echo "[25/33] Reconciling boundary evidence"; run_zero_row_gate "Split-brain boundary reconciliation" db/tests/v1_1_1_evidence_split_brain.sql
echo "[26/33] Loading isolated test fixtures"; "${PSQL[@]}" -f db/tests/fixtures.sql
echo "[27/33] Running positive acceptance fixtures"; "${PSQL[@]}" -f db/tests/positive.sql
echo "[28/33] Reconciling score history"; run_zero_row_gate "Score history" db/tests/score_history.sql
echo "[29/33] Reconciling approval architecture"; run_zero_row_gate "Approval architecture" db/tests/approval_architecture.sql
echo "[30/33] Reconciling authorization architecture"; run_zero_row_gate "Privilege hardening" db/tests/privilege_hardening.sql
echo "[31/33] Reconciling release architecture"; run_zero_row_gate "Release architecture" db/tests/release_entities.sql
echo "[32/33] Running invariant and adversarial checks"; run_zero_row_gate "Invariant" db/tests/invariants.sql; "${PSQL[@]}" -f db/tests/adversarial.sql
echo "[33/33] Database migration gate complete"
echo "Database integrity, frozen baseline reconciliation, scientific versioning, immutable score history, semantic firewalls, approval, authorization, and release architecture suite passed."
