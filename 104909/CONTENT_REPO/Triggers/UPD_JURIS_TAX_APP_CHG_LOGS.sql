CREATE OR REPLACE TRIGGER content_repo."UPD_JURIS_TAX_APP_CHG_LOGS" 
 BEFORE
  UPDATE
 ON content_repo.juris_tax_app_chg_logs
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
IF UPDATING('STATUS') THEN
    :new.status_modified_Date := SYSTIMESTAMP;
    EXECUTE IMMEDIATE 'UPDATE '||:old.table_name||' SET status = '||:new.status||' WHERE id = '||:old.primary_key;
    UPDATE juris_tax_app_revisions
    SET status = :new.status
    WHERE id = :old.rid;
END IF;

END;
/