-- Phase 13: migrate exact frozen evidence source locators into work-level provenance.
BEGIN;

INSERT INTO source_locators(
  source_locator_id,source_id,work_id,locator_type,locator_text,content_hash
)
SELECT
  (substr(md5('locator:'||e.evidence_id),1,8)||'-'||substr(md5('locator:'||e.evidence_id),9,4)||'-'||substr(md5('locator:'||e.evidence_id),13,4)||'-'||substr(md5('locator:'||e.evidence_id),17,4)||'-'||substr(md5('locator:'||e.evidence_id),21,12))::uuid,
  e.source_id,sw.work_id,'OTHER'::source_locator_type_code,e.source_locator,
  md5(concat_ws('|',e.source_id,sw.work_id,e.source_locator))
FROM evidence e
JOIN LATERAL (
  SELECT sw.work_id FROM source_works sw
  WHERE sw.source_id=e.source_id ORDER BY sw.ordinal LIMIT 1
) sw ON TRUE
WHERE e.ledger_version='v1.1.1' AND btrim(COALESCE(e.source_locator,''))<>''
ON CONFLICT (source_locator_id) DO NOTHING;

INSERT INTO evidence_source_locations(evidence_id,source_locator_id,is_primary,rationale)
SELECT
  e.evidence_id,
  (substr(md5('locator:'||e.evidence_id),1,8)||'-'||substr(md5('locator:'||e.evidence_id),9,4)||'-'||substr(md5('locator:'||e.evidence_id),13,4)||'-'||substr(md5('locator:'||e.evidence_id),17,4)||'-'||substr(md5('locator:'||e.evidence_id),21,12))::uuid,
  TRUE,'Exact locator migrated from frozen v1.1.1 evidence source_locator.'
FROM evidence e
WHERE e.ledger_version='v1.1.1' AND btrim(COALESCE(e.source_locator,''))<>''
  AND EXISTS (
    SELECT 1 FROM source_locators sl
    WHERE sl.source_locator_id=(substr(md5('locator:'||e.evidence_id),1,8)||'-'||substr(md5('locator:'||e.evidence_id),9,4)||'-'||substr(md5('locator:'||e.evidence_id),13,4)||'-'||substr(md5('locator:'||e.evidence_id),17,4)||'-'||substr(md5('locator:'||e.evidence_id),21,12))::uuid
  )
ON CONFLICT (evidence_id,source_locator_id) DO NOTHING;

COMMIT;
