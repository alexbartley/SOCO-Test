CREATE OR REPLACE TRIGGER content_repo.upd_juris_type_chg_logs
 BEFORE
  UPDATE
 ON content_repo.juris_type_chg_logs
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
IF UPDATING('STATUS') THEN
    :new.status_modified_Date := SYSTIMESTAMP;
    EXECUTE IMMEDIATE 'UPDATE '||:old.table_name||' SET status = '||:new.status||' WHERE id = '||:old.primary_key;
    UPDATE jurisdiction_type_revisions
    SET status = :new.status
    WHERE id = :old.rid;
END IF;

END;
/