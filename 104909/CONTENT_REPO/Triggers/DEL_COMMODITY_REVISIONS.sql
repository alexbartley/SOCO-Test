CREATE OR REPLACE TRIGGER content_repo."DEL_COMMODITY_REVISIONS" 
 AFTER
  DELETE
 ON content_repo.commodity_revisions
REFERENCING NEW AS NEW OLD AS OLD
BEGIN
UPDATE commodity_revisions r
SET next_rid = NULL
WHERE next_rid IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM commodity_revisions r2
    where r2.id = r.next_rid
    );
END;
/