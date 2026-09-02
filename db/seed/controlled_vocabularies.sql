BEGIN;

INSERT INTO target_relevance (target_relevance_id, label, description) VALUES
('DIRECT_CONSCIOUSNESS', 'Direct consciousness claim', 'Evidence directly targets a claim about conscious state, content, subject, or phenomenality.'),
('CONSCIOUSNESS_ADJACENT', 'Consciousness-adjacent mechanism', 'Evidence targets a mechanism closely associated with conscious access or processing but is not itself a consciousness criterion.'),
('GENERAL_COGNITIVE', 'General cognitive/perceptual mechanism', 'Evidence targets cognition, perception, prediction, learning, memory, or related processing without consciousness specificity.'),
('SUBSTRATE_ENABLING', 'Substrate-enabling mechanism', 'Evidence targets a physical or biological substrate that could enable a theory mechanism without independently establishing consciousness.');

INSERT INTO populations (population_id, name, description, translation_framework) VALUES
('ANESTHESIA', 'Anesthesia and emergence', 'Reversible pharmacological transitions in responsiveness and conscious-compatible neural dynamics.', 'state-transition'),
('SLEEP', 'Sleep and dreaming', 'REM/NREM and within-state experience sampling.', 'state-within-state'),
('DOC_CMD', 'Disorders of consciousness and cognitive motor dissociation', 'Behaviorally limited clinical populations with covert command-following paradigms.', 'asymmetric-evidence'),
('SPLIT_BRAIN', 'Split-brain and hemispherectomy', 'Boundary, access, agency, and subject-unity stress tests.', 'unity-and-boundary'),
('DEVELOPMENT', 'Infants and development', 'Age-dependent conscious-compatible markers under developmental translation constraints.', 'developmental-translation-penalty'),
('NONHUMAN_ANIMAL', 'Nonhuman animals', 'Comparative consciousness inference across divergent architectures and ecologies.', 'phylogenetic-translation-penalty'),
('EX_VIVO', 'Organoids and ex vivo neural systems', 'Neural organization without ordinary organism-level behavior or embodiment.', 'ex-vivo-translation-and-oec-firewall');

COMMIT;
