CREATE OR REPLACE TRIGGER content_repo."INS_ADMIN_CHG_LOGS" 
 BEFORE
  INSERT
 ON content_repo.admin_chg_logs
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_admin_chg_logs.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/