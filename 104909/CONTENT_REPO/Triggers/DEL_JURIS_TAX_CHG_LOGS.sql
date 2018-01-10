CREATE OR REPLACE TRIGGER content_repo."DEL_JURIS_TAX_CHG_LOGS" 
 AFTER
  DELETE
 ON content_repo.juris_tax_chg_logs
REFERENCING NEW AS NEW OLD AS OLD
BEGIN
DELETE from jurisdiction_tax_revisions r
WHERE status = 0
AND NOT EXISTS (
    SELECT 1
    FROM juris_tax_chg_logs l
    WHERE l.rid = r.id
    );
END;
/