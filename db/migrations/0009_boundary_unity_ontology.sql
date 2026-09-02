-- Encode the v1.1.1 split-brain/hemispherectomy boundary ontology.
-- Unity classes must not be silently promoted into one another.

BEGIN;

CREATE TYPE unity_class_code AS ENUM (
  'ANATOMICAL',
  'CAUSAL_INFORMATIONAL',
  'ACCESS',
  'AGENTIVE',
  'PHENOMENAL_SUBJECT'
);

CREATE TABLE unity_classes (
    unity_class unity_class_code PRIMARY KEY,
    label TEXT NOT NULL UNIQUE,
    definition TEXT NOT NULL
);

INSERT INTO unity_classes (unity_class, label, definition) VALUES
('ANATOMICAL','Anatomical unity','Whether tissue is physically continuous or connected by major tracts.'),
('CAUSAL_INFORMATIONAL','Causal/informational unity','Whether components exert sufficiently rich reciprocal influence on one another.'),
('ACCESS','Access unity','Whether information available to one subsystem can be flexibly used by the other.'),
('AGENTIVE','Agentive unity','Whether the organism behaves as one coordinated decision-making agent.'),
('PHENOMENAL_SUBJECT','Phenomenal/subject unity','Whether simultaneous experiences belong to one first-person subject.');

CREATE TABLE evidence_unity_links (
    evidence_id TEXT NOT NULL REFERENCES evidence(evidence_id) ON DELETE CASCADE,
    unity_class unity_class_code NOT NULL REFERENCES unity_classes(unity_class),
    relationship TEXT NOT NULL,
    bridge_to_phenomenal_established BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (evidence_id, unity_class)
);

COMMENT ON TABLE evidence_unity_links IS
'Boundary-layer interpretation of evidence. A link to access, agentive, anatomical, or causal/informational unity does not establish phenomenal subject unity unless an explicit bridge is separately supported.';

COMMENT ON COLUMN evidence_unity_links.bridge_to_phenomenal_established IS
'True only when the controlling evidence explicitly establishes a bridge from this unity class to phenomenal/subject unity. v1.1.1 split-brain evidence does not establish such a bridge.';

COMMIT;
