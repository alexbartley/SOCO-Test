CREATE OR REPLACE TRIGGER content_repo.ins_juris_type_chg_logs
 BEFORE
  INSERT
 ON content_repo.juris_type_chg_logs
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_juris_type_chg_logs.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/