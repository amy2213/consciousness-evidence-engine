-- Phase 4 authorization invariants. Zero rows = pass.

-- Required group roles exist and cannot log in directly.
SELECT 'MISSING_OR_LOGIN_ROLE' AS violation, v.role_name AS detail
FROM (VALUES
 ('cee_app_read'),('cee_ingest'),('cee_review'),('cee_approve'),('cee_release'),('cee_migration_admin')
) v(role_name)
LEFT JOIN pg_roles r ON r.rolname=v.role_name
WHERE r.rolname IS NULL OR r.rolcanlogin;

-- PUBLIC must not retain schema creation rights.
SELECT 'PUBLIC_SCHEMA_CREATE' AS violation, 'public' AS detail
WHERE has_schema_privilege('public','public','CREATE');

-- Ordinary application roles must never have direct mutation rights on authoritative state.
WITH roles(role_name) AS (VALUES
 ('cee_app_read'),('cee_ingest'),('cee_review'),('cee_approve'),('cee_release')
), authoritative(table_name) AS (VALUES
 ('claims'),('evidence'),('claim_evidence'),('score_change_proposals'),('approval_events'),('provenance_events'),('audit_log')
), forbidden(privilege_type) AS (VALUES ('UPDATE'),('DELETE'),('TRUNCATE'))
SELECT 'AUTHORITATIVE_MUTATION_PRIVILEGE' AS violation,
       r.role_name || ':' || a.table_name || ':' || f.privilege_type AS detail
FROM roles r CROSS JOIN authoritative a CROSS JOIN forbidden f
WHERE has_table_privilege(r.role_name, a.table_name, f.privilege_type);

-- AI/candidate ingestion cannot insert directly into authoritative scientific state.
SELECT 'INGEST_AUTHORITATIVE_INSERT' AS violation, v.table_name AS detail
FROM (VALUES ('claims'),('evidence'),('claim_evidence'),('score_change_proposals'),('approval_events'),('provenance_events'),('audit_log')) v(table_name)
WHERE has_table_privilege('cee_ingest', v.table_name, 'INSERT');

-- Reviewer cannot insert approvals or provenance authority records.
SELECT 'REVIEW_AUTHORITY_INSERT' AS violation, v.table_name AS detail
FROM (VALUES ('approval_events'),('provenance_events'),('audit_log'),('score_change_proposals')) v(table_name)
WHERE has_table_privilege('cee_review', v.table_name, 'INSERT');

-- Approver may append decision/provenance records but cannot directly write claims/evidence/scores/audit.
SELECT 'APPROVER_MISSING_APPEND_RIGHT' AS violation, v.table_name AS detail
FROM (VALUES ('approval_events'),('provenance_events')) v(table_name)
WHERE NOT has_table_privilege('cee_approve', v.table_name, 'INSERT');

SELECT 'APPROVER_DIRECT_SCIENCE_WRITE' AS violation, v.table_name AS detail
FROM (VALUES ('claims'),('evidence'),('claim_evidence'),('score_change_proposals'),('audit_log')) v(table_name)
WHERE has_table_privilege('cee_approve', v.table_name, 'INSERT,UPDATE,DELETE');

-- Read-only role means what the name says, a concept humanity has historically struggled with.
SELECT 'READ_ROLE_WRITE' AS violation, t.tablename AS detail
FROM pg_tables t
WHERE t.schemaname='public'
  AND has_table_privilege('cee_app_read', format('%I.%I',t.schemaname,t.tablename), 'INSERT,UPDATE,DELETE,TRUNCATE');

-- Phase 5 intentionally grants cee_release write access only to release-construction tables.
-- It must remain unable to mutate scientific authority, approvals, provenance, or audit history.
SELECT 'RELEASE_ROLE_UNAUTHORIZED_WRITE' AS violation, t.tablename AS detail
FROM pg_tables t
WHERE t.schemaname='public'
  AND t.tablename NOT IN ('dataset_releases','release_membership','release_errata')
  AND has_table_privilege('cee_release', format('%I.%I',t.schemaname,t.tablename), 'INSERT,UPDATE,DELETE,TRUNCATE');

SELECT 'RELEASE_ROLE_APPROVAL_WRITE' AS violation, v.table_name AS detail
FROM (VALUES ('approval_events'),('provenance_events'),('audit_log'),('claims'),('evidence'),('claim_evidence'),('score_change_proposals')) v(table_name)
WHERE has_table_privilege('cee_release', v.table_name, 'INSERT,UPDATE,DELETE,TRUNCATE');
