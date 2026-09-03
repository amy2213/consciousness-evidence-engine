-- Frozen canonical claims extracted from Consciousness Evidence Map: Claim Ledger v1.1.1.
-- Source pages 7-21. Claim wording, falsifiers, operational tests, scores, CMC, OF, types, and roles are preserved.
BEGIN;

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('GNW-1','GNWT','TR-CA-MECH','Consciously accessed content produces a late, nonlinear transition into widespread cortical availability.','Under matched no-report conditions, conscious content repeatedly occurs without any measurable ignition or broad availability.','Preregistered no-report threshold task with content decoding and temporally resolved tests of widespread ignition, while decision, confidence, and memory demands are matched.',3,3,3,2,3,2,1);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('GNW-1','M',1);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('GNW-1','ACC');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','GNW-1',3,3,2,3,2,1,3,3,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('GNW-2','GNWT','TR-DIR-ACC','Global broadcasting is necessary for flexible conscious access.','A subject demonstrates flexible, cross-domain use of a content while broadcasting is selectively and reversibly absent.','Reversibly suppress a preregistered broadcast pathway while preserving local content coding, then test cross-domain flexible use with convergent report and no-report measures.',2,3,3,2,2,2,1);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('GNW-2','N',1);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('GNW-2','ACC');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','GNW-2',3,3,2,2,2,1,2,2,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('GNW-3','GNWT','TR-DIR-PHEN','Global broadcasting is sufficient for subjective experience.','Robust broadcast is induced in an otherwise unconscious system without any convergent evidence of experience, or equivalent broadcast occurs in accepted nonconscious systems.','Induce a broadcast-like state without normal content-generating input and test for convergent content-sensitive evidence of experience; currently limited by the lack of an independent phenomenality criterion.',1,1,1,0,1,0,1);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('GNW-3','P',1);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('GNW-3','PHEN');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','GNW-3',1,1,0,1,0,1,1,1,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('IIT-1','IIT','TR-SUB-FORMAL','Physical systems possess measurable intrinsic cause-effect structures with degrees of irreducibility.','Two implementations agreed by proponents to instantiate the same intrinsic causal structure yield incompatible results under the formalism.','Run exact IIT calculations on small, fully specified systems implemented in multiple physically distinct but formally equivalent ways and test formal invariance.',2,4,3,0,3,1,2);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('IIT-1','M',1);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('IIT-1','INT');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','IIT-1',4,3,0,3,1,2,2,2,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('IIT-2','IIT','TR-DIR-BND','The maximally irreducible complex identifies the conscious subject and excludes overlapping alternatives.','A system''s stable conscious boundary dissociates reproducibly from its maximal complex under an agreed exact calculation.','Prospectively calculate candidate complexes in tractable biological or synthetic systems before perturbing coupling or grain; compare predicted boundaries with convergent subject-boundary indicators.',1,3,1,0,1,1,1);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('IIT-2','B',1);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('IIT-2','BND');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','IIT-2',3,1,0,1,1,1,1,1,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('IIT-3','IIT','TR-DIR-PHEN-CONT-ID','The quality of experience is identical to the structure of the system''s cause-effect structure.','Preregistered IIT mappings repeatedly predict the wrong content while rival mappings succeed.','Preregister exact or agreed proxy mappings from cause-effect structure to specific perceptual contents and compare out-of-sample predictions with rival content models.',2,3,1,0,1,1,0);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('IIT-3','C',1);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('IIT-3','GEN'), ('IIT-3','PHEN');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','IIT-3',3,1,0,1,1,0,1,2,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('IIT-4','IIT','TR-DIR-PHEN-ID','A substrate satisfying IIT''s postulates is conscious, regardless of its input-output behavior.','A matched pair with different IIT structures shows the same well-supported consciousness profile, or a high-IIT system satisfies strong agreed criteria for nonconsciousness.','Compare systems with sharply different agreed IIT structures under a predeclared multi-measure consciousness assessment; decisive testing remains limited by the absence of a theory-neutral negative criterion.',1,3,0,0,1,0,1);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('IIT-4','P',1);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('IIT-4','PHEN');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','IIT-4',3,0,0,1,0,1,0,1,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('RPT-1','RPT','TR-CA-MECH','Recurrent sensory processing differentiates consciously perceived from feedforward-only processing.','Awareness dissociates from recurrence after stimulus, performance, attention, and report demands are matched.','Apply temporally precise feedback disruption while matching stimulus strength, attention, performance, and report demands; decode feedforward content to verify preservation.',3,3,3,2,3,2,1);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('RPT-1','M',1);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('RPT-1','GEN'), ('RPT-1','INT');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','RPT-1',3,3,2,3,2,1,3,3,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('RPT-2','RPT','TR-DIR-PERCEPT','Local sensory recurrence is necessary for perceptual phenomenality.','A stable perceptual experience survives selective blockade of local recurrence while feedforward content coding remains intact.','Block a preregistered local recurrent pathway while demonstrating preserved feedforward representation, then assess content-specific experience through convergent measures.',2,3,3,2,2,1,1);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('RPT-2','N',1);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('RPT-2','GEN'), ('RPT-2','INT');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','RPT-2',3,3,2,2,1,1,2,2,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('RPT-3','RPT','TR-DIR-PHEN-SUFF','Local recurrence alone is sufficient for perceptual experience without global access.','Local recurrence is induced without any convergent content-sensitive sign of experience across no-report and later-memory probes.','Induce or preserve local recurrence while suppressing global access, then test no-report physiology, surprise probes, delayed memory, and content decoding for convergent evidence.',2,2,1,0,1,1,1);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('RPT-3','S',1);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('RPT-3','GEN'), ('RPT-3','PHEN');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','RPT-3',2,1,0,1,1,1,1,2,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('HOT-1','HOT','TR-DIR-AWARE-MECH','Subjective awareness depends on a metarepresentation of a first-order state.','Conscious content remains intact during selective, reversible abolition of the relevant metarepresentation.','Selectively perturb the specified metarepresentational format or circuit while preserving first-order coding and objective task performance; compare subjective and no-report content measures.',2,2,2,1,2,1,2);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('HOT-1','M',1);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('HOT-1','META');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','HOT-1',2,2,1,2,1,2,2,2,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('HOT-2','HOT','TR-DIR-NEC','The relevant higher-order state is necessary for a first-order state to be conscious.','No-report content measures remain normal when the agreed higher-order process is selectively disabled.','Reversibly disable the agreed higher-order process and test whether first-order content remains consciously available under matched criterion, memory, and report demands.',2,2,2,1,1,1,1);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('HOT-2','N',1);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('HOT-2','META');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','HOT-2',2,2,1,1,1,1,2,2,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('HOT-3','HOT','TR-DIR-CONT','Misrepresentation at the higher level can generate conscious appearance without a matching first-order state.','Controlled higher-order manipulation fails to change experience unless first-order sensory representations change.','Manipulate higher-order representation while holding first-order sensory evidence approximately constant and preregister the predicted phenomenal distortion.',2,2,1,1,1,1,1);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('HOT-3','C',1);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('HOT-3','META'), ('HOT-3','GEN');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','HOT-3',2,1,1,1,1,1,1,2,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('PP-1','PP','TR-GEN-COG','Cortical processing encodes predictions and prediction errors across hierarchical levels.','An agreed computational model repeatedly loses to a nonpredictive encoding model on prospective neural data.','Prospectively compare explicit predictive-coding and nonpredictive encoding models on held-out neural data with predeclared anatomical, temporal, and spectral predictions.',4,4,4,2,4,2,1);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('PP-1','M',1);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('PP-1','GEN');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','PP-1',4,4,2,4,2,1,3,4,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('PP-2','PP','TR-CA-CONT','Conscious content reflects the posterior hypothesis with greatest precision-weighted support.','Priors and precision are altered as modeled, yet conscious content changes contrary to the preregistered posterior prediction.','Manipulate priors and precision independently where possible, fit the generative model before outcome inspection, and score preregistered trial-level content predictions.',3,3,3,1,3,2,1);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('PP-2','C',1);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('PP-2','GEN');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','PP-2',3,3,1,3,2,1,3,3,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('PP-3','PP','TR-DIR-PHEN','Predictive inference is sufficient for phenomenality.','Systems implement equivalent predictive dynamics while diverging on an independently justified consciousness criterion.','Compare systems or states with matched predictive dynamics but sharply different convergent consciousness profiles; decisive interpretation remains criterion-limited.',1,1,1,0,1,0,0);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('PP-3','P',1);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('PP-3','PHEN');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','PP-3',1,1,0,1,0,0,0,1,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('AST-1','AST','TR-CA-SELF','An internal model of attention improves control of attention and awareness attribution.','Removing the candidate schema leaves attention control and awareness attribution intact.','Identify a preregistered neural/computational schema representation distinct from generic metacognition, perturb it, and measure attention control plus awareness attribution.',2,2,2,1,1,1,2);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('AST-1','M',1);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('AST-1','META');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','AST-1',2,2,1,1,1,2,2,2,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('AST-2','AST','TR-CA-REPORT','Awareness reports reflect the content of the attention schema, including systematic errors.','Schema content is manipulated without the predicted change in awareness judgment, attribution, or control.','Manipulate the inferred schema content while holding actual attentional allocation as constant as possible, then test predicted changes in awareness judgment and control.',3,2,2,1,1,1,2);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('AST-2','C',1);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('AST-2','META');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','AST-2',2,2,1,1,1,2,2,3,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('AST-3','AST','TR-DIR-PHEN-ID','Possessing the attention schema constitutes subjective awareness.','A system implements the schema and its functions but meets strong agreed negative criteria for experience.','Implement the specified attention-schema computation in systems with divergent consciousness evidence and test all nonphenomenal predictions; phenomenal adjudication remains indirect.',1,1,1,0,1,0,1);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('AST-3','P',1);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('AST-3','PHEN');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','AST-3',1,1,0,1,0,1,0,1,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('EM-1','EM','TR-SUB-ENABLE','Endogenous neural fields causally influence neuronal timing and integration.','Consciousness-relevant integration persists unchanged when the field''s causal influence is selectively canceled.','Alter endogenous field geometry with closed-loop stimulation while matching major population firing statistics, then test predicted timing/integration changes.',2,3,3,2,3,1,1);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('EM-1','M',1);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('EM-1','SUB'), ('EM-1','INT');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','EM-1',3,3,2,3,1,1,2,2,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('EM-2','EM','TR-DIR-STATE-SUB','A specified integrated field pattern is necessary for conscious unity or state.','Neural computation and conscious behavior persist while the candidate field pattern is selectively disrupted.','Use a field-versus-neuron causal clamp to perturb the candidate field while preserving neural computation as closely as technically possible, then measure state and unity indicators.',1,2,2,1,2,0,1);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('EM-2','N',1);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('EM-2','SUB'), ('EM-2','INT');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','EM-2',2,2,1,2,0,1,2,1,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('EM-3','EM','TR-DIR-CONT-SUFF','Reproducing the relevant field organization creates or changes a predicted conscious content.','A preregistered field pattern is imposed without generating its predicted experience across replications.','Impose a preregistered field pattern while matching conventional neural stimulation effects and test whether the predicted content is induced across replications.',2,2,1,0,1,0,0);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('EM-3','S',1), ('EM-3','C',2);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('EM-3','SUB'), ('EM-3','GEN');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','EM-3',2,1,0,1,0,0,1,2,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('OR-1','OR','TR-SUB-ENABLE','Neuronal microtubules support nontrivial quantum states under physiological conditions.','Rigorous physiological measurements place coherence below the duration and scale required by the specified model.','Measure preregistered quantum-sensitive signatures in intact neuronal microtubules under physiological conditions using controls that exclude identified classical mimics.',2,3,2,1,1,1,1);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('OR-1','M',1);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('OR-1','SUB');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','OR-1',3,2,1,1,1,1,1,2,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('OR-2','OR','TR-SUB-CAUSAL','Those states perform computation that causally alters neuronal firing and network dynamics.','Quantum-selective perturbation changes the proposed state but leaves predicted neuronal computation unchanged.','Use a quantum-selective intervention that preserves classical chemistry and microtubule stability, then test the predicted intracellular, neuronal, and network consequences.',1,2,2,1,0,0,1);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('OR-2','M',1);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('OR-2','SUB');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','OR-2',2,2,1,0,0,1,1,1,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('OR-3','OR','TR-DIR-CONSC-NEC','The quantum-microtubule mechanism is necessary for consciousness.','Consciousness persists with classical microtubule function intact but the operational quantum signature eliminated.','Eliminate the operational quantum signature while preserving classical microtubule function and test whether convergent consciousness measures remain intact.',1,1,1,0,0,0,1);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('OR-3','N',1);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('OR-3','SUB'), ('OR-3','PHEN');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','OR-3',1,1,0,0,0,1,1,1,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('OR-4','OR','TR-SUB-TEMP','Objective reduction occurs according to a gravity-related timescale and organizes conscious moments.','Prospectively calculated collapse intervals fail across biological configurations, or objective-collapse tests rule out the required parameter range.','Specify the relevant mass distribution and reduction parameter before measurement, calculate collapse intervals prospectively, and test them across biological configurations.',1,3,0,0,0,1,0);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('OR-4','M',1);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('OR-4','SUB');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','OR-4',3,0,0,0,1,0,0,1,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

INSERT INTO claims (claim_id,theory_id,target_relevance_id,claim_text,logical_falsifier,operational_test,operational_feasibility,ps,ed,ci,ir,rd,rr) VALUES ('OR-5','OR','TR-DIR-PHEN-CONT','Objective-reduction events determine the existence and specific contents of experience.','Correctly measured collapse events fail to track presence, boundary, or content of experience under decisive tests.','Measure preregistered objective-reduction events and test whether they predict presence, boundary, timing, and specific content beyond classical neural models; no decisive operational paradigm currently exists.',0,1,0,0,0,0,0);
INSERT INTO claim_claim_types (claim_id,claim_type,ordinal) VALUES ('OR-5','C',1), ('OR-5','P',2);
INSERT INTO claim_theory_roles (claim_id,theory_role) VALUES ('OR-5','PHEN'), ('OR-5','GEN');
INSERT INTO claim_baseline_snapshots (ledger_version,claim_id,ps,ed,ci,ir,rd,rr,cmc,operational_feasibility,source_artifact) VALUES ('v1.1.1','OR-5',1,0,0,0,0,0,0,0,'Consciousness_Evidence_Map_Claim_Ledger_v1.1.1.docx');

COMMIT;
