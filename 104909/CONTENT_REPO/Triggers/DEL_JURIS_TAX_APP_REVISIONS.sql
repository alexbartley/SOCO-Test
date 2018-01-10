CREATE OR REPLACE TRIGGER content_repo."DEL_JURIS_TAX_APP_REVISIONS" 
 AFTER
  DELETE
 ON content_repo.juris_tax_app_revisions
REFERENCING NEW AS NEW OLD AS OLD
BEGIN
UPDATE juris_tax_app_revisions r
SET next_rid = NULL
WHERE next_rid IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM juris_tax_app_revisions r2
    where r2.id = r.next_rid
    );
END;
/