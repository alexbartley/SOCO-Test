CREATE OR REPLACE TRIGGER content_repo.del_juris_type_revisions
 AFTER
  DELETE
 ON content_repo.jurisdiction_type_revisions
REFERENCING NEW AS NEW OLD AS OLD
BEGIN
UPDATE jurisdiction_type_revisions r
SET next_rid = NULL
WHERE next_rid IS NOT NULL
AND NOT EXISTS (
    SELECT 1
    FROM jurisdiction_type_revisions r2
    where r2.id = r.next_rid
    );
END;
/