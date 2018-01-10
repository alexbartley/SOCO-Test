CREATE OR REPLACE TRIGGER content_repo."DEL_REF_GROUP_REVISIONS" 
 AFTER
  DELETE
 ON content_repo.ref_group_revisions
REFERENCING NEW AS NEW OLD AS OLD
BEGIN
UPDATE ref_group_revisions r
SET next_rid = NULL
WHERE next_rid IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM ref_group_revisions r2
    where r2.id = r.next_rid
    );
END;
/