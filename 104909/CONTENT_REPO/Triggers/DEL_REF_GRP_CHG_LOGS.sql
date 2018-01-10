CREATE OR REPLACE TRIGGER content_repo."DEL_REF_GRP_CHG_LOGS" 
 AFTER
  DELETE
 ON content_repo.ref_grp_chg_logs
REFERENCING NEW AS NEW OLD AS OLD
BEGIN
DELETE from ref_group_revisions r
WHERE status = 0
AND NOT EXISTS (
    SELECT 1
    FROM ref_grp_chg_logs l
    WHERE l.rid = r.id
    );
END;
/