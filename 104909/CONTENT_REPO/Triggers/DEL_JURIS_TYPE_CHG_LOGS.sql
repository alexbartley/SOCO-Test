CREATE OR REPLACE TRIGGER content_repo.del_juris_type_chg_logs
 AFTER
  DELETE
 ON content_repo.juris_type_chg_logs
REFERENCING NEW AS NEW OLD AS OLD
BEGIN
DELETE from jurisdiction_type_revisions r
WHERE status = 0
AND NOT EXISTS (
    SELECT 1
    FROM juris_type_chg_logs l
    WHERE l.rid = r.id
    );
END;
/