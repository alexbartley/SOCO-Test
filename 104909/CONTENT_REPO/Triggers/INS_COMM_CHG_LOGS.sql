CREATE OR REPLACE TRIGGER content_repo."INS_COMM_CHG_LOGS" 
 BEFORE
  INSERT
 ON content_repo.comm_chg_logs
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_comm_chg_logs.nextval;
:new.entered_Date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/