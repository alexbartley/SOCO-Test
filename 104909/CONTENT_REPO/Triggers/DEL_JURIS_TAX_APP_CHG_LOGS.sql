CREATE OR REPLACE TRIGGER content_repo."DEL_JURIS_TAX_APP_CHG_LOGS" 
 AFTER 
 DELETE
 ON content_repo.JURIS_TAX_APP_CHG_LOGS
 REFERENCING OLD AS OLD NEW AS NEW
BEGIN
DELETE from juris_tax_app_revisions r
WHERE  NOT EXISTS (
    SELECT 1
    FROM juris_tax_app_chg_logs l
    WHERE l.rid = r.id
    )
AND status = 0;
END;
/