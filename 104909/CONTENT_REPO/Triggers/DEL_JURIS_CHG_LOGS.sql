CREATE OR REPLACE TRIGGER content_repo."DEL_JURIS_CHG_LOGS" 
 AFTER
 DELETE
 ON content_repo.JURIS_CHG_LOGS
 REFERENCING OLD AS OLD NEW AS NEW
BEGIN
DELETE from jurisdiction_revisions r
WHERE status = 0
AND NOT EXISTS (
    SELECT 1
    FROM juris_chg_logs l
    WHERE l.rid = r.id
);
/* Previous version
DELETE from jurisdiction_revisions r
WHERE status = 0
AND NOT EXISTS (
    SELECT 1
    FROM juris_chg_logs l
    WHERE l.rid = r.id
    );
IF (SQL%ROWCOUNT >0) THEN
UPDATE jurisdiction_revisions
SET next_rid = NULL
WHERE id = :old.id;
END IF;
*/
END;
/