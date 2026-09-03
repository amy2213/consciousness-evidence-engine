#!/usr/bin/env bash
set -euo pipefail
: "${DATABASE_URL:=postgresql://cee:cee_dev_only@localhost:5432/consciousness_engine}"
PSQL=(psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -X)
cleanup_files=(); cleanup(){ rm -f "${cleanup_files[@]}" 2>/dev/null || true; }; trap cleanup EXIT
run_zero_row_gate(){ local label="$1" file="$2" tmp; tmp="$(mktemp)"; cleanup_files+=("$tmp"); if ! "${PSQL[@]}" -At -f "$file" >"$tmp"; then cat "$tmp"; exit 1; fi; local violations; violations="$(sed '/^[[:space:]]*$/d' "$tmp")"; if [[ -n "$violations" ]]; then echo "$label violations detected:"; echo "$violations"; exit 1; fi; }
echo "[1/47] Resetting public schema"; "${PSQL[@]}" -c 'DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;'
echo "[2/47] Applying base schema"; "${PSQL[@]}" -f db/schema.sql
echo "[3/47] Applying migrations"; for migration in db/migrations/*.sql; do echo "  -> $migration"; "${PSQL[@]}" -f "$migration"; done
echo "[4/47] Loading controlled vocabularies"; "${PSQL[@]}" -f db/seed/controlled_vocabularies.sql
echo "[5/47] Loading v1.1.1 evaluation contexts"; "${PSQL[@]}" -f db/seed/v1_1_1_evaluation_contexts.sql
echo "[6/47] Reconciling baseline evaluation contexts"; run_zero_row_gate "Evaluation contexts" db/tests/evaluation_contexts.sql
echo "[7/47] Loading v1.1.1 claim taxonomy"; "${PSQL[@]}" -f db/seed/v1_1_1_claim_taxonomy.sql
echo "[8/47] Loading v1.1.1 authoritative sources"; "${PSQL[@]}" -f db/seed/v1_1_1_sources.sql
echo "[9/47] Reconciling frozen v1.1.1 source registry"; run_zero_row_gate "Source reconciliation" db/tests/v1_1_1_sources.sql
echo "[10/47] Replaying frozen source seed"; "${PSQL[@]}" -f db/seed/v1_1_1_sources.sql
echo "[11/47] Re-reconciling source registry"; run_zero_row_gate "Source replay reconciliation" db/tests/v1_1_1_sources.sql
echo "[12/47] Loading normalized bibliographic works"; "${PSQL[@]}" -f db/seed/v1_1_1_bibliographic_works.sql
echo "[13/47] Reconciling source-container/work model"; run_zero_row_gate "Source-model invariant" db/tests/source_model_invariants.sql
echo "[14/47] Loading frozen canonical claims"; "${PSQL[@]}" -f db/seed/v1_1_1_claims.sql
echo "[15/47] Reconciling frozen claim ledger"; run_zero_row_gate "Claim reconciliation" db/tests/v1_1_1_manifest.sql
echo "[16/47] Loading frozen scientific versions"; "${PSQL[@]}" -f db/seed/v1_1_1_scientific_versions.sql
echo "[17/47] Reconciling theory and claim versions"; run_zero_row_gate "Scientific versioning" db/tests/scientific_versioning.sql
echo "[18/47] Loading frozen score history"; "${PSQL[@]}" -f db/seed/v1_1_1_score_history.sql
echo "[19/47] Loading claim-source provenance"; "${PSQL[@]}" -f db/seed/v1_1_1_claim_source_links.sql
echo "[20/47] Reconciling claim-source provenance"; run_zero_row_gate "Claim-source reconciliation" db/tests/v1_1_1_claim_source_links.sql
echo "[21/47] Rechecking source model"; run_zero_row_gate "Source-model invariant" db/tests/source_model_invariants.sql
echo "[22/47] Loading anesthesia + sleep evidence"; "${PSQL[@]}" -f db/seed/v1_1_1_evidence_anesthesia_sleep.sql
echo "[23/47] Loading DoC/CMD evidence"; "${PSQL[@]}" -f db/seed/v1_1_1_evidence_doc_cmd.sql
echo "[24/47] Loading split-brain evidence"; "${PSQL[@]}" -f db/seed/v1_1_1_evidence_split_brain.sql
echo "[25/47] Migrating evidence context links"; "${PSQL[@]}" -f db/seed/v1_1_1_evaluation_contexts.sql
echo "[26/47] Reconciling all evaluation-context links"; run_zero_row_gate "Evaluation contexts" db/tests/evaluation_contexts.sql
echo "[27/47] Loading v1.1.1 measurement layer"; "${PSQL[@]}" -f db/seed/v1_1_1_measurements.sql
echo "[28/47] Reconciling measurement layer"; run_zero_row_gate "Measurement layer" db/tests/measurement_layer.sql
echo "[29/47] Attacking measurement consciousness firewall"; "${PSQL[@]}" -f db/tests/measurement_layer_adversarial.sql
echo "[30/47] Reconciling anesthesia + sleep evidence"; run_zero_row_gate "Anesthesia/sleep evidence reconciliation" db/tests/v1_1_1_evidence_anesthesia_sleep.sql
echo "[31/47] Reconciling DoC/CMD evidence"; run_zero_row_gate "DoC/CMD evidence reconciliation" db/tests/v1_1_1_evidence_doc_cmd.sql
echo "[32/47] Reconciling boundary evidence and frozen work-level locators"; run_zero_row_gate "Split-brain boundary reconciliation" db/tests/v1_1_1_evidence_split_brain.sql; "${PSQL[@]}" -f db/seed/v1_1_1_source_locators.sql
echo "[33/47] Loading isolated test and provenance fixtures"; "${PSQL[@]}" -f db/tests/fixtures.sql; "${PSQL[@]}" -f db/tests/provenance_fixtures.sql
echo "[34/47] Running positive acceptance fixtures"; "${PSQL[@]}" -f db/tests/positive.sql
echo "[35/47] Building and reconciling end-to-end provenance path"; run_zero_row_gate "End-to-end provenance" db/tests/end_to_end_provenance.sql
echo "[36/47] Attacking provenance immutability and source binding"; "${PSQL[@]}" -f db/tests/provenance_adversarial.sql
echo "[37/47] Reconciling executable epistemic rules"; run_zero_row_gate "Epistemic rules" db/tests/epistemic_rules.sql
echo "[38/47] Attacking executable epistemic rules"; "${PSQL[@]}" -f db/tests/epistemic_rules_adversarial.sql
echo "[39/47] Running rule conformance structural checks"; run_zero_row_gate "Rule conformance structure" db/tests/rule_conformance_invariants.sql
echo "[40/47] Running rule conformance positive, negative, edge, and mutation fixtures"; "${PSQL[@]}" -f db/tests/rule_conformance.sql
echo "[41/47] Reconciling score history"; run_zero_row_gate "Score history" db/tests/score_history.sql
echo "[42/47] Attacking score history immutability"; "${PSQL[@]}" -f db/tests/score_history_adversarial.sql
echo "[43/47] Reconciling canonical relational model"; run_zero_row_gate "Canonical relational model" db/tests/canonical_relational_model.sql
echo "[44/47] Reconciling approval, authorization, and release architecture"; run_zero_row_gate "Approval architecture" db/tests/approval_architecture.sql; run_zero_row_gate "Privilege hardening" db/tests/privilege_hardening.sql; run_zero_row_gate "Release architecture" db/tests/release_entities.sql
echo "[45/47] Running invariant and adversarial checks"; run_zero_row_gate "Invariant" db/tests/invariants.sql; "${PSQL[@]}" -f db/tests/adversarial.sql
echo "[46/47] Verifying provenance path view remains queryable"; "${PSQL[@]}" -At -c "SELECT count(*) FROM release_provenance_paths WHERE release_id='test-provenance-release';" | grep -qx '1'
echo "[47/47] Database migration gate complete"
echo "Database integrity, frozen baseline reconciliation, end-to-end provenance, rule conformance, mutation resistance, scientific versioning, score history, evaluation contexts, measurement semantics, executable epistemic firewalls, approval, authorization, and release architecture suite passed."
