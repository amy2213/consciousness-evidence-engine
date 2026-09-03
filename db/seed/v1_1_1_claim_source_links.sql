-- Frozen claim-to-source provenance from v1.1.1 Sections 4 and 5.1.
-- BASELINE_CITATION = source cited in the canonical Section 4 claim definition.
-- ACCUMULATED_EVIDENCE_LINK = additional source present in Section 5.1 after later deep dives.
BEGIN;

CREATE TEMP TABLE tmp_claim_source_baseline (claim_id TEXT, source_num INT);
INSERT INTO tmp_claim_source_baseline VALUES
('GNW-1',1),('GNW-1',2),('GNW-1',4),('GNW-2',4),('GNW-3',1),
('IIT-1',3),('IIT-2',3),('IIT-3',3),('IIT-3',1),('IIT-4',3),
('RPT-1',5),('RPT-1',6),('RPT-2',6),('RPT-3',5),('RPT-3',6),
('HOT-1',12),('HOT-1',13),('HOT-1',14),('HOT-2',12),('HOT-2',13),('HOT-2',14),('HOT-3',12),
('PP-1',8),('PP-2',8),('PP-3',8),('AST-1',7),('AST-2',7),('AST-3',7),
('EM-1',9),('EM-2',9),('EM-3',9),
('OR-1',10),('OR-1',11),('OR-2',10),('OR-2',11),('OR-3',10),('OR-3',11),('OR-4',10),('OR-4',11),('OR-5',10),('OR-5',11);

INSERT INTO claim_source_links (ledger_version,claim_id,source_id,link_kind,population_id,interpretation)
SELECT 'v1.1.1', claim_id, 'SRC-' || lpad(source_num::text,3,'0'), 'BASELINE_CITATION', NULL,
       'Canonical Section 4 claim citation preserved from the frozen v1.1.1 ledger.'
FROM tmp_claim_source_baseline;

CREATE TEMP TABLE tmp_claim_source_full (claim_id TEXT, source_num INT);
INSERT INTO tmp_claim_source_full VALUES
('GNW-1',1),('GNW-1',2),('GNW-1',4),('GNW-1',16),('GNW-1',17),('GNW-1',22),('GNW-1',23),('GNW-1',25),('GNW-1',26),('GNW-1',31),('GNW-1',32),('GNW-1',33),('GNW-1',34),
('GNW-2',4),('GNW-2',16),('GNW-2',17),('GNW-2',23),('GNW-2',25),('GNW-2',26),('GNW-2',31),('GNW-2',32),('GNW-2',33),('GNW-2',34),
('GNW-3',1),('GNW-3',21),('GNW-3',22),('GNW-3',34),
('IIT-1',3),('IIT-1',19),('IIT-1',23),('IIT-1',24),('IIT-1',25),('IIT-1',26),('IIT-2',3),('IIT-2',25),('IIT-2',26),('IIT-3',3),('IIT-3',1),('IIT-3',22),('IIT-4',3),('IIT-4',15),('IIT-4',19),('IIT-4',25),('IIT-4',26),('IIT-4',34),
('RPT-1',5),('RPT-1',6),('RPT-1',17),('RPT-1',22),('RPT-1',24),('RPT-2',6),('RPT-2',17),('RPT-2',22),('RPT-2',24),('RPT-3',5),('RPT-3',6),('RPT-3',21),('RPT-3',22),('RPT-3',34),
('HOT-1',12),('HOT-1',13),('HOT-1',14),('HOT-1',21),('HOT-1',22),('HOT-1',31),('HOT-1',32),('HOT-1',34),('HOT-2',12),('HOT-2',13),('HOT-2',14),('HOT-2',21),('HOT-2',22),('HOT-2',31),('HOT-2',32),('HOT-2',34),('HOT-3',12),('HOT-3',22),('HOT-3',34),
('PP-1',8),('PP-1',17),('PP-1',28),('PP-2',8),('PP-2',17),('PP-2',22),('PP-2',31),('PP-2',32),('PP-3',8),('PP-3',21),('PP-3',22),
('AST-1',7),('AST-1',21),('AST-2',7),('AST-2',21),('AST-2',34),('AST-3',7),('AST-3',21),('AST-3',34),
('EM-1',9),('EM-1',23),('EM-2',9),('EM-2',15),('EM-2',18),('EM-2',23),('EM-2',25),('EM-3',9),('EM-3',21),('EM-3',34),
('OR-1',10),('OR-1',11),('OR-1',20),('OR-1',27),('OR-2',10),('OR-2',11),('OR-2',20),('OR-2',27),('OR-3',10),('OR-3',11),('OR-3',20),('OR-3',21),('OR-3',22),('OR-4',10),('OR-4',11),('OR-4',27),('OR-5',10),('OR-5',11),('OR-5',21),('OR-5',22),('OR-5',34);

INSERT INTO claim_source_links (ledger_version,claim_id,source_id,link_kind,population_id,interpretation)
SELECT 'v1.1.1', f.claim_id, 'SRC-' || lpad(f.source_num::text,3,'0'), 'ACCUMULATED_EVIDENCE_LINK', NULL,
       'Additional Section 5.1 linkage accumulated through later deep dives; population attribution is deferred to atomic EVIDENCE migration.'
FROM tmp_claim_source_full f
WHERE NOT EXISTS (
  SELECT 1 FROM tmp_claim_source_baseline b
  WHERE b.claim_id=f.claim_id AND b.source_num=f.source_num
);

COMMIT;
