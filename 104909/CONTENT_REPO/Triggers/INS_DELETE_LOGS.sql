CREATE OR REPLACE TRIGGER content_repo."INS_DELETE_LOGS" 
 BEFORE
  INSERT
 ON content_repo.delete_logs
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_delete_logs.nextval;
:new.deleted_date := SYSTIMESTAMP;
END;
/