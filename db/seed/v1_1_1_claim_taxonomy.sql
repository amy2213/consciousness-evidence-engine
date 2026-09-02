-- Frozen taxonomy extracted from Consciousness Evidence Map: Claim Ledger v1.1.1.
-- This seed preserves source wording. It does not collapse the claim-level relevance labels
-- into the four broad explanatory categories defined in section 2.2.

BEGIN;

INSERT INTO claim_types (claim_type, label, question) VALUES
('M','Mechanism','Does the proposed process occur and do the claimed operation?'),
('N','Necessity','Can the target conscious property persist without it?'),
('S','Sufficiency','Does selectively producing it create the target property?'),
('C','Content','Does it predict which experience occurs?'),
('B','Boundary','Does it identify which subsystem is the conscious subject?'),
('P','Phenomenal','Does it explain why the process is experienced at all?')
ON CONFLICT (claim_type) DO UPDATE SET label=EXCLUDED.label, question=EXCLUDED.question;

INSERT INTO theories (theory_id, name, version_label, status) VALUES
('GNWT','Global Neuronal Workspace Theory',NULL,'ACTIVE'),
('IIT','Integrated Information Theory','4.0','ACTIVE'),
('RPT','Recurrent Processing Theory',NULL,'ACTIVE'),
('HOT','Higher-Order Theories',NULL,'ACTIVE'),
('PP','Predictive Processing and Active Inference',NULL,'ACTIVE'),
('AST','Attention Schema Theory',NULL,'ACTIVE'),
('EM','Electromagnetic Field Theories',NULL,'ACTIVE'),
('OR','Orchestrated Objective Reduction',NULL,'ACTIVE')
ON CONFLICT (theory_id) DO NOTHING;

INSERT INTO target_relevance (target_relevance_id, label, description) VALUES
('TR-CA-MECH','Consciousness-adjacent mechanism','Frozen v1.1.1 claim-level target-relevance label.'),
('TR-DIR-ACC','Direct consciousness/access claim','Frozen v1.1.1 claim-level target-relevance label.'),
('TR-DIR-PHEN','Direct phenomenal claim','Frozen v1.1.1 claim-level target-relevance label.'),
('TR-SUB-FORMAL','Substrate/formal enabling mechanism','Frozen v1.1.1 claim-level target-relevance label.'),
('TR-DIR-BND','Direct subject-boundary claim','Frozen v1.1.1 claim-level target-relevance label.'),
('TR-DIR-PHEN-CONT-ID','Direct phenomenal-content identity claim','Frozen v1.1.1 claim-level target-relevance label.'),
('TR-DIR-PHEN-ID','Direct phenomenal identity claim','Frozen v1.1.1 claim-level target-relevance label.'),
('TR-DIR-PERCEPT','Direct perceptual-consciousness claim','Frozen v1.1.1 claim-level target-relevance label.'),
('TR-DIR-PHEN-SUFF','Direct phenomenal sufficiency claim','Frozen v1.1.1 claim-level target-relevance label.'),
('TR-DIR-AWARE-MECH','Direct awareness mechanism claim','Frozen v1.1.1 claim-level target-relevance label.'),
('TR-DIR-NEC','Direct necessity claim','Frozen v1.1.1 claim-level target-relevance label.'),
('TR-DIR-CONT','Direct conscious-content claim','Frozen v1.1.1 claim-level target-relevance label.'),
('TR-GEN-COG','General cognitive/perceptual mechanism','Frozen v1.1.1 claim-level target-relevance label.'),
('TR-CA-CONT','Consciousness-adjacent content claim','Frozen v1.1.1 claim-level target-relevance label.'),
('TR-CA-SELF','Consciousness-adjacent self-model mechanism','Frozen v1.1.1 claim-level target-relevance label.'),
('TR-CA-REPORT','Consciousness-adjacent report/content claim','Frozen v1.1.1 claim-level target-relevance label.'),
('TR-SUB-ENABLE','Substrate-enabling mechanism','Frozen v1.1.1 claim-level target-relevance label.'),
('TR-DIR-STATE-SUB','Direct consciousness-state/substrate claim','Frozen v1.1.1 claim-level target-relevance label.'),
('TR-DIR-CONT-SUFF','Direct conscious-content sufficiency claim','Frozen v1.1.1 claim-level target-relevance label.'),
('TR-SUB-CAUSAL','Substrate-enabling causal mechanism','Frozen v1.1.1 claim-level target-relevance label.'),
('TR-DIR-CONSC-NEC','Direct consciousness necessity claim','Frozen v1.1.1 claim-level target-relevance label.'),
('TR-SUB-TEMP','Substrate/temporal mechanism claim','Frozen v1.1.1 claim-level target-relevance label.'),
('TR-DIR-PHEN-CONT','Direct phenomenal/content identity claim','Frozen v1.1.1 claim-level target-relevance label.')
ON CONFLICT (target_relevance_id) DO NOTHING;

COMMIT;
