CREATE OR REPLACE TRIGGER content_repo."INS_JURIS_CHG_LOGS" 
 BEFORE
  INSERT
 ON content_repo.juris_chg_logs
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_juris_chg_logs.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/