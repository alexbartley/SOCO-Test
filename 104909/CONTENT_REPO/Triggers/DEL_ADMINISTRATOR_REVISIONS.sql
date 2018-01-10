CREATE OR REPLACE TRIGGER content_repo."DEL_ADMINISTRATOR_REVISIONS" 
 AFTER 
 DELETE
 ON content_repo.ADMINISTRATOR_REVISIONS
BEGIN
UPDATE administrator_revisions r
SET next_rid = NULL
WHERE next_rid IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM administrator_revisions r2
    where r2.id = r.next_rid
    );
END;
/