BEGIN;

-- Target relevance is seeded by db/seed/v1_1_1_claim_taxonomy.sql on the
-- v1.1.1 migration branch. Keeping a second generic target-relevance seed here
-- creates competing IDs for identical labels and violates the unique label
-- contract. Populations remain generic controlled vocabulary.

INSERT INTO populations (population_id, name, description, translation_framework) VALUES
('ANESTHESIA', 'Anesthesia and emergence', 'Reversible pharmacological transitions in responsiveness and conscious-compatible neural dynamics.', 'state-transition'),
('SLEEP', 'Sleep and dreaming', 'REM/NREM and within-state experience sampling.', 'state-within-state'),
('DOC_CMD', 'Disorders of consciousness and cognitive motor dissociation', 'Behaviorally limited clinical populations with covert command-following paradigms.', 'asymmetric-evidence'),
('SPLIT_BRAIN', 'Split-brain and hemispherectomy', 'Boundary, access, agency, and subject-unity stress tests.', 'unity-and-boundary'),
('DEVELOPMENT', 'Infants and development', 'Age-dependent conscious-compatible markers under developmental translation constraints.', 'developmental-translation-penalty'),
('NONHUMAN_ANIMAL', 'Nonhuman animals', 'Comparative consciousness inference across divergent architectures and ecologies.', 'phylogenetic-translation-penalty'),
('EX_VIVO', 'Organoids and ex vivo neural systems', 'Neural organization without ordinary organism-level behavior or embodiment.', 'ex-vivo-translation-and-oec-firewall');

COMMIT;
