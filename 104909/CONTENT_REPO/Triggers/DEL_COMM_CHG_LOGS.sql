CREATE OR REPLACE TRIGGER content_repo."DEL_COMM_CHG_LOGS" 
 AFTER
  DELETE
 ON content_repo.comm_chg_logs
REFERENCING NEW AS NEW OLD AS OLD
BEGIN
DELETE from commodity_revisions r
WHERE status = 0
AND NOT EXISTS (
    SELECT 1
    FROM comm_chg_logs l
    WHERE l.rid = r.id
    );
END;
/