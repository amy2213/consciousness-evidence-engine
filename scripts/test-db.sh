#!/usr/bin/env bash
set -euo pipefail
: "${DATABASE_URL:=postgresql://cee:cee_dev_only@localhost:5432/consciousness_engine}"
PSQL=(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X)
cleanup_files=(); cleanup(){ rm -f "${cleanup_files[@]}" 2>/dev/null || true; }; trap cleanup EXIT
run_zero_row_gate(){ local label="$1" file="$2" tmp; tmp="$(mktemp)"; cleanup_files+=("$tmp"); if ! "${PSQL[@]}" -At -f "$file" >"$tmp"; then cat "$tmp"; exit 1; fi; local violations; violations="$(sed '/^[[:space:]]*$/d' "$tmp")"; if [[ -n "$violations" ]]; then echo "$label violations detected:"; echo "$violations"; exit 1; fi; }
echo "[1/37] Resetting public schema"; "${PSQL[@]}" -c 'DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;'
echo "[2/37] Applying base schema"; "${PSQL[@]}" -f db/schema.sql
echo "[3/37] Applying migrations"; for migration in db/migrations/*.sql; do echo "  -> $migration"; "${PSQL[@]}" -f "$migration"; done
echo "[4/37] Loading controlled vocabularies"; "${PSQL[@]}" -f db/seed/controlled_vocabularies.sql
echo "[5/37] Loading v1.1.1 evaluation contexts"; "${PSQL[@]}" -f db/seed/v1_1_1_evaluation_contexts.sql
echo "[6/37] Reconciling baseline evaluation contexts"; run_zero_row_gate "Evaluation contexts" db/tests/evaluation_contexts.sql
echo "[7/37] Loading v1.1.1 claim taxonomy"; "${PSQL[@]}" -f db/seed/v1_1_1_claim_taxonomy.sql
echo "[8/37] Loading v1.1.1 authoritative sources"; "${PSQL[@]}" -f db/seed/v1_1_1_sources.sql
echo "[9/37] Reconciling frozen v1.1.1 source registry"; run_zero_row_gate "Source reconciliation" db/tests/v1_1_1_sources.sql
echo "[10/37] Replaying frozen source seed"; "${PSQL[@]}" -f db/seed/v1_1_1_sources.sql
echo "[11/37] Re-reconciling source registry"; run_zero_row_gate "Source replay reconciliation" db/tests/v1_1_1_sources.sql
echo "[12/37] Loading normalized bibliographic works"; "${PSQL[@]}" -f db/seed/v1_1_1_bibliographic_works.sql
echo "[13/37] Reconciling source-container/work model"; run_zero_row_gate "Source-model invariant" db/tests/source_model_invariants.sql
echo "[14/37] Loading frozen canonical claims"; "${PSQL[@]}" -f db/seed/v1_1_1_claims.sql
echo "[15/37] Reconciling frozen claim ledger"; run_zero_row_gate "Claim reconciliation" db/tests/v1_1_1_manifest.sql
echo "[16/37] Loading frozen scientific versions"; "${PSQL[@]}" -f db/seed/v1_1_1_scientific_versions.sql
echo "[17/37] Reconciling theory and claim versions"; run_zero_row_gate "Scientific versioning" db/tests/scientific_versioning.sql
echo "[18/37] Loading frozen score history"; "${PSQL[@]}" -f db/seed/v1_1_1_score_history.sql
echo "[19/37] Loading claim-source provenance"; "${PSQL[@]}" -f db/seed/v1_1_1_claim_source_links.sql
echo "[20/37] Reconciling claim-source provenance"; run_zero_row_gate "Claim-source reconciliation" db/tests/v1_1_1_claim_source_links.sql
echo "[21/37] Rechecking source model"; run_zero_row_gate "Source-model invariant" db/tests/source_model_invariants.sql
echo "[22/37] Loading anesthesia + sleep evidence"; "${PSQL[@]}" -f db/seed/v1_1_1_evidence_anesthesia_sleep.sql
echo "[23/37] Loading DoC/CMD evidence"; "${PSQL[@]}" -f db/seed/v1_1_1_evidence_doc_cmd.sql
echo "[24/37] Loading split-brain evidence"; "${PSQL[@]}" -f db/seed/v1_1_1_evidence_split_brain.sql
echo "[25/37] Migrating evidence context links"; "${PSQL[@]}" -f db/seed/v1_1_1_evaluation_contexts.sql
echo "[26/37] Reconciling all evaluation-context links"; run_zero_row_gate "Evaluation contexts" db/tests/evaluation_contexts.sql
echo "[27/37] Reconciling anesthesia + sleep evidence"; run_zero_row_gate "Anesthesia/sleep evidence reconciliation" db/tests/v1_1_1_evidence_anesthesia_sleep.sql
echo "[28/37] Reconciling DoC/CMD evidence"; run_zero_row_gate "DoC/CMD evidence reconciliation" db/tests/v1_1_1_evidence_doc_cmd.sql
echo "[29/37] Reconciling boundary evidence"; run_zero_row_gate "Split-brain boundary reconciliation" db/tests/v1_1_1_evidence_split_brain.sql
echo "[30/37] Loading isolated test fixtures"; "${PSQL[@]}" -f db/tests/fixtures.sql
echo "[31/37] Running positive acceptance fixtures"; "${PSQL[@]}" -f db/tests/positive.sql
echo "[32/37] Reconciling score history"; run_zero_row_gate "Score history" db/tests/score_history.sql
echo "[33/37] Attacking score history immutability"; "${PSQL[@]}" -f db/tests/score_history_adversarial.sql
echo "[34/37] Reconciling canonical relational model"; run_zero_row_gate "Canonical relational model" db/tests/canonical_relational_model.sql
echo "[35/37] Reconciling approval, authorization, and release architecture"; run_zero_row_gate "Approval architecture" db/tests/approval_architecture.sql; run_zero_row_gate "Privilege hardening" db/tests/privilege_hardening.sql; run_zero_row_gate "Release architecture" db/tests/release_entities.sql
echo "[36/37] Running invariant and adversarial checks"; run_zero_row_gate "Invariant" db/tests/invariants.sql; "${PSQL[@]}" -f db/tests/adversarial.sql
echo "[37/37] Database migration gate complete"
echo "Database integrity, frozen baseline reconciliation, scientific versioning, score history, generalized evaluation contexts, relational structure, semantic firewalls, approval, authorization, and release architecture suite passed."
